//
//  A3PongGame.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-08.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "A3PongGameProtocol.h"
#import <AVFoundation/AVFoundation.h>

#define kGameStateDisconnected -1
#define kGameStatePaused  0
#define kGameCountdown1   1
#define kGameCountdown2   2
#define kGameCountdown3   3
#define kGameCountdown4   4
#define kGameStateRunning 5
#define kGameStateOver    6

#define kBallSpeedX 3
#define kBallSpeedY 4

//#define kPacketInit 0
#define kPacketSend 1
#define kPacketAck  2
#define kPacketSendAndAck 3

#define kP0ngFast   (1 << 0)
#define kP0ngNormal (1 << 1)
#define kP0ngSlow   (1 << 2)
#define kP0ng5      (1 << 3)
#define kP0ng10     (1 << 4)
#define kP0ng15     (1 << 5)
#define kP0ng20     (1 << 6)

#define kP0ngPacketPlayerTurn (1 << 0)
#define kP0ngPacketPlayerOnLeft (1 << 1)

#define kGameSyncNone 0
#define kGameSyncWaitingForAck 1
#define kGameSyncHasToAck 2

typedef struct
{
    char type;
    float ballX;
    float ballY;
    float paddleY;
    unsigned stateAndScores;
    char hostingFlags;
} p0ngPacket;


@class A3GameCenter;

@interface A3PongGame : NSObject
{
    int _playerScore;
    int _opponentScore;
    float _randomAILag;
    NSTimer *_timer;
    CGFloat _scale;
    AVAudioPlayer* _sndWall;
    AVAudioPlayer* _sndPaddle;
    CGPoint _speedBonus;
    
}
@property BOOL opponentIsComputer;

@property CGPoint ballVelocity;
@property int state;
@property unsigned long interval;
@property BOOL playerTurn;
@property id<A3PongGameProtocol> delegate;
@property int syncState;

+ (A3PongGame *) sharedInstance;

- (void) setPlayerScore: (int) value;
- (void) setOpponentScore: (int) value;
- (void) broadcast: (BOOL) ack;
- (int) playerScore;
- (int) opponentScore;
- (void) updatePlayerScore: (UILabel *)label;
- (void) updateOpponentScore: (UILabel *)label;
- (void) updateForBall: (UIView *) ball andPaddle: (UIView *) playerPaddle andOpponent: (UIView *) opponentPaddle;
- (void) newGame: (BOOL) isComputer;
- (void) gameOver: (BOOL) disconnected;
- (void) resetForPlayer: (BOOL) opponent;
- (void) gotPacket: (p0ngPacket *) packet;
- (void) sendPacket: (NSInteger) state;

@end
