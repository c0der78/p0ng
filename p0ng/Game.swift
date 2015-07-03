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

@objc
enum GameState: Int {
    case Disconnected = -1;
    case Paused;
    case Countdown1, Countdown2, Countdown3, Countdown4;
    case Running;
    case Over;
}

struct BallSpeed {
    static let X:CGFloat = 3
    static let Y:CGFloat = 4
}

@objc
enum PacketType: UInt8 {
    case Send, Ack, SendAndAck
}

struct PacketFlags {
    static var PlayerTurn:UInt8 = (1 << 0)
    static var PlayerOnLeft:UInt8 = (1 << 1)
}

struct p0ngPacket
{
    var ballX: Float;
    var ballY: Float;
    var paddleY: Float;
    var stateAndScores: UInt16;
    var hostingFlags: UInt8;
    var type: UInt8;
    
    init() {
        self.ballX = 0;
        self.ballY = 0;
        self.paddleY = 0;
        self.stateAndScores = 0;
        self.hostingFlags = 0;
        self.type = 0;
    }
}

@objc
enum GameSync: UInt8 {
    case None, WaitingForAck, HasToAck
}

@objc
protocol GameProtocol
{

    func newGame(game: Game, ballPosition position: CGPoint);

    func gameOver( game: Game);

    func gameTick(game: Game);

    func updateGame(game: Game, withBall ballLocation: CGPoint);

    func updateGame(game: Game, withOpponent location: CGFloat);

    func updateStatus(status: String?);

    var playerPosition: CGPoint { get };

    var opponentPosition: CGPoint { get };

    var ballPosition: CGPoint { get };

}

@objc
class Game
{
    static let sharedInstance = Game();
    
    // MARK: Private variables
    private var _playerScore:UInt;
    private var _opponentScore:UInt;
    
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
    
    private init() {
        
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
    
    var playerScore: UInt {
        
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
    
    var opponentScore: UInt {
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
        let settings = notification.object as! Settings;
        
        self.timer.invalidate();
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(settings.speed, target:self, selector:Selector("gameLoop:"), userInfo:nil, repeats:true);
    
    }
    
    func calcSpeedBonus(ball: UIView, paddle: UIView, margin: Int) {
        if(Int(ball.center.y - paddle.frame.origin.y) <= margin || Int((paddle.frame.origin.y+paddle.frame.size.height) - ball.center.y) <= margin) {
            self.speedBonus = CGPointMake(1.1, 1.2);
            NSLog("Speed Bonus!");
        }
        else {
            self.speedBonus = CGPointZero;
        }
    }
    
    func sendPacket( state: PacketType) {
        
        if (self.delegate == nil || self.state == GameState.Disconnected || self.opponentIsComputer) {
            return;
        }
        
        let screenSize:CGSize = UIScreen.mainScreen().bounds.size;
        
        let position:CGPoint = self.delegate!.ballPosition;
        
        let ballPos:CGPoint = CGPointMake(screenSize.height-position.x, position.y);
        
        var packet:p0ngPacket = p0ngPacket();
        
        packet.ballY = Float(ballPos.y);
        packet.paddleY = Float(self.delegate!.playerPosition.y);
        
        packet.stateAndScores = 0;
        packet.hostingFlags = 0;
        packet.type = state.rawValue;

        
        if(UIDevice.currentResolution() == UIDeviceResolution.iPhoneTallerHiRes) {
            packet.ballX = Float(ballPos.x / (1136.0/960.0));
        } else {
            packet.ballX = Float(ballPos.x);
        }
        
        packet.stateAndScores = UInt16(self.state.rawValue << 16) | UInt16(self._playerScore << 8) | UInt16(self._opponentScore);
        
        if(self.playerTurn) {
            packet.hostingFlags |= PacketFlags.PlayerTurn;
        }
        if(Settings.sharedInstance.playerOnLeft) {
            packet.hostingFlags |= PacketFlags.PlayerOnLeft;
        }
        
        let data = NSData(bytes:&packet, length:sizeof(p0ngPacket));
        
        
        if(state != PacketType.Send) {
            GameCenter.sharedInstance.sendReliableData(data);
        } else {
            GameCenter.sharedInstance.sendData(data);
        }
    }
    
    func broadcast ( ack: Bool) {
        
        if(self.opponentIsComputer) {
            return;
        }
        
        if(self.state.rawValue > GameState.Paused.rawValue)
        {
            if(ack)
            {
                if(self.syncState == GameSync.HasToAck)
                {
                    NSLog("SENDING ACK %ld", self.interval);
                    self.syncState = GameSync.None;
                    self.sendPacket(PacketType.Ack);
                }
                else
                {
                    NSLog("REQUESTING ACK %ld", self.interval);
                    self.syncState = GameSync.WaitingForAck;
                    self.sendPacket(PacketType.SendAndAck);
                }
            } else {
                NSLog("SEND %ld", self.interval);
                self.sendPacket(self.syncState == GameSync.WaitingForAck ? PacketType.SendAndAck : PacketType.Send);
            }
        }
    }
    
    func gotPacket(packet: p0ngPacket )
    {
        if(packet.type == PacketType.Ack.rawValue)
        {
            if(self.syncState == GameSync.WaitingForAck)
            {
                self.syncState = GameSync.None;
            }
        }
        else if(packet.type == PacketType.SendAndAck.rawValue)
        {
            if(self.syncState == GameSync.WaitingForAck) {
                NSLog("Sending ack %ld", self.interval);
                self.sendPacket(PacketType.Ack);
            }
            else if(self.syncState == GameSync.None) {
                self.syncState = GameSync.HasToAck;
                NSLog("Opponent waiting for ack %ld", self.interval);
            }
            return;
        }
        
        if(self.syncState == GameSync.WaitingForAck)
        {
            NSLog("Updated state from opponent");
            
            self.syncState = GameSync.None;
            
            NSLog("GOT ACK %ld", self.interval);
            
            let opponentScore = packet.stateAndScores & 0xff;
            let playerScore = (packet.stateAndScores >> 8) & 0xff;
            let state = GameState(rawValue: Int(packet.stateAndScores >> 16) & 0xff);
            
            if (state != nil) {
                if(self.state != state)
                {
                    NSLog("State Change: %d", state!.rawValue);
                    
                    self._playerScore = UInt(opponentScore);
                    
                    self._opponentScore = UInt(playerScore);
                    
                    if (self.delegate != nil) {
                        switch(state!)
                        {
                            case GameState.Countdown2,
                                 GameState.Countdown3,
                                 GameState.Countdown4:
                                self.delegate!.updateStatus(String(format:"%i", state!.rawValue-1));
                            break;
                            case GameState.Running:
                                self.delegate!.updateStatus(nil);
                            break;
                        }
                    }
                }
                
                self.state = state!;
            }
            
            self.playerTurn = (packet.hostingFlags & PacketFlags.PlayerTurn) == 0;
            
            var ballLocation: CGPoint;
            
            if( (packet.hostingFlags & PacketFlags.PlayerOnLeft) != 0 && Settings.sharedInstance.playerOnLeft) {
                ballLocation = CGPointMake(CGFloat(packet.ballX), CGFloat(packet.ballY));
            }
            else{
                ballLocation = CGPointMake(UIScreen.mainScreen().bounds.size.height - CGFloat(packet.ballX), CGFloat(packet.ballY));
            }
            
            if (self.delegate != nil) {
                self.delegate!.updateGame(self, withBall:ballLocation);
                
                if(self.state == GameState.Over) {
                    self.delegate!.gameOver(self);
                }
            }
        }
        
        if (self.delegate != nil) {
            self.delegate!.updateGame(self, withOpponent: CGFloat(packet.paddleY));
        }
        
    }
    
    func updateForBall(ball: UIView, andPaddle playerPaddle: UIView, andOpponent opponentPaddle: UIView) {
    
        if(self.state != GameState.Running || self.syncState != GameSync.None) {
            return;
        }
        
        ball.center = CGPointMake(ball.center.x + self.speedX, ball.center.y + self.speedY);
        
        var screenSize = UIScreen.mainScreen().bounds.size;
        
        screenSize = CGSizeMake(screenSize.width, screenSize.height);
        
        let settings = Settings.sharedInstance;
        
        if(ball.center.y > screenSize.height - 25 || ball.center.y < 25) {
            self.ballVelocity.y = -self.ballVelocity.y;
            if(settings.playSounds) {
                self.sndWall.play();
            }
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
            self.broadcast(true);
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
        
            self.broadcast(true);
        }
        
        else if(ball.center.x > screenSize.width || ball.center.x < 0) {
            self.ballVelocity.x = -self.ballVelocity.x;
        
        }
        
        // Begin Simple AI
        else if(self.opponentIsComputer && (settings.playerOnLeft ? (ball.center.x >= screenSize.width/2) : (ball.center.x <= screenSize.width/2))) {
        
            if(self.randomAILag < self.interval)
            {
                let speed = CGFloat(settings.difficultyValue);
            
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
            self.delegate!.newGame(self, ballPosition:arc4random_uniform(100) < 50 ? self.delegate!.playerPosition : self.delegate!.opponentPosition);
        }
        
        self.state = GameState.Countdown1;
        self.syncState = GameSync.None;
        
        if(!isComputer)
        {
            self.sendPacket(PacketType.Ack);
        }
    }
    
    func gameOver(disconnected: Bool) {
    
        self.state = disconnected ? GameState.Disconnected : GameState.Over;
        
        if (self.delegate != nil) {
            self.delegate!.gameOver(self);
        }
        
        self.opponentScore = 0;
        self.playerScore = 0;
        
        GameCenter.sharedInstance.disconnect();
        
        self.interval = 0;
    }
    
    
    func resetForPlayer(opponent: Bool) {
    
        self.state = GameState.Countdown1;
        self.syncState = GameSync.None;
        
        self.playerTurn = !opponent;
        
        let ballLocation = (opponent) ? self.delegate!.opponentPosition : self.delegate!.playerPosition;
        
        self.delegate!.updateGame(self, withBall:ballLocation);
        
        if(GameCenter.sharedInstance.isHosting) {
            self.broadcast(true);
        }
    
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
            
            if (self.delegate != nil) {
                self.delegate!.gameTick(self);
            }
        }
    
    }
}

