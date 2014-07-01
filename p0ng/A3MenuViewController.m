//
//  A3MenuControllerViewController.m
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-19.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import "A3MenuViewController.h"
#import "A3GameCenter.h"
#import "A3GameController.h"
#import "A3PongGame.h"
#import "A3AppDelegate.h"
#import "A3OptionsViewController.h"

@interface A3MenuViewController ()

@end

@implementation A3MenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Home";
    
    _lblHeader.font = [UIFont fontWithName:@"kongtext" size:64];
    _btnPlayComputer.titleLabel.font = _btnPlayOnline.titleLabel.font =
        _btnSettings.titleLabel.font = _btnContinue.titleLabel.font = [UIFont fontWithName:@"kongtext" size:20];

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if([A3PongGame sharedInstance].state == kGameStatePaused)
        _btnContinue.hidden = NO;
    else
        _btnContinue.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (BOOL) shouldAutorotate {
    return YES;
}

- (void)playComputer:(id)sender{
    [A3PongGame sharedInstance].state = kGameStateDisconnected;
    
    A3ViewController *viewController = [[A3GameController alloc] initWithNibName:@"A3GameController" bundle:nil];
    
    [self.appDelegate pushViewController:viewController animated:YES];
    
    [[A3PongGame sharedInstance] newGame: YES];
}

- (void) continueGame:(id)sender {
    A3ViewController *viewController = [[A3GameController alloc] initWithNibName:@"A3GameController" bundle:nil];
    
    [self.appDelegate pushViewController:viewController animated:YES];
    
    [A3PongGame sharedInstance].state = kGameCountdown1;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1) {
        [self showSettings: self];
    }
}

- (void)playOnline:(id)sender {
    
    [A3PongGame sharedInstance].state = kGameStateDisconnected;
    
    [[A3GameCenter sharedInstance] authenticateLocalUser: self];
    
}

- (void) matchFound:(A3GameCenter *)gameCenter {
    A3ViewController *viewController = [[A3GameController alloc] initWithNibName:@"A3GameController" bundle:nil];
    
    //[A3AppDelegate loadViewController:viewController];

    [self.appDelegate pushViewController:viewController animated:YES];
}

- (void)showSettings:(id)sender {
    
    A3ViewController *viewController = [[A3OptionsViewController alloc] initWithNibName:@"A3OptionsViewController" bundle:nil];
    
    [self.appDelegate pushViewController:viewController animated:YES];
}

@end
