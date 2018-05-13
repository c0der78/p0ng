//
//  Game.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import Foundation
import AVFoundation
import GameKit


//! a state in the game
enum GameState: Int16 {
    case Disconnected = -1
    case Paused
    case Countdown1, Countdown2, Countdown3, Ready
    case Running
    case Over
    
    var description : String {
        switch(self) {
        case .Disconnected: return "Disconnected"
        case .Paused: return "Paused"
        case .Countdown1: return "Countdown1"
        case .Countdown2: return "Countdown2"
        case .Countdown3: return "Countdown3"
        case .Ready: return "Ready"
        case .Running: return "Running"
        case .Over: return "Over"
        }
    }
}

//! ball velocity values
struct BallSpeed {
    static let X:CGFloat = 3
    static let Y:CGFloat = 4
}

//! network sync type
enum GameSync: UInt8 {
    case None, WaitingForAck;//, HasToAck
    
    var description : String {
        switch(self) {
        case .None: return "None"
        case .WaitingForAck: return "WaitingForAck"
        //case .HasToAck: return "HasToAck"
        }
    }
}

protocol GameEntityPosition {
    var playerPosition: CGPoint { get }
    
    var opponentPosition: CGPoint { get }
    
    var ballPosition: CGPoint { get }
}

//! a game protocol
protocol GameViewDelegate : GameEntityPosition {
    func newGame(_ game: Game, ballPosition position: CGPoint)

    func gameOver( _ game: Game)

    func gameTick(_ game: Game)

    func updateGame(_ game: Game, withBall ballLocation: CGPoint)

    func setOpponentPaddle(_ game: Game, withYLocation location: CGFloat)

    func updateStatus(_ status: String?)
}

class Game : NSObject, MultiplayerDelegate {
    static let shared = Game()
    
    // MARK: Private variables
    private var _playerScore:UInt16
    private var _opponentScore:UInt16
    
    // MARK: Members
    var randomAILag:TimeInterval
    var timer: Timer?
    var scale:CGFloat
    var sndWall:AVAudioPlayer!
    var sndPaddle:AVAudioPlayer!
    var speedBonus:CGPoint
    var opponentIsComputer:Bool
    var ballVelocity:CGPoint
    var state:GameState
    var interval:TimeInterval
    var playerTurn:Bool
    var syncState:GameSync
    
    private var viewDelegate: GameViewDelegate?
    
    private lazy var multiplayer: Multiplayer = NearbyServiceManager()
    
    // MARK: Initializers
    
    private override init() {
        
        self.opponentIsComputer = true
        
        self.state = GameState.Disconnected
        
        self.syncState = GameSync.None
        
        self.randomAILag = 0
        
        self.scale = UIScreen.main.scale
        
        self.speedBonus = CGPoint.zero
        
        self._playerScore = 0
        
        self._opponentScore = 0
        
        self.ballVelocity = CGPoint(x: BallSpeed.X, y: BallSpeed.Y)
        
        self.interval = 0
        
        self.playerTurn = false
        
        super.init()
        
        var soundPath:URL? =  Bundle.main.url(forResource: "offthepaddle", withExtension:"wav")

        if soundPath != nil {
            do {
                try self.sndPaddle = AVAudioPlayer(contentsOf: soundPath!)
            }
            catch let error as NSError {
                print(error)
            }
        }
        
        soundPath = Bundle.main.url(forResource: "offthewall", withExtension: "wav")
        
        if soundPath != nil {
            do {
                try self.sndWall = AVAudioPlayer(contentsOf: soundPath!)
            }
            catch let error as NSError {
                print(error)
            }
        }
        
        Settings.addListener(self, selector:#selector(settingsChanged(_:)))
    }
    
    func start(_ delegate: GameViewDelegate?) {
        self.viewDelegate = delegate
        self.timer = Timer.scheduledTimer(timeInterval: Settings.sharedInstance.speed, target:self, selector:#selector(gameLoopInterval(_:)), userInfo:nil, repeats:true)
        self.state = GameState.Countdown1
    }
    
    // MARK: Dynamic properties
    
    var speedX: CGFloat {
        get {
            var x = self.ballVelocity.x
            
            if x < 0 {
                x += -self.speedBonus.x
            }
            else if x > 0 {
                x += self.speedBonus.x
            }
            
            return x
        }
    }
    
    
    var speedY: CGFloat {
        get {
            var y = self.ballVelocity.y
            
            if y < 0 { y += -self.speedBonus.y; }
            else if y > 0 { y += self.speedBonus.y; }
            
            return y
        }
    }
    
    var playerScore: UInt16 {
        set(value) {
            self._playerScore = value
            
            if self._playerScore >= Settings.sharedInstance.gamePoint {
                self.gameOver(disconnected: false)
            }
        }
        get {
            return self._playerScore
        }
    }
    
    var opponentScore: UInt16 {
        set(value) {
            self._opponentScore = value
            
            if self._opponentScore >= Settings.sharedInstance.gamePoint {
                self.gameOver(disconnected: false)
            }
        }
        
        get {
            return self._opponentScore
        }
    }
    
    
    // MARK: Functions

    @objc func settingsChanged(_ notification: NSNotification)
    {
        guard let settings = notification.object as? Settings  else {
            print("No settings in notification")
            return
        }
    
        self.timer?.invalidate()
            
        self.timer = Timer.scheduledTimer(timeInterval: settings.speed, target:self, selector:#selector(gameLoopInterval(_:)), userInfo:nil, repeats:true)
    }
    
    func calcSpeedBonus(ball: UIView, paddle: UIView, margin: Int) {
        if Int(ball.center.y - paddle.frame.origin.y) > margin
            && Int((paddle.frame.origin.y+paddle.frame.size.height) - ball.center.y) > margin {
            self.speedBonus = CGPoint.zero
        }

        let settings = Settings.sharedInstance
        
        switch settings.difficulty {
        case GameDifficulty.Easy:
            self.speedBonus = CGPoint(x: 1.1, y: 1.36)
            break
        case GameDifficulty.Normal:
            self.speedBonus = CGPoint(x: 1.1, y: 1.28)
            break
        case GameDifficulty.Hard:
            self.speedBonus = CGPoint(x: 1.1, y: 1.2)
            break
        }
        
        print("Speed Bonus!")
    }
    
    func createPaddlePacket() -> PaddlePacket {
        let packet = PaddlePacket()
        if self.viewDelegate != nil {
            packet.paddleY = self.viewDelegate!.playerPosition.y
        }
        return packet
    }
    
    func createStatePacket() -> StatePacket {
        let packet = StatePacket()
        
        packet.state = self.state
        packet.playerScore = self._playerScore
        packet.opponentScore = self._opponentScore
        packet.hostingFlags = 0
        
        if self.playerTurn {
            packet.hostingFlags |= PacketFlags.PlayerTurn
        }
        
        if Settings.sharedInstance.playerOnLeft {
            packet.hostingFlags |= PacketFlags.PlayerOnLeft
        }

        return packet
    }
    
    func createBallPacket() -> BallPacket {
        let packet = BallPacket()
        
        packet.velocityY = self.ballVelocity.y
        packet.velocityX = self.ballVelocity.x
        
        if self.viewDelegate != nil {
            let position = self.viewDelegate!.ballPosition

            packet.ballY = position.y
            packet.ballX = position.x
        }
        
        if self.playerTurn {
            packet.hostingFlags |= PacketFlags.PlayerTurn
        }
        
        if Settings.sharedInstance.playerOnLeft {
            packet.hostingFlags |= PacketFlags.PlayerOnLeft
        }
        
        return packet
    }
    
    func createPacket(type: PacketType) -> Any? {
    
        switch type {
        case .Ball:
            return self.createBallPacket()
            
        case .Paddle, .PaddleMove:
            return self.createPaddlePacket()
            
        case .State:
            return self.createStatePacket()
            
        default:
            return nil
        }
        
    }
    
    //! sends a packet to game center
    func sendPacket( type: PacketType ) {
        
        if self.viewDelegate == nil || self.state == GameState.Disconnected || self.opponentIsComputer {
            return
        }
        
        guard let packet = createPacket(type: type) else {
            return
        }
        
        let archive = type.archive()
        
        archive.encode(packet)
        
        archive.finishEncoding()
        
        if type.needsAck {
            multiplayer.sendReliable(data: archive.encodedData)
        } else {
            multiplayer.send(data: archive.encodedData)
        }
    }
    
    func broadcast ( type: PacketType) {
        
        if self.opponentIsComputer {
            return
        }
        
        if self.state.rawValue <= GameState.Paused.rawValue {
            return
        }
        
        self.sendPacket(type: type)
        
        if type.needsAck {
            print("broadcast: \(type.description)")
            self.syncState = GameSync.WaitingForAck
        }
    }
    
    func gotPaddlePacket(type: PacketType, packet: PaddlePacket) {
        
        print("packet: paddle Change")
        
        let scalingY = UIScreen.main.bounds.width / packet.screenWidth
        
        self.viewDelegate?.setOpponentPaddle(self, withYLocation: packet.paddleY / scalingY)
        
        if type == PacketType.Paddle {
            self.syncState = GameSync.None
        }
    }
    
    func gotStatePacket(_ packet: StatePacket) {
    
        print("packet: State Change: \(packet.state.description)")
        
        self._playerScore = packet.opponentScore
        
        self._opponentScore = packet.playerScore
        
        switch packet.state {
        case GameState.Countdown2, GameState.Countdown3:
            self.viewDelegate?.updateStatus(String(format:"%i", packet.state.rawValue-1))
            break
        case GameState.Running:
            self.viewDelegate?.updateStatus(nil)
            break
        default:
            break
        }
    
        self.state = packet.state
        
        // reset the waiting state
        self.syncState = GameSync.None
        
        self.playerTurn = (packet.hostingFlags & PacketFlags.PlayerTurn) == 0
    }
    
    func gotBallPacket(_ packet: BallPacket )
    {
        print("packet: Ball Change")
    
        self.playerTurn = (packet.hostingFlags & PacketFlags.PlayerTurn) == 0
        
        let opponentOnLeft = (packet.hostingFlags & PacketFlags.PlayerOnLeft) != 0
        
        let scalingX = UIScreen.main.bounds.height / packet.screenHeight
        let scalingY = UIScreen.main.bounds.width / packet.screenWidth
        
        var ballX = packet.ballX
        
        var ballY = packet.ballY
        
        var velocityX = packet.velocityX
        //var velocityY = packet.velocityY
        
        ballX /= scalingX
        ballY /= scalingY
        
        if opponentOnLeft {
            if Settings.sharedInstance.playerOnLeft {
                // move opponent to the right
                ballX = UIScreen.main.bounds.height - ballX
                velocityX = -velocityX
            }
        } else {
            if !Settings.sharedInstance.playerOnLeft {
                // move opponent to left
                ballX = UIScreen.main.bounds.height - ballX
                velocityX = -velocityX
            }
        }
        
        let ballLocation: CGPoint = CGPoint(x: ballX, y: ballY)
        
        self.ballVelocity = CGPoint(x: velocityX, y: packet.velocityY)
        
        self.viewDelegate?.updateGame(self, withBall:ballLocation)
        
        if self.state == GameState.Over {
            self.viewDelegate?.gameOver(self)
        }
        
        self.syncState = GameSync.None
    }
    
    
    func update(ball: UIView, playerPaddle: UIView, opponentPaddle: UIView) {
    
        // if we're not running, or waiting for a network sync...
        if self.state != GameState.Running || self.syncState != GameSync.None {
            if self.syncState != GameSync.None {
                print("Skipping update, waiting for ACK")
            }
            // just return
            return
        }
        
        // set the ball center
        ball.center = CGPoint(x: ball.center.x + self.speedX, y: ball.center.y + self.speedY)
        
        let screenSize = UIScreen.main.bounds.size
        
        let settings = Settings.sharedInstance
        
        if ball.center.y > screenSize.height - 25 || ball.center.y < 25 {
            self.ballVelocity.y = -self.ballVelocity.y
            if settings.playSounds {
                self.sndWall.play()
            }
            self.broadcast(type: PacketType.Ball)
        }
        
        if playerPaddle.frame.intersects(ball.frame) {
            var frame = ball.frame
            self.calcSpeedBonus(ball: ball, paddle: playerPaddle, margin: 1)
            frame.origin.x = settings.playerOnLeft ? playerPaddle.frame.maxX : (playerPaddle.frame.origin.x - frame.size.height)
            ball.frame = frame
            self.ballVelocity.x = -self.ballVelocity.x
            if settings.playSounds {
                self.sndPaddle.play()
            }
            print("Player hit ball")
            self.broadcast(type: PacketType.Ball)
        }
        
        else if self.opponentIsComputer && opponentPaddle.frame.intersects(ball.frame) {
            var frame = ball.frame
            
            if settings.difficulty != GameDifficulty.Easy {
                self.calcSpeedBonus(ball: ball, paddle:opponentPaddle, margin: 0)
            } else {
                self.speedBonus = CGPoint.zero
            }
        
            frame.origin.x = settings.playerOnLeft ? (opponentPaddle.frame.origin.x - frame.size.height) : opponentPaddle.frame.maxX
            ball.frame = frame
        
            self.ballVelocity.x = -self.ballVelocity.x
        
            if settings.playSounds {
                self.sndPaddle.play()
            }
            print("Computer hit ball")
        }
            
        else if ball.center.x > screenSize.width || ball.center.x < 0 {
            self.ballVelocity.x = -self.ballVelocity.x
            
            broadcast(type: PacketType.Ball)
        }
        
        // Begin Simple AI
        else if self.opponentIsComputer && (settings.playerOnLeft ? (ball.center.x >= screenSize.width/2) : (ball.center.x <= screenSize.width/2)) {
            if self.randomAILag < self.interval {
                updateAI(ball: ball, aiPaddle: opponentPaddle, settings: settings, screenSize: screenSize)
            }
        }
    }
    
    private func updateAI(ball: UIView, aiPaddle: UIView, settings: Settings, screenSize: CGSize) {
        
        let speed = CGFloat(settings.difficulty.toSpeedValue())
        
        var percent:UInt32
        
        switch settings.difficulty
        {
        case GameDifficulty.Easy:
            percent = arc4random() % 3500
            break
        case GameDifficulty.Normal:
            percent = arc4random() % 7500
            break
        case GameDifficulty.Hard:
            percent = 100
            break
        }
        
        if percent < 20 {
            print("Random lag!")
            self.randomAILag = self.interval + TimeInterval(settings.difficulty.rawValue+1)
        }
        
        if ball.center.y < aiPaddle.center.y {
            let compLocation = CGPoint(x: aiPaddle.center.x, y: aiPaddle.center.y - speed)
            if compLocation.y - aiPaddle.frame.size.height/2 > 25 && compLocation.y + aiPaddle.frame.size.height/2 < screenSize.height-25 {
                aiPaddle.center = compLocation
            }
        }
        
        if ball.center.y > aiPaddle.center.y {
            let compLocation = CGPoint(x: aiPaddle.center.x, y: aiPaddle.center.y + speed)
            if compLocation.y - aiPaddle.frame.size.height/2 > 25 && compLocation.y + aiPaddle.frame.size.height/2 < screenSize.height-25 {
                aiPaddle.center = compLocation
            }
        }
    }
    
    func newGame(isComputer: Bool) {
        
        self.opponentScore = 0
        self.playerScore = 0
        self.opponentIsComputer = isComputer
        
        if let delegate = self.viewDelegate {
            let pos = (arc4random_uniform(100) < 50) ? delegate.playerPosition : delegate.opponentPosition
            delegate.newGame(self, ballPosition:pos)
        }
        
        self.state = GameState.Countdown1
        self.syncState = GameSync.None
        
        if !isComputer {
            self.multiplayer.delegate = self
            self.sendPacket(type: PacketType.State)
        }
    }
    
    func gameOver(disconnected: Bool) {
    
        self.state = disconnected ? GameState.Disconnected : GameState.Over
        
        self.viewDelegate?.gameOver(self)
        
        self.opponentScore = 0
        self.playerScore = 0
        
        self.multiplayer.disconnect()
        
        self.interval = 0
    }
    
    func peerFound(_ multiplayer: Multiplayer, peer: NSObject) {
        switch self.state {
        case .Disconnected,.Over:
             DispatchQueue.main.async {
                self.newGame(isComputer: false)
            }
            
        default:
            print("Got new peer, but already in a game!")
        }
    }
    
    func peerLost(_ multiplayer: Multiplayer, peer: NSObject) {
         DispatchQueue.main.async {
            self.gameOver(disconnected: true)
        }
    }
    
    func resetForPlayer(opponent: Bool) {
    
        self.state = GameState.Countdown1
        
        self.syncState = GameSync.None
        
        self.playerTurn = !opponent
        
        if let delegate = self.viewDelegate {
            let ballLocation = (opponent) ? delegate.opponentPosition : delegate.playerPosition
        
            delegate.updateGame(self, withBall:ballLocation)
        }
        
        self.broadcast(type: PacketType.State)
    }
    
    func updatePlayerScore(label: UILabel) {
        print("Player scored")
        
        self._playerScore += 1
        
        label.text = String(format:"%d", self._playerScore)
    
        if self._playerScore >= Settings.sharedInstance.gamePoint {
            self.gameOver(disconnected: false)
        } else {
            self.resetForPlayer(opponent: false)
        }
    }
    
    func updateOpponentScore(label: UILabel) {
        print("Opponent scored")
        
        self._opponentScore += 1
        
        label.text = String(format: "%d", self._opponentScore)
        
        if self._opponentScore >= Settings.sharedInstance.gamePoint {
            self.gameOver(disconnected: false)
        } else {
            self.resetForPlayer(opponent: true)
        }
    }
    
    @objc func gameLoopInterval(_ timer: Timer) {
    
        if self.state.rawValue <= GameState.Paused.rawValue || self.state == GameState.Over {
            return
        }
    
        self.interval += 1
        
        self.viewDelegate?.gameTick(self)
    }
    
    func findMultiplayerMatch(forViewController viewController: UIViewController, delegate: MultiplayerDelegate?) {
        
        self.multiplayer.delegate = delegate
        
        self.multiplayer.findMatch(forViewController: viewController)
    
    }
    
}

