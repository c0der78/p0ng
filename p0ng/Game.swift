//
//  Game.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import Foundation
import AVFoundation
import GameKit


//! a state in the game
@objc enum GameState: Int16 {
    case Disconnected = -1;
    case Paused;
    case Countdown1, Countdown2, Countdown3;
    case Running;
    case Over;
    
    var description : String {
        switch(self) {
        case .Disconnected: return "Disconnected";
        case .Paused: return "Paused";
        case .Countdown1: return "Countdown1";
        case .Countdown2: return "Countdown2";
        case .Countdown3: return "Countdown3";
        case .Running: return "Running";
        case .Over: return "Over";
        }
    }
}

//! ball velocity values
struct BallSpeed {
    static let X:CGFloat = 3
    static let Y:CGFloat = 4
}

//! type of network packet
@objc enum PacketType: UInt8 {
    case State, PaddleMove, Paddle, Ball, Ack;
    
    var description : String {
        switch(self) {
        case .State: return "State";
        case .Paddle: return "Paddle";
        case .PaddleMove: return "PaddleMove";
        case .Ball: return "Ball";
        case .Ack: return "Ack";
        }
    }
    
    var needsAck : Bool {
        switch(self) {
        case .Ack, .PaddleMove:
            return false;
        default:
            return true;
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
    var state: GameState;
    var playerScore: UInt16;
    var opponentScore: UInt16;
    var hostingFlags: UInt8;
    
    init() {
        self.state = GameState.Paused;
        self.playerScore = 0;
        self.opponentScore = 0;
        self.hostingFlags = 0;
    }
};

struct BallPacket
{
    var ballX: CGFloat;
    var ballY: CGFloat;
    var velocityX: CGFloat;
    var velocityY: CGFloat;
    var screenHeight: CGFloat;
    var screenWidth: CGFloat;
    var hostingFlags: UInt8;
    
    init() {
        self.ballX = 0;
        self.ballY = 0;
        self.velocityX = 0;
        self.velocityY = 0;
        self.screenHeight = UIScreen.mainScreen().bounds.height;
        self.screenWidth = UIScreen.mainScreen().bounds.width;
        self.hostingFlags = 0;
    }

};

struct PaddlePacket
{
    var paddleY: CGFloat;
    var screenWidth: CGFloat;
    
    init() {
        self.paddleY = 0;
        self.screenWidth = UIScreen.mainScreen().bounds.width;
    }
};

//! network sync type
@objc enum GameSync: UInt8 {
    case None, WaitingForAck;//, HasToAck;
    
    var description : String {
        switch(self) {
        case .None: return "None";
        case .WaitingForAck: return "WaitingForAck";
        //case .HasToAck: return "HasToAck";
        }
    }
}

//! a game protocol
@objc protocol GameProtocol
{
    func newGame(game: Game, ballPosition position: CGPoint);

    func gameOver( game: Game);

    func gameTick(game: Game);

    func updateGame(game: Game, withBall ballLocation: CGPoint);

    func setOpponentPaddle(game: Game, withYLocation location: CGFloat);

    func updateStatus(status: String?);

    var playerPosition: CGPoint { get };

    var opponentPosition: CGPoint { get };

    var ballPosition: CGPoint { get };

}


func encode<T>(var value: T) -> NSData {
    return withUnsafePointer(&value) { p in
        NSData(bytes: p, length: sizeof(T))
    }
}

func decode<T>(data: NSData) -> T {

    let pointer = UnsafeMutablePointer<T>.alloc(sizeof(T))
    
    data.getBytes(pointer, length: sizeof(T))
    
    return pointer.move()
}

@objc class Game : NSObject
{
    static let sharedInstance = Game();
    
    // MARK: Private variables
    private var _playerScore:UInt16;
    private var _opponentScore:UInt16;
    
    // MARK: Internal variables
    var randomAILag:NSTimeInterval;
    var timer: NSTimer!;
    var scale:CGFloat;
    var sndWall:AVAudioPlayer!;
    var sndPaddle:AVAudioPlayer!;
    var speedBonus:CGPoint;
    var opponentIsComputer:Bool;
    var ballVelocity:CGPoint;
    var state:GameState;
    var interval:NSTimeInterval;
    var playerTurn:Bool;
    var delegate: GameProtocol?;
    var syncState:GameSync;
    
    // MARK: Initializers
    
    private override init() {
        
        self.opponentIsComputer = true;
        
        self.state = GameState.Disconnected;
        
        self.syncState = GameSync.None;
        
        self.randomAILag = 0;
        
        self.scale = UIScreen.mainScreen().scale;
        
        self.speedBonus = CGPointZero;
        
        self._playerScore = 0;
        
        self._opponentScore = 0;
        
        self.ballVelocity = CGPointMake(BallSpeed.X, BallSpeed.Y);
        
        self.interval = 0;
        
        self.playerTurn = false;
        
        super.init();
        
        var soundPath:NSURL? =  NSBundle.mainBundle().URLForResource("offthepaddle", withExtension:"wav");
        
        if (soundPath != nil) {
            do {
                try self.sndPaddle = AVAudioPlayer(contentsOfURL: soundPath!);
            }
            catch let error as NSError {
                NSLog("%@", error);
            }
        }
        
        soundPath = NSBundle.mainBundle().URLForResource("offthewall", withExtension: "wav");
        
        if (soundPath != nil) {
            do {
                try self.sndWall = AVAudioPlayer(contentsOfURL: soundPath!);
            }
            catch let error as NSError {
                NSLog("%@", error);
            }
        }
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(Settings.sharedInstance.speed, target:self, selector:Selector("gameLoop:"), userInfo:nil, repeats:true);
        
        Settings.addListener(self, selector:Selector("settingsChanged:"));
    }
    
    // MARK: Dynamic properties
    
    var speedX: CGFloat {
        get {
            var x:CGFloat = self.ballVelocity.x;
            
            if(x < 0) {
                x += -self.speedBonus.x;
            }
            else if(x > 0) {
                x += self.speedBonus.x;
            }
            
            return x;
        }
    }
    
    
    var speedY: CGFloat {
        get {
            var y:CGFloat = self.ballVelocity.y;
            
            if(y < 0) { y += -self.speedBonus.y; }
            else if(y > 0) { y += self.speedBonus.y; }
            
            return y;
        }
    }
    
    var playerScore: UInt16 {
        
        set(value) {
            self._playerScore = value;
            
            if(self._playerScore >= Settings.sharedInstance.gamePoint) {
                self.gameOver(false);
            }
        }
        get {
            return self._playerScore;
        }
    }
    
    var opponentScore: UInt16 {
        set(value) {
            self._opponentScore = value;
            
            if(self._opponentScore >= Settings.sharedInstance.gamePoint) {
                self.gameOver(false);
            }
        }
        
        get {
            return self._opponentScore;
        }
    }
    
    
    // MARK: Functions

    func settingsChanged(notification: NSNotification)
    {
        if let settings = notification.object as? Settings {
    
            self.timer.invalidate();
            
            self.timer = NSTimer.scheduledTimerWithTimeInterval(settings.speed, target:self, selector:Selector("gameLoop:"), userInfo:nil, repeats:true);
        }
    
    }
    
    func calcSpeedBonus(ball: UIView, paddle: UIView, margin: Int) {
        if(Int(ball.center.y - paddle.frame.origin.y) <= margin || Int((paddle.frame.origin.y+paddle.frame.size.height) - ball.center.y) <= margin) {
            
            let settings = Settings.sharedInstance;
            
            var bonus: CGPoint;
            
            switch(settings.difficulty) {
            case GameDifficulty.Easy:
                bonus = CGPointMake(1.1, 1.36);
                break;
            case GameDifficulty.Normal:
                bonus = CGPointMake(1.1, 1.28);
                break;
            case GameDifficulty.Hard:
                bonus = CGPointMake(1.1, 1.2);
                break;
            }
            
            self.speedBonus = bonus;
            NSLog("Speed Bonus!");
        }
        else {
            self.speedBonus = CGPointZero;
        }
    }
    
    func createPaddlePacket(data: NSMutableData) {
        var packet = PaddlePacket();
        packet.paddleY = self.delegate!.playerPosition.y;
        data.appendData(encode(packet));
    }
    
    func createStatePacket(data: NSMutableData) {
        var packet = StatePacket();
        
        packet.state = self.state;
        packet.playerScore = self._playerScore;
        packet.opponentScore = self._opponentScore;
        packet.hostingFlags = 0;
        
        if(self.playerTurn) {
            packet.hostingFlags |= PacketFlags.PlayerTurn;
        }
        
        if(Settings.sharedInstance.playerOnLeft) {
            packet.hostingFlags |= PacketFlags.PlayerOnLeft;
        }
        
        
        data.appendData(encode(packet));
    }
    
    func createBallPacket(data: NSMutableData) {
        var packet = BallPacket();
        
        packet.velocityY = self.ballVelocity.y;
        packet.velocityX = self.ballVelocity.x;
        
        let position:CGPoint = self.delegate!.ballPosition;

        packet.ballY = position.y;
        packet.ballX = position.x;
        
        if(self.playerTurn) {
            packet.hostingFlags |= PacketFlags.PlayerTurn;
        }
        
        if(Settings.sharedInstance.playerOnLeft) {
            packet.hostingFlags |= PacketFlags.PlayerOnLeft;
        }
        
        data.appendData(encode(packet));
    }
    
    //! sends a packet to game center
    func sendPacket( type: PacketType ) {
        
        if (self.delegate == nil || self.state == GameState.Disconnected || self.opponentIsComputer) {
            return;
        }
        
        let data = NSMutableData();
        
        data.appendData(encode(type));
        
        switch(type) {
        case .Ball:
            self.createBallPacket(data);
            break;
        case .Paddle, .PaddleMove:
            self.createPaddlePacket(data);
            break;
        case .State:
            self.createStatePacket(data);
            break;
        default:
            break;
        }
        
        if(type.needsAck) {
            GameCenter.sharedInstance.sendReliableData(data);
        } else {
            GameCenter.sharedInstance.sendData(data);
        }
    }
    
    func broadcast ( type: PacketType) {
        
        if(self.opponentIsComputer) {
            return;
        }
        
        if(self.state.rawValue > GameState.Paused.rawValue)
        {
            self.sendPacket(type);
            
            if (type.needsAck) {
                NSLog("broadcast: %@", type.description);
                self.syncState = GameSync.WaitingForAck;
            }
        }
    }
    
    func gotPaddlePacket(type: PacketType, packet: PaddlePacket)
    {
        
        NSLog("packet: Ball Change");
        
        let scalingY = (UIScreen.mainScreen().bounds.width / packet.screenWidth);
        
        self.delegate?.setOpponentPaddle(self, withYLocation: packet.paddleY / scalingY);
        
        if (type == PacketType.Paddle) {
            self.syncState = GameSync.None;
        }
    }
    
    func gotStatePacket(packet: StatePacket)
    {
    
        NSLog("packet: State Change: %@", packet.state.description);
        
        self._playerScore = packet.opponentScore;
        
        self._opponentScore = packet.playerScore;
        
        if (self.delegate != nil) {
            switch(packet.state)
            {
            case GameState.Countdown2,
            GameState.Countdown3:
                self.delegate!.updateStatus(String(format:"%i", packet.state.rawValue-1));
                break;
            case GameState.Running:
                self.delegate!.updateStatus(nil);
                break;
            default:
                break;
            }
        }
        self.state = packet.state;
        
        // reset the waiting state
        self.syncState = GameSync.None;
        self.playerTurn = (packet.hostingFlags & PacketFlags.PlayerTurn) == 0;
    }
    
    func gotBallPacket(packet: BallPacket )
    {
        
        NSLog("packet: Ball Change");
    
        self.playerTurn = (packet.hostingFlags & PacketFlags.PlayerTurn) == 0;
        
        let opponentOnLeft = (packet.hostingFlags & PacketFlags.PlayerOnLeft) != 0;
        
        let scalingX = (UIScreen.mainScreen().bounds.height / packet.screenHeight);
        let scalingY = (UIScreen.mainScreen().bounds.width / packet.screenWidth);
        
        var ballX = packet.ballX;
        
        var ballY = packet.ballY;
        
        var velocityX = packet.velocityX;
        //var velocityY = packet.velocityY;
        
        ballX /= scalingX;
        ballY /= scalingY;
        
        if(opponentOnLeft) {
            
            if (Settings.sharedInstance.playerOnLeft) {
                // move opponent to the right
                ballX = UIScreen.mainScreen().bounds.height - ballX;
                velocityX = -velocityX;
            }
        } else {
            if (!Settings.sharedInstance.playerOnLeft) {
                // move opponent to left
                ballX = UIScreen.mainScreen().bounds.height - ballX;
                velocityX = -velocityX;
            }
        }
        
        let ballLocation: CGPoint = CGPointMake(ballX, ballY);
        
        self.ballVelocity = CGPointMake(velocityX, packet.velocityY);
        
        self.delegate?.updateGame(self, withBall:ballLocation);
        
        if(self.state == GameState.Over) {
            self.delegate?.gameOver(self);
        }
        
        self.syncState = GameSync.None;
    }
    
    
    func update(ball: UIView, playerPaddle: UIView, opponentPaddle: UIView) {
    
        // if we're not running, or waiting for a network sync...
        if(self.state != GameState.Running || self.syncState != GameSync.None) {
            if (self.syncState != GameSync.None) {
                NSLog("Skipping update, waiting for ACK");
            }
            // just return
            return;
        }
        
        // set the ball center
        ball.center = CGPointMake(ball.center.x + self.speedX, ball.center.y + self.speedY);
        
        var screenSize = UIScreen.mainScreen().bounds.size;
        
        screenSize = CGSizeMake(screenSize.width, screenSize.height);
        
        let settings = Settings.sharedInstance;
        
        if(ball.center.y > screenSize.height - 25 || ball.center.y < 25) {
            self.ballVelocity.y = -self.ballVelocity.y;
            if(settings.playSounds) {
                self.sndWall.play();
            }
            self.broadcast(PacketType.Ball);
        }
        
        if (CGRectIntersectsRect (ball.frame, playerPaddle.frame)) {
            var frame = ball.frame;
            self.calcSpeedBonus(ball, paddle: playerPaddle, margin: 1);
            frame.origin.x = settings.playerOnLeft ? CGRectGetMaxX(playerPaddle.frame) : (playerPaddle.frame.origin.x - frame.size.height);
            ball.frame = frame;
            self.ballVelocity.x = -self.ballVelocity.x;
            if(settings.playSounds) {
                self.sndPaddle.play();
            }
            NSLog("Player hit ball");
            self.broadcast(PacketType.Ball);
        }
        
        else if (self.opponentIsComputer && CGRectIntersectsRect (ball.frame, opponentPaddle.frame)) {
            var frame = ball.frame;
            if(settings.difficulty != GameDifficulty.Easy) {
                self.calcSpeedBonus(ball, paddle:opponentPaddle, margin: 0);
            }
            else {
                self.speedBonus = CGPointZero;
            }
        
            frame.origin.x = settings.playerOnLeft ? (opponentPaddle.frame.origin.x - frame.size.height) : CGRectGetMaxX(opponentPaddle.frame);
            ball.frame = frame;
        
            self.ballVelocity.x = -self.ballVelocity.x;
        
            if(settings.playSounds) {
                self.sndPaddle.play();
            }
            NSLog("Computer hit ball");
        }
            
        else if(ball.center.x > screenSize.width || ball.center.x < 0) {
            self.ballVelocity.x = -self.ballVelocity.x;
            broadcast(PacketType.Ball);
        }
        
        // Begin Simple AI
        else if(self.opponentIsComputer && (settings.playerOnLeft ? (ball.center.x >= screenSize.width/2) : (ball.center.x <= screenSize.width/2))) {
        
            if(self.randomAILag < self.interval)
            {
                let speed = CGFloat(settings.difficulty.toSpeedValue());
            
                var percent:UInt32;
            
                switch(settings.difficulty)
                {
                case GameDifficulty.Easy:
                    percent = arc4random() % 3500;
                    break;
                case GameDifficulty.Normal:
                    percent = arc4random() % 7500;
                    break;
                case GameDifficulty.Hard:
                    percent = 100;
                    break;
                }
                
                if(percent < 20) {
                    NSLog("Random lag!");
                    self.randomAILag = self.interval + NSTimeInterval(settings.difficulty.rawValue+1);
                }
            
                if(ball.center.y < opponentPaddle.center.y) {
                    let compLocation = CGPointMake(opponentPaddle.center.x, opponentPaddle.center.y - speed);
                    if(compLocation.y - opponentPaddle.frame.size.height/2 > 25 && compLocation.y + opponentPaddle.frame.size.height/2 < screenSize.height-25) {
                        opponentPaddle.center = compLocation;
                    }
                }
                
                if(ball.center.y > opponentPaddle.center.y) {
                    let compLocation = CGPointMake(opponentPaddle.center.x, opponentPaddle.center.y + speed);
                    if(compLocation.y - opponentPaddle.frame.size.height/2 > 25 && compLocation.y + opponentPaddle.frame.size.height/2 < screenSize.height-25) {
                        opponentPaddle.center = compLocation;
                    }
                }
            }
        
        }
    }
    
    func newGame(isComputer: Bool) {
        
        self.opponentScore = 0;
        self.playerScore = 0;
        self.opponentIsComputer = isComputer;
        
        if (self.delegate != nil) {
            self.delegate!.newGame(self, ballPosition:(arc4random_uniform(100) < 50) ? self.delegate!.playerPosition : self.delegate!.opponentPosition);
        }
        
        self.state = GameState.Countdown1;
        self.syncState = GameSync.None;
        
        if(!isComputer)
        {
            self.sendPacket(PacketType.State);
        }
    }
    
    func gameOver(disconnected: Bool) {
    
        self.state = disconnected ? GameState.Disconnected : GameState.Over;
        
        self.delegate?.gameOver(self);
        
        self.opponentScore = 0;
        self.playerScore = 0;
        
        GameCenter.sharedInstance.disconnect();
        
        self.interval = 0;
    }
    
    
    func resetForPlayer(opponent: Bool) {
    
        self.state = GameState.Countdown1;
        self.syncState = GameSync.None;
        
        self.playerTurn = !opponent;
        
        if let delegate = self.delegate {
            let ballLocation = (opponent) ? delegate.opponentPosition : delegate.playerPosition;
        
            delegate.updateGame(self, withBall:ballLocation);
        }
        
        self.broadcast(PacketType.State);
    }
    
    func updatePlayerScore(label: UILabel) {
        NSLog("Player scored");
        
        self._playerScore++;
        
        label.text = String(format:"%d", self._playerScore);
    
        if(self._playerScore >= Settings.sharedInstance.gamePoint) {
            self.gameOver(false);
        } else {
            self.resetForPlayer(false);
        }
    }
    
    func updateOpponentScore(label: UILabel) {
        NSLog("Opponent scored");
        self._opponentScore++;
        label.text = String(format: "%d", self._opponentScore);
        if(self._opponentScore >= Settings.sharedInstance.gamePoint) {
            self.gameOver(false);
        } else {
            self.resetForPlayer(true);
        }
    }
    
    func gameLoop(timer: NSTimer) {
    
        if(self.state.rawValue > GameState.Paused.rawValue && self.state != GameState.Over) {
        
            self.interval++;
            
            self.delegate?.gameTick(self);
        }
    
    }
}

