//
//  A3PongSettings.m
//  p0ng
//
//  Created by Ryan Jennings on 2013-02-16.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import "A3PongSettings.h"

#define kComputerMoveSpeed 3.5f

int gamePointValues[] = { 5, 10, 15, 20 };

float AIDifficulties[] = { 3.7, 4.3, 5 };

@implementation A3PongSettings

static A3PongSettings *sharedSettings = nil;

+ (A3PongSettings *) sharedInstance {
    if(!sharedSettings) {
        sharedSettings = [[A3PongSettings alloc] init];
    }
    return sharedSettings;
}

- (void) load: (NSUserDefaults *) defaults {
    self.difficulty = [defaults integerForKey:@"p0ngAIDifficulty"];
    
    if(self.difficulty < kAIEasy || self.difficulty > kAIHard )
        self.difficulty = kSpeedNormal;
    
    self.speedIndex = [defaults integerForKey:@"p0ngGameSpeed"];
    
    if(self.speedIndex < kSpeedSlow || self.speedIndex > kSpeedFast)
        self.speedIndex= kSpeedNormal;
    
    self.playerOnLeft = [defaults boolForKey:@"p0ngPlayerOnLeft"];
    
    self.playSounds = ![defaults boolForKey:@"p0ngSoundsOff"];
    
    self.gamePointIndex = [defaults integerForKey:@"p0ngGamePoint"];
    
    if(self.gamePointIndex < kGamePointIndexMin || self.gamePointIndex > kGamePointIndexMax)
        self.gamePointIndex = kGamePointIndexDefault;
    
    self.matchGamePoint = [defaults boolForKey:@"p0ngMatchGamePoint"];
    
    self.matchSpeeds = [defaults boolForKey:@"p0ngMatchSpeed"];
    
    self.lagReduction = [defaults boolForKey:@"p0ngLagReduction"];
}

- (id)init {
    if ((self = [super init])) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
        BOOL initialized = [defaults boolForKey:@"p0nginitialized"];
        
        if(initialized) {
            [self load: defaults];
        }
        else
        {
            self.difficulty = kSpeedNormal;
            self.speedIndex = kSpeedNormal;
            self.gamePointIndex = kGamePointIndexMin;
            self.matchGamePoint = YES;
            self.matchSpeeds = YES;
            self.playSounds = YES;
            self.playerOnLeft = NO;
            
            [self save];
        }
        
    }
    return self;
}

- (float) speed {
    return (kSpeedFast - _speedIndex+1) / 100.0f;
}

- (NSUInteger) speedInterval {
    return (100/(kSpeedFast - _speedIndex+1));
    
}

- (NSUInteger) gamePoint {
    return gamePointValues[_gamePointIndex];
}

- (float) difficultyValue {
    return AIDifficulties[_difficulty];
}

- (void) save
{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger: self.difficulty forKey:@"p0ngAIDifficulty"];
    
    [defaults setInteger: self.speedIndex forKey:@"p0ngGameSpeed"];
    
    [defaults setBool:self.playerOnLeft forKey:@"p0ngPlayerOnLeft"];
    
    [defaults setBool:!self.playSounds forKey:@"p0ngSoundsOff"];
    
    [defaults setInteger:self.gamePointIndex forKey:@"p0ngGamePoint"];
    
    [defaults setBool:self.matchSpeeds forKey:@"p0ngMatchSpeed"];
    
    [defaults setBool:self.matchGamePoint forKey:@"p0ngMatchGamePoint"];
    
    [defaults setBool:self.lagReduction forKey:@"p0ngLagReduction"];
    
    [defaults setBool:TRUE forKey:@"p0nginitialized"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: A3SettingsDidChangeNotificationName object:self];
}

@end
