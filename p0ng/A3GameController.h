//
//  A3ViewController.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-08.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "A3PongGame.h"
#import "A3Label.h"
#import "A3ViewController.h"

@interface A3GameController : A3ViewController<A3PongGameProtocol>
{
    
    IBOutlet UIImageView *_paddleA;
    IBOutlet UIImageView *_paddleB;
    IBOutlet UILabel *_scoreA;
    IBOutlet UILabel *_scoreB;
}
@property UIImageView *playerPaddle;
@property UIImageView *opponentPaddle;
@property IBOutlet UIImageView *ball;
@property UILabel *playerScore;
@property UILabel *opponentScore;
@property IBOutlet A3Label *lblStatus;
@property IBOutlet UIButton *btnBack;

- (IBAction)showMenu:(id)sender;

//@property CGPoint ballVelocity;
//@property NSInteger gameState;

//@property NSInteger playerScoreValue;
//@property NSInteger opponentScoreValue;

//- (void) gameLoop;

@end
