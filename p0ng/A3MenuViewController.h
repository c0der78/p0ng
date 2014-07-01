//
//  A3MenuControllerViewController.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-19.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "A3GameCenterProtocol.h"
#import "A3ViewController.h"

@interface A3MenuViewController : A3ViewController<A3GameCenterProtocol, UIAlertViewDelegate>

@property IBOutlet UILabel *lblHeader;
@property IBOutlet UIButton *btnPlayComputer;
@property IBOutlet UIButton *btnPlayOnline;
@property IBOutlet UIButton *btnSettings;
@property IBOutlet UIButton *btnContinue;

- (IBAction)playComputer:(id)sender;
- (IBAction)playOnline:(id)sender;
- (IBAction)showSettings:(id)sender;
- (IBAction)continueGame:(id)sender;

@end
