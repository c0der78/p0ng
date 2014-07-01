//
//  A3ViewController.m
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-08.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "A3GameController.h"
#import "A3ViewController.h"
#import "A3MenuViewController.h"
#import "A3GameCenter.h"
#import "A3PongSettings.h"

@interface A3GameController ()

@end

@implementation A3GameController

- (void) restore {
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    if([A3PongGame sharedInstance].state == kGameStatePaused)
    {
        _ball.center = CGPointFromString([def stringForKey:@"p0ngBall"]);
        _paddleA.center = CGPointFromString([def stringForKey:@"p0ngPaddleA"]);
        _paddleB.center = CGPointFromString([def stringForKey:@"p0ngPaddleB"]);
    
        
        _playerScore.text = [NSString stringWithFormat:@"%ld", (long)[A3PongGame sharedInstance].playerScore];
        
        _opponentScore.text = [NSString stringWithFormat:@"%ld", (long)[A3PongGame sharedInstance].opponentScore];
    }
    
    [def removeObjectForKey:@"p0ngBall"];
    [def removeObjectForKey:@"p0ngPaddleA"];
    [def removeObjectForKey:@"p0ngPaddleB"];
}

- (void) save {
    
    if([A3PongGame sharedInstance].state != kGameStatePaused)
        return;
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    [def setObject:NSStringFromCGPoint(_ball.center) forKey:@"p0ngBall"];
    [def setObject:NSStringFromCGPoint(_paddleA.center) forKey:@"p0ngPaddleA"];
    [def setObject:NSStringFromCGPoint(_paddleB.center) forKey:@"p0ngPaddleB"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [A3PongGame sharedInstance].delegate = self;
     
    _scoreA.font = _scoreB.font = [UIFont fontWithName:@"kongtext" size:24];
    
    _lblStatus.font = [UIFont fontWithName:@"kongtext" size:30];
    
    _btnBack.titleLabel.font = [UIFont fontWithName:@"kongtext" size:16];
    
    if([A3PongSettings sharedInstance].playerOnLeft) {
        _playerPaddle = _paddleA;
        _opponentPaddle = _paddleB;
        _playerScore = _scoreA;
        _opponentScore = _scoreB;
    } else {
        _playerPaddle = _paddleB;
        _opponentPaddle = _paddleA;
        _playerScore = _scoreB;
        _opponentScore = _scoreA;
    }
    
    _opponentPaddle.image = [UIImage imageNamed:@"opponent_paddle.png"];
    
    [self restore];
    
    _lblStatus.backgroundColor = [UIColor grayColor];
    _lblStatus.layer.cornerRadius = 10;
    _lblStatus.layer.borderColor = [UIColor whiteColor].CGColor;
    _lblStatus.layer.borderWidth = 2;
    _lblStatus.topInset = 10;
    _lblStatus.bottomInset = 10;
    _lblStatus.rightInset = 15;
    _lblStatus.leftInset = 15;
    
    _lblStatus.hidden = YES;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (BOOL) shouldAutorotate {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated  {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (void)showMenu:(id)sender {
    
    if(![A3PongGame sharedInstance].opponentIsComputer)
        [[A3PongGame sharedInstance] gameOver:YES];
    else if([A3PongGame sharedInstance].state != kGameStateOver)
        [A3PongGame sharedInstance].state = kGameStatePaused;
    
    [self save];
    
    [self.appDelegate popViewControllerAnimated:YES];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    
    if ([A3PongSettings sharedInstance].playerOnLeft ? (location.x < 25) : (location.x > 400)) {
        CGPoint yLocation = CGPointMake(_playerPaddle.center.x, location.y);
        
        if(yLocation.y - (_playerPaddle.frame.size.height/2) > 25 && yLocation.y + (_playerPaddle.frame.size.height/2)
                < [UIScreen mainScreen].bounds.size.width-25)
        {
            if(CGRectContainsPoint(_playerPaddle.frame, _ball.center)
               && [A3PongGame sharedInstance].state != kGameStateRunning)
            {
                _ball.center = yLocation;
            }
        
            _playerPaddle.center = yLocation;
            
            [[A3PongGame sharedInstance] broadcast:NO];
        }
        
    }
}

- (void) newGame:(A3PongGame *)game ballPosition: (CGPoint) position {
    
    _playerScore.text = [NSString stringWithFormat:@"%i", game.playerScore];
    _opponentScore.text = [NSString stringWithFormat:@"%i", game.opponentScore];
    
    _ball.center = position;
    
    _playerScore.hidden = NO;
    _opponentScore.hidden = NO;
    
    _lblStatus.hidden = YES;
    
    int ySpeed = (arc4random_uniform(50) >= 25) ? kBallSpeedY : -kBallSpeedY;
    
    game.ballVelocity = CGPointMake(_ball.center.x > self.view.frame.size.width/2 ? -kBallSpeedX : kBallSpeedX, ySpeed);
    
    
}

- (void) updateGame:(A3PongGame *)game withOpponent:(float)location {
    
    _opponentPaddle.center = CGPointMake(_opponentPaddle.center.x, location);
    
    if(game.state < kGameStateRunning && !game.playerTurn)
    {
        _ball.center = _opponentPaddle.center;
    }
    
}

- (void) updateGame: (A3PongGame*) game withBall:(CGPoint)ballLocation
{
    _ball.center = ballLocation;

    _playerScore.text = [NSString stringWithFormat:@"%i", game.playerScore];
    
    _opponentScore.text = [NSString stringWithFormat:@"%i", game.opponentScore];
}

- (void) updateStatus: (NSString*) status
{
    if(status == nil) {
        _lblStatus.hidden = YES;
        return;
    }
    
    _lblStatus.hidden = NO;

    _lblStatus.text = status;
    
    [_lblStatus sizeToFit];
    
    _lblStatus.center = CGPointMake(self.view.center.y, self.view.center.x);
}

- (void) gameTick:(A3PongGame *)game
{

    if(game.state == kGameStateRunning)
    {
        _lblStatus.hidden = YES;

        if(game.syncState != kGameSyncNone)
        {
            NSLog(@"SYNC STATE: %d", game.syncState);
            return;
        }
        
        [game updateForBall:_ball andPaddle:_playerPaddle andOpponent:_opponentPaddle];
        
        // Begin Scoring Game Logic
        if(_ball.center.x <= 0) {
            if([A3PongSettings sharedInstance].playerOnLeft)
                [game updateOpponentScore:_scoreB];
            else
                [game updatePlayerScore: _scoreB];
        }
        
        if(_ball.center.x > self.view.bounds.size.width) {
            if([A3PongSettings sharedInstance].playerOnLeft)
                [game updatePlayerScore:_scoreA];
            else
                [game updateOpponentScore: _scoreA];
        }
    }
    else if(game.state > kGameStatePaused && game.state < kGameStateRunning) {
        
        if(game.interval % [A3PongSettings sharedInstance].speedInterval != 0) return;
        
        if(game.syncState != kGameSyncNone)
        {
            NSLog(@"SYNC STATE: %d", game.syncState);
            return;
        }
        
        [self updateStatus: [NSString stringWithFormat:@"%i", game.state]];
        
        game.state++;
        
        [game broadcast: YES];
    
    }

}

- (CGPoint) getPlayerPosition {
    return _playerPaddle.center;
}

- (CGPoint) getOpponentPosition {
    return _opponentPaddle.center;
}

- (CGPoint) getBallPosition {
    return _ball.center;
}

- (void) gameOver:(A3PongGame *)game {
    
    
    if(game.state == kGameStateDisconnected) {
        [self updateStatus: @"Disconnected"];
    }
    else if(game.playerScore <= game.opponentScore) {
        [self updateStatus:@"Game Over!"];
    } else {
        [self updateStatus:@"You Win!"];
    }

}

@end
