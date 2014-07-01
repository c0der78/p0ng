//
//  A3PongGame.m
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-08.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import "A3PongGame.h"
#import "A3GameController.h"
#import "A3GameCenter.h"
#import "UIDevice+Resolutions.h"
#import "A3PongSettings.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation A3PongGame

static A3PongGame *sharedGame = nil;

+ (A3PongGame *) sharedInstance {
    if(!sharedGame) {
        sharedGame = [[A3PongGame alloc] init];
    }
    return sharedGame;
}

- (void) settingsChanged:(NSNotification *) notification
{
    A3PongSettings *settings = notification.object;
    
    [_timer invalidate];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:settings.speed target:self selector:@selector(gameLoop:) userInfo:nil repeats:YES];

}

- (id)init {
    if ((self = [super init])) {
        
        _opponentIsComputer = YES;
        
        _state = kGameStateDisconnected;
        
        _syncState = kGameSyncNone;
        
        NSNotificationCenter *nc =
        [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(settingsChanged:)
                   name:A3SettingsDidChangeNotificationName
                 object:nil];
        
        _speedBonus = CGPointZero;
        
        NSURL *soundPath =  [[NSBundle mainBundle] URLForResource:@"offthepaddle" withExtension:@"wav"];
        
        _sndPaddle = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:soundPath error:nil];
        
        soundPath = [[NSBundle mainBundle] URLForResource: @"offthewall" withExtension: @"wav"];
        
        _sndWall = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:soundPath error:nil];
        
        _randomAILag = 0;
        
        _scale = ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]) ? [UIScreen mainScreen].scale: 1.0;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:[A3PongSettings sharedInstance].speed target:self selector:@selector(gameLoop:) userInfo:nil repeats:YES];
    }
    return self;
}

- (void) calcSpeedBonus: (UIView *) ball andPaddle: (UIView *) paddle margin: (float) margin {
    if(ball.center.y - paddle.frame.origin.y <= margin || (paddle.frame.origin.y+paddle.frame.size.height) - ball.center.y <= margin) {
        _speedBonus = CGPointMake(1.1, 1.2);
        NSLog(@"Speed Bonus!");
    }
    else
        _speedBonus = CGPointZero;
}

- (float) getSpeedX {
    float x = _ballVelocity.x;
    
    if(x < 0) x += -_speedBonus.x;
    else if(x > 0) x += _speedBonus.x;
    
    return x;
}

- (float) getSpeedY {
    float y = _ballVelocity.y;
    
    if(y < 0) y += -_speedBonus.y;
    else if(y > 0) y += _speedBonus.y;
    
    return y;
}

- (void) sendPacket: (NSInteger) state {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGPoint position = [_delegate getBallPosition];
    
    CGPoint ballPos = CGPointMake(screenSize.height-position.x, position.y);
    
    p0ngPacket packet;
    
    packet.type = state;

    if([UIDevice currentResolution] == UIDevice_iPhoneTallerHiRes)
        packet.ballX = ballPos.x / (1136.0/960.0);
    else
        packet.ballX = ballPos.x;
    
    packet.ballY = ballPos.y;
    
    packet.paddleY = [_delegate getPlayerPosition].y;
    
    packet.stateAndScores = (_state << 16) | (_playerScore << 8) | _opponentScore;
    
    if(_playerTurn)
        packet.hostingFlags |= kP0ngPacketPlayerTurn;
    if([A3PongSettings sharedInstance].playerOnLeft)
        packet.hostingFlags |= kP0ngPacketPlayerOnLeft;
    
    NSData *data = [NSData dataWithBytes:&packet length:sizeof(p0ngPacket)];
    
    
    if(state != kPacketSend)
        [[A3GameCenter sharedInstance] sendReliableData:data];
    else
        [[A3GameCenter sharedInstance] sendData:data];
    
}

- (void) broadcast: (BOOL) ack {
    
    if(_opponentIsComputer)
        return;
    
    if(_state > kGameStatePaused && (ack /*|| ![A3PongSettings sharedInstance].lagReduction || _interval % 2 == 0*/))
    {
        if(ack)
        {
            if(_syncState == kGameSyncHasToAck)
            {
                NSLog(@"SENDING ACK %ld", _interval);
                _syncState = kGameSyncNone;
                [self sendPacket:kPacketAck];
            }
            else
            {
                NSLog(@"REQUESTING ACK %ld", _interval);
                _syncState = kGameSyncWaitingForAck;
                [self sendPacket:kPacketSendAndAck];
           }
        }
        else {
            NSLog(@"SEND %ld", _interval);
            [self sendPacket:_syncState == kGameSyncWaitingForAck ? kPacketSendAndAck : kPacketSend];
        }
    }
}

- (void) gotPacket:(p0ngPacket *)packet
{
    if(packet->type == kPacketAck)
    {
        if(_syncState == kGameSyncWaitingForAck)
        {
            _syncState = kGameSyncNone;
        }
    }
    else if(packet->type == kPacketSendAndAck)
    {
        if(_syncState == kGameSyncWaitingForAck) {
            NSLog(@"Sending ack %ld", _interval);
            [self sendPacket:kPacketAck];
        } else if(_syncState == kGameSyncNone){
            _syncState = kGameSyncHasToAck;
            NSLog(@"Opponent waiting for ack %ld", _interval);
        }
        return;
    }
    
    if(_syncState == kGameSyncWaitingForAck)
    {
        NSLog(@"Updated state from opponent");
        
        _syncState = kGameSyncNone;
        
        NSLog(@"GOT ACK %ld", _interval);
        
        char opponentScore = packet->stateAndScores & 0xff;
        char playerScore = (packet->stateAndScores >> 8) & 0xff;
        char state = (packet->stateAndScores >> 16) & 0xff;
        
        if(_state != state)
        {
            NSLog(@"State Change: %d", state);
            
            [self setPlayerScore:opponentScore];
            
            [self setOpponentScore:playerScore];
            
            switch(state)
            {
                case kGameCountdown2:
                case kGameCountdown3:
                case kGameCountdown4:
                    [_delegate updateStatus:[NSString stringWithFormat:@"%i", state-1]];
                    break;
                case kGameStateRunning:
                    [_delegate updateStatus:nil];
                    break;
            }
        }
        
        self.state = state;
        
        _playerTurn = (packet->hostingFlags & kP0ngPacketPlayerTurn) == 0;
        
        CGPoint ballLocation;
        
        if( (packet->hostingFlags & kP0ngPacketPlayerOnLeft) && [A3PongSettings sharedInstance].playerOnLeft) {
            ballLocation = CGPointMake(packet->ballX, packet->ballY);
        }
        else{
            ballLocation = CGPointMake([UIScreen mainScreen].bounds.size.height - packet->ballX, packet->ballY);
        }
        
        [_delegate updateGame: self withBall:ballLocation];
        
        if(_state == kGameStateOver)
            [_delegate gameOver:self];
    }
    
    [_delegate updateGame: self withOpponent: packet->paddleY];
    
}
- (void) updateForBall: (UIView *) ball andPaddle: (UIView *) playerPaddle andOpponent: (UIView *) opponentPaddle {
    
    if(_state != kGameStateRunning || _syncState != kGameSyncNone)
        return;
    
    ball.center = CGPointMake(ball.center.x + [self getSpeedX], ball.center.y + [self getSpeedY]);
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    screenSize = CGSizeMake(screenSize.height, screenSize.width);

    if(ball.center.y > screenSize.height - 25 || ball.center.y < 25) {
        _ballVelocity.y = -_ballVelocity.y;
        if([A3PongSettings sharedInstance].playSounds)
            [_sndWall play];
    }
    
    if (CGRectIntersectsRect (ball.frame, playerPaddle.frame)) {
        CGRect frame = ball.frame;
        [self calcSpeedBonus:ball andPaddle:playerPaddle margin:1];
        frame.origin.x = [A3PongSettings sharedInstance].playerOnLeft ? CGRectGetMaxX(playerPaddle.frame) : (playerPaddle.frame.origin.x - frame.size.height);
        ball.frame = frame;
        _ballVelocity.x = -_ballVelocity.x;
        if([A3PongSettings sharedInstance].playSounds)
            [_sndPaddle play];
        [self broadcast:YES];

    }
    
    else if (_opponentIsComputer && CGRectIntersectsRect (ball.frame, opponentPaddle.frame)) {
        CGRect frame = ball.frame;
        if([A3PongSettings sharedInstance].difficulty > kAIEasy)
            [self calcSpeedBonus:ball andPaddle:opponentPaddle margin: 0];
        else
            _speedBonus = CGPointZero;
        
        frame.origin.x = [A3PongSettings sharedInstance].playerOnLeft ? (opponentPaddle.frame.origin.x - frame.size.height) : CGRectGetMaxX(opponentPaddle.frame);
        ball.frame = frame;
        
        _ballVelocity.x = -_ballVelocity.x;
        
        if([A3PongSettings sharedInstance].playSounds)
           [_sndPaddle play];
        
        [self broadcast:YES];
    }
    
    else if(ball.center.x > screenSize.width || ball.center.x < 0) {
        _ballVelocity.x = -_ballVelocity.x;

        //AudioServicesPlaySystemSound(_sndWall);
    }

    // Begin Simple AI
    else if(_opponentIsComputer && ([A3PongSettings sharedInstance].playerOnLeft ? (ball.center.x >= screenSize.width/2) : (ball.center.x <= screenSize.width/2))) {
        
        if(_randomAILag < _interval)
        {
            float speed = [A3PongSettings sharedInstance].difficultyValue;
        
            float percent;
            
            switch([A3PongSettings sharedInstance].difficulty)
            {
                case kAIEasy:
                    percent = arc4random() % 3500;
                    break;
                case kAINormal:
                    percent = arc4random() % 7500;
                    break;
                case kAIHard:
                    percent = 100;
                    break;
            }
            
            if(percent < 20) {
                NSLog(@"Random lag!");
                _randomAILag = _interval + [A3PongSettings sharedInstance].difficulty+1;
            }
            
            if(ball.center.y < opponentPaddle.center.y) {
                CGPoint compLocation = CGPointMake(opponentPaddle.center.x, opponentPaddle.center.y - speed);
                if(compLocation.y - opponentPaddle.frame.size.height/2 > 25 && compLocation.y + opponentPaddle.frame.size.height/2 < screenSize.height-25)
                    opponentPaddle.center = compLocation;
            }
            
            if(ball.center.y > opponentPaddle.center.y) {
                CGPoint compLocation = CGPointMake(opponentPaddle.center.x, opponentPaddle.center.y + speed);
                if(compLocation.y - opponentPaddle.frame.size.height/2 > 25 && compLocation.y + opponentPaddle.frame.size.height/2 < screenSize.height-25)
                    opponentPaddle.center = compLocation;
            }
        }
        
    }
}

- (void) newGame: (BOOL) isComputer {
    
    _opponentScore = 0;
    _playerScore = 0;
    _opponentIsComputer = isComputer;
    
    [self.delegate newGame: self ballPosition:arc4random_uniform(100) < 50 ? [_delegate getPlayerPosition] : [_delegate getOpponentPosition]];
    
    self.state = kGameCountdown1;
    _syncState = kGameSyncNone;
    
    if(!isComputer)
    {
        [self sendPacket: YES];
    }
}

- (void) gameOver: (BOOL) disconnected {
    
    self.state = disconnected ? kGameStateDisconnected : kGameStateOver;

    [self.delegate gameOver:self];
    
    _opponentScore = 0;
    _playerScore = 0;
    
    [[A3GameCenter sharedInstance] disconnect];
    
    _interval = 0;
}


-(void)resetForPlayer:(BOOL) opponent {
    
    self.state = kGameCountdown1;
    _syncState = kGameSyncNone;
    
    _playerTurn = !opponent;
    
    CGPoint ballLocation = (opponent) ? [_delegate getOpponentPosition] : [_delegate getPlayerPosition];
    
    [_delegate updateGame:self withBall:ballLocation];

    if([A3GameCenter sharedInstance].isHosting)
        [self broadcast: YES];

}

- (void) setPlayerScore:(int)value {
    _playerScore = value;
    
    if(_playerScore >= [A3PongSettings sharedInstance].gamePoint) {
        [self gameOver:NO];
    }
}

- (void) setOpponentScore:(int)value {
    _opponentScore = value;
    
    if(_opponentScore >= [A3PongSettings sharedInstance].gamePoint) {
        [self gameOver:NO];
    }
}

- (int) playerScore {
    return _playerScore;
}

- (int) opponentScore {
    return _opponentScore;
}

- (void) updatePlayerScore: (UILabel *) label {
    NSLog(@"Player scored");
    _playerScore++;
    label.text = [NSString stringWithFormat: @"%d", _playerScore];
    
    
    if(_playerScore >= [A3PongSettings sharedInstance].gamePoint) {
        [self gameOver:NO];
    } else {
        [self resetForPlayer:NO];
    }
}

- (void) updateOpponentScore: (UILabel *) label {
    NSLog(@"Opponent scored");
    _opponentScore++;
    label.text = [NSString stringWithFormat: @"%d", _opponentScore];
    if(_opponentScore >= [A3PongSettings sharedInstance].gamePoint) {
        [self gameOver:NO];
    } else {
        [self resetForPlayer:YES];
    }
}

-(void) gameLoop: (NSTimer *) timer {
    
    if(_state > kGameStatePaused && _state != kGameStateOver) {
 
        _interval++;
        
        [self.delegate gameTick:self];
    }
    
}

@end
