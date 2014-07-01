//
//  A3PongSettings.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-02-16.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kAIEasy     0
#define kAINormal   1
#define kAIHard     2

#define kSpeedSlow   0
#define kSpeedNormal 1
#define kSpeedFast   2

#define kGamePointIndexMin 0
#define kGamePointIndexMax 3
#define kGamePointIndexDefault 0

#define A3SettingsDidChangeNotificationName @"A3SettingsDidChangeNotifcation"

@interface A3PongSettings : NSObject

@property BOOL playSounds;
@property NSUInteger difficulty;
@property NSUInteger gamePointIndex;
@property NSInteger speedIndex;
@property BOOL matchSpeeds;
@property BOOL matchGamePoint;
@property BOOL playerOnLeft;
@property BOOL lagReduction;

+ (A3PongSettings *) sharedInstance;

- (float) speed;

- (NSUInteger) speedInterval;

- (NSUInteger) gamePoint;

- (float) difficultyValue;

- (void) save;

@end
