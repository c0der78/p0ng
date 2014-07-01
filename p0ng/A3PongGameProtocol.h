//
//  A3GameProtocol.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-08.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class A3PongGame;

@protocol A3PongGameProtocol <NSObject>

- (void) newGame: (A3PongGame *) game ballPosition: (CGPoint) position;

- (void) gameOver: (A3PongGame *) game;

- (void) gameTick: (A3PongGame *) game;

- (void) updateGame: (A3PongGame *) game withBall: (CGPoint) ballLocation;

- (void) updateGame:(A3PongGame *)game withOpponent: (float) location;

- (void) updateStatus: (NSString *) status;

- (CGPoint) getPlayerPosition;

- (CGPoint) getOpponentPosition;

- (CGPoint) getBallPosition;

@end
