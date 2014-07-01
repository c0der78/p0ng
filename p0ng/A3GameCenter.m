//
//  A3GameCenter.m
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-19.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import "A3GameCenter.h"
#import "A3AppDelegate.h"
#import "A3PongGame.h"
#import "A3GameController.h"

#import "A3PongSettings.h"

static A3GameCenter *sharedGame = nil;

@implementation A3GameCenter (Private)

- (BOOL) isGameCenterAvailable {
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

@end


@implementation A3GameCenter


+ (A3GameCenter *) sharedInstance {
    if(!sharedGame) {
        sharedGame = [[A3GameCenter alloc] init];
    }
    return sharedGame;
}

- (id)init {
    if ((self = [super init])) {
        _gameCenterAvailable = [self isGameCenterAvailable];
        
        _game = [A3PongGame sharedInstance];
        
        if (_gameCenterAvailable) {
            NSNotificationCenter *nc =
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
        }
        
    }
    return self;
}

- (BOOL) isHosting {
    return _gameCenterAvailable && _isHosting;
}

- (void)authenticationChanged {
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && !_userAuthenticated) {
        NSLog(@"Authentication changed: player authenticated.");
        _userAuthenticated = TRUE;
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && _userAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        _userAuthenticated = FALSE;
    }
    
}

- (void) disconnect {
    if(!_gameCenterAvailable) return;
    
    if(_match == nil) return;
    
    [_match disconnect];
    
}

- (NSUInteger) getPlayerGroup
{
    A3PongSettings *settings = [A3PongSettings sharedInstance];
    
    NSUInteger group = 0;
    
    //if(settings.matchSpeeds)
    switch(settings.speedIndex) {
        case kSpeedFast:
            group |= kP0ngFast;
            break;
        case kSpeedNormal:
            group |= kP0ngNormal;
            break;
        case kSpeedSlow:
            group |= kP0ngSlow;
            break;
    }
    
    //if(settings.matchGamePoint)
    switch(settings.gamePointIndex)
    {
        case kGamePointIndexMin:
            group |= kP0ng5;
            break;
        case kGamePointIndexMin+1:
            group |= kP0ng10;
            break;
        case kGamePointIndexMax-1:
            group |= kP0ng15;
            break;
        case kGamePointIndexMax:
            group |= kP0ng20;
            break;
    }
    
    return group;
}

- (void)findMatchWithViewController:(UIViewController *) viewController {
    
    if (!_gameCenterAvailable) return;
    
    _matchStarted = NO;
    _isHosting = NO;
    self.match = nil;
    self.presentingViewController = viewController;
    [_presentingViewController dismissViewControllerAnimated:NO completion:nil];
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    request.playerGroup = [self getPlayerGroup];
    
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    mmvc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    NSLog(@"Finding match on game center...");
    
    [_presentingViewController presentViewController:mmvc animated:YES completion:nil];
    
}


#pragma mark GKMatchmakerViewControllerDelegate

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Match was cancelled");
    _isHosting = NO;
    _matchStarted = NO;
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"Error finding match: %@", error.localizedDescription);
    _isHosting = NO;
    _matchStarted = NO;
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    _match = theMatch;
    _match.delegate = self;
    if (!_matchStarted && _match.expectedPlayerCount == 0) {
        NSLog(@"Ready to start match2!");
        
        _isHosting = [[GKLocalPlayer localPlayer].playerID compare:_match.playerIDs[0]] == NSOrderedDescending;
        
        NSLog(@"is Hosting? = %@", _isHosting ? @"YES" : @"NO");
        _matchStarted = YES;
        
        [_delegate matchFound:self];
        
        [_game newGame: NO];
    }
    else{
        NSLog(@"Match found, but not ready2");
    }
}


#pragma mark GKMatchDelegate

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    
    if (_match != theMatch) return;
    
    if([playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
        return;
    
    p0ngPacket packet;
    
    [data getBytes:&packet length:sizeof(p0ngPacket)];
    
    [_game gotPacket:&packet];
    
    /*if(packet.type == kPacketSendAndAck)
    {
        packet.type = kPacketAck;
        
        NSLog(@"SEND ACK");
        
        [self sendReliableData:[NSData dataWithBytes:&packet length:sizeof(p0ngPacket)]];
    }*/
}


// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    if (_match != theMatch) return;
    
    switch (state) {
        case GKPlayerStateConnected:
            // handle a new player connection.
            NSLog(@"Player connected!");
            
            if (!_matchStarted && theMatch.expectedPlayerCount == 0) {
                NSLog(@"Ready to start match!");
                
                _isHosting = [[GKLocalPlayer localPlayer].playerID compare:_match.playerIDs[0]] == NSOrderedDescending;
                _matchStarted = YES;
                
                [_delegate matchFound:self];
                    
                [_game newGame: NO];
            } else {
                NSLog(@"Match found, but not ready");
            }
            
            break;
        case GKPlayerStateDisconnected:
            // a player just disconnected.
            NSLog(@"Player disconnected!");
            _matchStarted = NO;
            [_game gameOver: YES];
            break;
    }
}

// The match was unable to connect with the player due to an error.
- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    
    NSLog(@"Failed to connect to player with error: %@", error.localizedDescription);
    
    if (_match != theMatch) return;
    
    _matchStarted = NO;
    [_game gameOver: YES];
}

// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error {
    
    NSLog(@"Match failed with error: %@", error.localizedDescription);
    if (_match != theMatch) return;
    
    _matchStarted = NO;
    
    [_game gameOver:YES];
}


#pragma mark User functions

- (void) sendData: (NSData *) data {
    
    NSError *error = nil;
    
    [_match sendData:data toPlayers:_match.playerIDs withDataMode:GKMatchSendDataUnreliable error:&error];
    
    if(error != nil) {
        NSLog(@"%@", error);
    }
}

- (void) sendReliableData: (NSData *) data {
    NSError *error = nil;
    
    [_match sendData:data toPlayers:_match.playerIDs withDataMode:GKMatchSendDataReliable error:&error];
    
    if(error != nil) {
        NSLog(@"%@", error);
    }
}

- (void)authenticateLocalUser: (id<A3GameCenterProtocol>) delegate {
    
    if (!_gameCenterAvailable) return;
    
    _delegate = delegate;
    
    A3AppDelegate* root = (A3AppDelegate*)[UIApplication sharedApplication].delegate;
    
    if(_userAuthenticated)
    {
        [self findMatchWithViewController:root.window.rootViewController];
         return;
    }
    
    NSString *reqSysVer = @"6.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
    {
        // Gamekit login for ios 6
        [[GKLocalPlayer localPlayer] setAuthenticateHandler:(^(UIViewController* viewcontroller, NSError *error) {
            if (viewcontroller != nil) {
                [root.window.rootViewController presentViewController:viewcontroller animated:YES completion:nil];
            }
            else if ([GKLocalPlayer localPlayer].authenticated)
            {
                _userAuthenticated = TRUE;
                [self findMatchWithViewController:root.window.rootViewController];
            }
        })];
    } else {
        // Gamekit login for ios 5
        [[GKLocalPlayer localPlayer]authenticateWithCompletionHandler:^(NSError *error) {
            A3AppDelegate* root = (A3AppDelegate*)[UIApplication sharedApplication].delegate;
            [self findMatchWithViewController:root.window.rootViewController];
        }];
    }
}


@end
