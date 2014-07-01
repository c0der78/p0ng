//
//  A3OptionsViewController.m
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-20.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import "A3OptionsViewController.h"
#import "A3PongSettings.h"
#import "A3PongGame.h"

@interface A3OptionsViewController ()

@end

@implementation A3OptionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) goBack: (id) selected {
    [self.appDelegate popViewControllerAnimated:YES];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    A3PongSettings *settings = [A3PongSettings sharedInstance];
    
    settings.difficulty = _segAiDifficulty.selectedSegmentIndex;
    
    settings.speedIndex = _segBallSpeed.selectedSegmentIndex;

    settings.playSounds = _switchSounds.on;
    
    settings.gamePointIndex = _segGamePoint.selectedSegmentIndex;
    
    BOOL left = (_segPlayerPosition.selectedSegmentIndex == 0);
    
    if(left != settings.playerOnLeft)
        [[A3PongGame sharedInstance] gameOver: YES];
       
    settings.playerOnLeft = left;
    
    settings.matchGamePoint = _matchGamePoint.on;
    
    settings.matchSpeeds = _matchSpeed.on;
    
    settings.lagReduction = _segNetwork.selectedSegmentIndex == 0;
    
    [settings save];
    
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}
- (BOOL) shouldAutorotate {
    return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    self.title = @"Options";
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"kongtext" size:20.0];
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor =[UIColor whiteColor];
    label.text=self.title;
    self.navItem.titleView = label;
    [self.navItem.titleView sizeToFit];
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"leftarrow.white.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
    
    self.navItem.leftBarButtonItem = backItem;
    
    //_lblAiDifficulty.font = _lblBallSpeed.font = _lblPlayerPosition.font = _lblSounds.font = _lblGamePoint.font = [UIFont fontWithName:@"kongtext" size:20];
    
    _segAiDifficulty.selectedSegmentIndex = [A3PongSettings sharedInstance].difficulty;
    
    _segBallSpeed.selectedSegmentIndex = [A3PongSettings sharedInstance].speedIndex;
    
    _segPlayerPosition.selectedSegmentIndex = [A3PongSettings sharedInstance].playerOnLeft ? 0 : 1;
    
    _segGamePoint.selectedSegmentIndex = [A3PongSettings sharedInstance].gamePointIndex;
    
    _segNetwork.selectedSegmentIndex = [A3PongSettings sharedInstance].lagReduction ? 0 : 1;
    
    _matchGamePoint.on = [A3PongSettings sharedInstance].matchGamePoint;
    
    _matchSpeed.on = [A3PongSettings sharedInstance].matchSpeeds;
    
    _switchSounds.on = [A3PongSettings sharedInstance].playSounds;
    
    self.scrollView.contentSize = self.contentView.bounds.size;
    [self.scrollView addSubview:self.contentView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
