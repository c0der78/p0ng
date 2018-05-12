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
    case Countdown1, Countdown2, Countdown3
    case Running
    case Over
    
    var description : String {
        switch(self) {
        case .Disconnected: return "Disconnected"
        case .Paused: return "Paused"
        case .Countdown1: return "Countdown1"
        case .Countdown2: return "Countdown2"
        case .Countdown3: return "Countdown3"
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

//! type of network packet
enum PacketType: UInt8 {
    case State, PaddleMove, Paddle, Ball, Ack
    
    var description : String {
        switch(self) {
        case .State: return "State"
        case .Paddle: return "Paddle"
        case .PaddleMove: return "PaddleMove"
        case .Ball: return "Ball"
        case .Ack: return "Ack"
        }
    }
    
    var needsAck : Bool {
        switch(self) {
        case .Ack, .PaddleMove:
            return false
        default:
            return true
        }
    }
    
    static func decode(data: Data) -> PacketType {
        if let coding = NSKeyedUnarchiver.unarchiveObject(with: data) as? Coding {
            return PacketType(rawValue: coding.type) ?? PacketType.State
        }
        return PacketType.State
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: Coding(self))
    }
    
    @objc(PacketType) class Coding : NSObject, NSCoding {
        let type: UInt8
        
        init(_ packet: PacketType) {
            self.type = packet.rawValue
        }
        
        required init?(coder: NSCoder) {
            if let val = coder.decodeObject(forKey: "type") as? NSNumber {
                self.type = val.uint8Value
            } else {
                self.type = 0
            }
        }
        
       func encode(with coder: NSCoder) {
            coder.encode(NSNumber(value: self.type), forKey: "type")
        }
    }
}

//! flags on a packet
struct PacketFlags {
    static var PlayerTurn:UInt8 = (1 << 0)
    static var PlayerOnLeft:UInt8 = (1 << 1)
}

//! a packet
struct StatePacket
{
    var state: GameState
    var playerScore: UInt16
    var opponentScore: UInt16
    var hostingFlags: UInt8
    
    init() {
        self.state = GameState.Paused
        self.playerScore = 0
        self.opponentScore = 0
        self.hostingFlags = 0
    }
    init(data: Data) {
        let coding = NSKeyedUnarchiver.unarchiveObject(with: data) as! Coding
        self.state = coding.state
        self.playerScore = coding.playerScore
        self.opponentScore = coding.opponentScore
        self.hostingFlags = coding.hostingFlags
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: Coding(self))
    }
    
    @objc(StatePacket) class Coding: NSObject, NSCoding {
        let state: GameState
        let playerScore: UInt16
        let opponentScore: UInt16
        let hostingFlags: UInt8
        
        init(_ packet: StatePacket) {
            self.state = packet.state
            self.playerScore = packet.playerScore
            self.opponentScore = packet.opponentScore
            self.hostingFlags = packet.hostingFlags
        }
        
        required init?(coder aDecoder: NSCoder) {
            var val = aDecoder.decodeObject(forKey: "state") as? NSNumber
            if val != nil {
                self.state = GameState(rawValue: val!.int16Value) ?? GameState.Disconnected
            } else {
                self.state = GameState.Disconnected
            }
            val = aDecoder.decodeObject(forKey: "playerScore") as? NSNumber
            self.playerScore = val != nil ? val!.uint16Value : 0
            
            val = aDecoder.decodeObject(forKey: "opponentScore") as? NSNumber
            self.opponentScore = val != nil ? val!.uint16Value : 0
            
            val = aDecoder.decodeObject(forKey: "hostingFlags") as? NSNumber
            self.hostingFlags = val != nil ? val!.uint8Value : 0
        }
        
        func encode(with aCoder: NSCoder) {
            aCoder.encode(NSNumber( value: self.state.rawValue), forKey: "state")
            aCoder.encode(NSNumber( value: self.playerScore), forKey: "playerScore")
            aCoder.encode(NSNumber( value: self.opponentScore), forKey: "opponentScore")
            aCoder.encode(NSNumber( value: self.hostingFlags), forKey: "hostingFlags")
        }
    }
}

struct BallPacket
{
    var ballX: CGFloat
    var ballY: CGFloat
    var velocityX: CGFloat
    var velocityY: CGFloat
    var screenHeight: CGFloat
    var screenWidth: CGFloat
    var hostingFlags: UInt8
    
    init() {
        self.ballX = 0
        self.ballY = 0
        self.velocityX = 0
        self.velocityY = 0
        self.screenHeight = UIScreen.main.bounds.height
        self.screenWidth = UIScreen.main.bounds.width
        self.hostingFlags = 0
    }
    
    init(data: Data) {
        if let coding = NSKeyedUnarchiver.unarchiveObject(with: data) as? Coding {
            self.ballX = coding.ballX
            self.ballY = coding.ballY
            self.velocityX = coding.velocityX
            self.velocityY = coding.velocityY
            self.screenHeight = coding.screenHeight
            self.screenWidth = coding.screenWidth
            self.hostingFlags = coding.hostingFlags
        } else {
            self.ballX = 0
            self.ballY = 0
            self.velocityX = 0
            self.velocityY = 0
            self.screenWidth = 0
            self.screenHeight = 0
            self.hostingFlags = 0
        }
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: Coding(self))
    }
    
    @objc(BallPacket) class Coding: NSObject, NSCoding {
        let ballX: CGFloat
        let ballY: CGFloat
        let velocityX: CGFloat
        let velocityY: CGFloat
        let screenHeight: CGFloat
        let screenWidth: CGFloat
        let hostingFlags: UInt8
        
        init(_ packet: BallPacket) {
            self.ballX = packet.ballX
            self.ballY = packet.ballY
            self.velocityY = packet.velocityY
            self.velocityX = packet.velocityX
            self.screenWidth = packet.screenWidth
            self.screenHeight = packet.screenHeight
            self.hostingFlags = packet.hostingFlags
        }
        
        required init?(coder aDecoder: NSCoder) {
            self.ballX = CGFloat(aDecoder.decodeFloat(forKey: "ballX"))
            self.ballY = CGFloat(aDecoder.decodeFloat(forKey: "ballY"))
            self.velocityX = CGFloat(aDecoder.decodeFloat(forKey: "velocityX"))
            self.velocityY = CGFloat(aDecoder.decodeFloat(forKey: "velocityY"))
            self.screenHeight = CGFloat(aDecoder.decodeFloat(forKey: "screenHeight"))
            self.screenWidth = CGFloat(aDecoder.decodeFloat(forKey: "screenWidth"))
            if let flags = aDecoder.decodeObject(forKey: "hostingFlags") as? NSNumber {
                self.hostingFlags = flags.uint8Value
            } else {
                self.hostingFlags = 0
            }
        }
        
        func encode(with aCoder: NSCoder) {
            aCoder.encode(Float(self.ballX), forKey: "ballX")
            aCoder.encode(Float(self.ballY), forKey: "ballY")
            aCoder.encode(Float(self.velocityX), forKey: "velocityX")
            aCoder.encode(Float(self.velocityY), forKey: "velocityY")
            aCoder.encode(Float(self.screenHeight), forKey: "screenHeight")
            aCoder.encode(Float(self.screenWidth), forKey: "screenWidth")
            aCoder.encode(NSNumber(value: self.hostingFlags), forKey: "hostingFlags")
        }
    }
}

struct PaddlePacket
{
    var paddleY: CGFloat
    var screenWidth: CGFloat
    
    init() {
        self.paddleY = 0
        self.screenWidth = UIScreen.main.bounds.width
    }
    
    init(data: Data) {
        if let coding = NSKeyedUnarchiver.unarchiveObject(with: data) as? Coding {
            self.paddleY = coding.paddleY
            self.screenWidth = coding.screenWidth
        } else {
            NSLog("invalid data for PaddlePacket")
            self.paddleY = 0
            self.screenWidth = 0
        }
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: Coding(self))
    }
    
    @objc(PaddlePacket) class Coding: NSObject, NSCoding {
        let paddleY: CGFloat
        let screenWidth: CGFloat
        
        init(_ packet: PaddlePacket) {
            self.paddleY = packet.paddleY
            self.screenWidth = packet.screenWidth
        }
        
        required init?(coder: NSCoder) {
            self.paddleY = CGFloat(coder.decodeFloat(forKey: "paddleY"))
            self.screenWidth = CGFloat(coder.decodeFloat(forKey: "screenWidth"))
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(Float(self.paddleY), forKey: "paddleY")
            coder.encode(Float(self.screenWidth), forKey: "screenWidth")
        }
    }
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

//! a game protocol
protocol GameProtocol
{
    func newGame(_ game: Game, ballPosition position: CGPoint)

    func gameOver( _ game: Game)

    func gameTick(_ game: Game)

    func updateGame(_ game: Game, withBall ballLocation: CGPoint)

    func setOpponentPaddle(_ game: Game, withYLocation location: CGFloat)

    func updateStatus(_ status: String?)

    var playerPosition: CGPoint { get }

    var opponentPosition: CGPoint { get }

    var ballPosition: CGPoint { get }

}

class Game : NSObject
{
    static let sharedInstance = Game()
    
    // MARK: Private variables
    private var _playerScore:UInt16
    private var _opponentScore:UInt16
    
    // MARK: Internal variables
    var randomAILag:TimeInterval
    var timer: Timer!
    var scale:CGFloat
    var sndWall:AVAudioPlayer!
    var sndPaddle:AVAudioPlayer!
    var speedBonus:CGPoint
    var opponentIsComputer:Bool
    var ballVelocity:CGPoint
    var state:GameState
    var interval:TimeInterval
    var playerTurn:Bool
    var delegate: GameProtocol?
    var syncState:GameSync
    
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
                NSLog("%@", error)
            }
        }
        
        soundPath = Bundle.main.url(forResource: "offthewall", withExtension: "wav")
        
        if soundPath != nil {
            do {
                try self.sndWall = AVAudioPlayer(contentsOf: soundPath!)
            }
            catch let error as NSError {
                NSLog("%@", error)
            }
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: Settings.sharedInstance.speed, target:self, selector:#selector(gameLoopInterval(_:)), userInfo:nil, repeats:true)
        
        Settings.addListener(self, selector:#selector(settingsChanged(_:)))
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
            NSLog("No settings in notification")
            return
        }
    
        self.timer.invalidate()
            
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
        
        NSLog("Speed Bonus!")
    }
    
    func createPaddlePacket(_ data: inout Data) {
        var packet = PaddlePacket()
        if self.delegate != nil {
            packet.paddleY = self.delegate!.playerPosition.y
        }
        data.append(packet.asData())
    }
    
    func createStatePacket(_ data: inout Data) {
        var packet = StatePacket()
        
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

        data.append(packet.asData())
    }
    
    func createBallPacket(_ data: inout Data) {
        var packet = BallPacket()
        
        packet.velocityY = self.ballVelocity.y
        packet.velocityX = self.ballVelocity.x
        
        if self.delegate != nil {
            let position = self.delegate!.ballPosition

            packet.ballY = position.y
            packet.ballX = position.x
        }
        
        if self.playerTurn {
            packet.hostingFlags |= PacketFlags.PlayerTurn
        }
        
        if Settings.sharedInstance.playerOnLeft {
            packet.hostingFlags |= PacketFlags.PlayerOnLeft
        }
        
        data.append(packet.asData())
    }
    
    //! sends a packet to game center
    func sendPacket( type: PacketType ) {
        
        if self.delegate == nil || self.state == GameState.Disconnected || self.opponentIsComputer {
            return
        }
        
        var data = type.asData()
        
        switch type {
        case .Ball:
            self.createBallPacket(&data)
            break
        case .Paddle, .PaddleMove:
            self.createPaddlePacket(&data)
            break
        case .State:
            self.createStatePacket(&data)
            break
        default:
            break
        }
        
        if type.needsAck {
            GameCenter.sharedInstance.sendReliableData(data: data)
        } else {
            GameCenter.sharedInstance.sendData(data: data)
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
            NSLog("broadcast: %@", type.description)
            self.syncState = GameSync.WaitingForAck
        }
    }
    
    func gotPaddlePacket(type: PacketType, packet: PaddlePacket) {
        
        NSLog("packet: Ball Change")
        
        let scalingY = UIScreen.main.bounds.width / packet.screenWidth
        
        self.delegate?.setOpponentPaddle(self, withYLocation: packet.paddleY / scalingY)
        
        if type == PacketType.Paddle {
            self.syncState = GameSync.None
        }
    }
    
    func gotStatePacket(_ packet: StatePacket) {
    
        NSLog("packet: State Change: %@", packet.state.description)
        
        self._playerScore = packet.opponentScore
        
        self._opponentScore = packet.playerScore
        
        switch packet.state {
        case GameState.Countdown2, GameState.Countdown3:
            self.delegate?.updateStatus(String(format:"%i", packet.state.rawValue-1))
            break
        case GameState.Running:
            self.delegate?.updateStatus(nil)
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
        NSLog("packet: Ball Change")
    
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
        
        self.delegate?.updateGame(self, withBall:ballLocation)
        
        if self.state == GameState.Over {
            self.delegate?.gameOver(self)
        }
        
        self.syncState = GameSync.None
    }
    
    
    func update(ball: UIView, playerPaddle: UIView, opponentPaddle: UIView) {
    
        // if we're not running, or waiting for a network sync...
        if self.state != GameState.Running || self.syncState != GameSync.None {
            if self.syncState != GameSync.None {
                NSLog("Skipping update, waiting for ACK")
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
            NSLog("Player hit ball")
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
            NSLog("Computer hit ball")
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
            NSLog("Random lag!")
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
        
        if self.delegate != nil {
            self.delegate!.newGame(self, ballPosition:(arc4random_uniform(100) < 50) ? self.delegate!.playerPosition : self.delegate!.opponentPosition)
        }
        
        self.state = GameState.Countdown1
        self.syncState = GameSync.None
        
        if !isComputer {
            self.sendPacket(type: PacketType.State)
        }
    }
    
    func gameOver(disconnected: Bool) {
    
        self.state = disconnected ? GameState.Disconnected : GameState.Over
        
        self.delegate?.gameOver(self)
        
        self.opponentScore = 0
        self.playerScore = 0
        
        GameCenter.sharedInstance.disconnect()
        
        self.interval = 0
    }
    
    
    func resetForPlayer(opponent: Bool) {
    
        self.state = GameState.Countdown1
        
        self.syncState = GameSync.None
        
        self.playerTurn = !opponent
        
        if let delegate = self.delegate {
            let ballLocation = (opponent) ? delegate.opponentPosition : delegate.playerPosition
        
            delegate.updateGame(self, withBall:ballLocation)
        }
        
        self.broadcast(type: PacketType.State)
    }
    
    func updatePlayerScore(label: UILabel) {
        NSLog("Player scored")
        
        self._playerScore += 1
        
        label.text = String(format:"%d", self._playerScore)
    
        if self._playerScore >= Settings.sharedInstance.gamePoint {
            self.gameOver(disconnected: false)
        } else {
            self.resetForPlayer(opponent: false)
        }
    }
    
    func updateOpponentScore(label: UILabel) {
        NSLog("Opponent scored")
        
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
        
        self.delegate?.gameTick(self)
    }
}

