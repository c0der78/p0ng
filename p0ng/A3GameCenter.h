//
//  A3GameCenter.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-19.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#import "A3GameCenterProtocol.h"

@class A3PongGame;

@interface A3GameCenter : NSObject<GKMatchmakerViewControllerDelegate, GKMatchDelegate>
{
    BOOL _userAuthenticated;
    BOOL _matchStarted;
    A3PongGame *_game;
    BOOL _isHosting;
    id<A3GameCenterProtocol> _delegate;
}

+ (A3GameCenter *) sharedInstance;

@property UIViewController *presentingViewController;
@property GKMatch *match;
@property BOOL gameCenterAvailable;

- (BOOL) isHosting;

- (void) disconnect;

- (void)findMatchWithViewController:(UIViewController *)viewController;

- (void)authenticateLocalUser: (id<A3GameCenterProtocol>) delegate;

- (void) sendData: (NSData*) data;
- (void) sendReliableData: (NSData*) data;

@end
