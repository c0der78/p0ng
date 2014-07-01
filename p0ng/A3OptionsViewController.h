//
//  A3OptionsViewController.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-20.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "A3ViewController.h"

@interface A3OptionsViewController : A3ViewController

@property IBOutlet UIView *contentView;

@property IBOutlet UIScrollView *scrollView;

@property IBOutlet UILabel* lblMatching;

@property IBOutlet UILabel *lblMatchSpeed;
@property IBOutlet UILabel *lblMatchGamePoint;

@property IBOutlet UILabel* lblAiDifficulty;

@property IBOutlet UILabel *lblSounds;

@property IBOutlet UILabel *lblGamePoint;

@property IBOutlet UISegmentedControl* segAiDifficulty;

@property IBOutlet UINavigationBar *navBar;

@property IBOutlet UINavigationItem *navItem;

@property IBOutlet UISegmentedControl *segBallSpeed;

@property IBOutlet UILabel *lblBallSpeed;

@property IBOutlet UILabel *lblPlayerPosition;

@property IBOutlet UISegmentedControl *segPlayerPosition;

@property IBOutlet UISwitch *switchSounds;

@property IBOutlet UISwitch *matchSpeed;

@property IBOutlet UISwitch *matchGamePoint;

@property IBOutlet UISegmentedControl *segNetwork;

@property IBOutlet UISegmentedControl *segGamePoint;

@end
