//
//  GameController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import UIKit

class GameController : BaseController, GameProtocol
{
    
    // MARK: IBOutlets
    @IBOutlet var paddleA: UIImageView?;
    @IBOutlet var paddleB: UIImageView?;
    @IBOutlet var scoreA: UILabel?;
    @IBOutlet var scoreB: UILabel?;
    @IBOutlet var ball: UIImageView?;
    @IBOutlet var lblStatus: InsetLabel?;
    @IBOutlet var btnBack: UIButton?;
    
    // MARK: Internal variables
    var playerPaddle: UIImageView?;
    var opponentPaddle: UIImageView?;
    var playerScore: UILabel?;
    var opponentScore: UILabel?;
    
    // MARK: Initializers
    override init(delegate: AppDelegate?, nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(delegate: delegate, nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder);
    }

    // MARK: Functions
    
    func restore() {
        
        let def = NSUserDefaults.standardUserDefaults();
        
        if(Game.sharedInstance.state == GameState.Paused)
        {
            var defVal = def.stringForKey("p0ngBall");
            
            if (self.ball != nil && defVal != nil) {
                self.ball!.center = CGPointFromString(defVal!);
            }
            defVal = def.stringForKey("p0ngPaddleA");
            
            if (self.paddleA != nil && defVal != nil) {
               self.paddleA!.center = CGPointFromString(defVal!);
            }
            defVal = def.stringForKey("p0ngPaddleB");
            
            if (self.paddleB != nil && defVal != nil) {
                self.paddleB!.center = CGPointFromString(defVal!);
            }
            
            if (self.playerScore != nil) {
                self.playerScore!.text = String(format:"%ld", Game.sharedInstance.playerScore);
            }
            if (self.opponentScore != nil) {
                self.opponentScore!.text = String(format:"%ld", Game.sharedInstance.opponentScore);
            }
        }
        
        def.removeObjectForKey("p0ngBall");
        def.removeObjectForKey("p0ngPaddleA");
        def.removeObjectForKey("p0ngPaddleB");
    }
    
    func save() {
    
        if(Game.sharedInstance.state != GameState.Paused) {
            return;
        }
    
        let def = NSUserDefaults.standardUserDefaults();
    
        if (self.ball != nil) {
            def.setObject(NSStringFromCGPoint(self.ball!.center), forKey:"p0ngBall");
        }
        if (self.paddleA != nil) {
            def.setObject(NSStringFromCGPoint(self.paddleA!.center), forKey:"p0ngPaddleA");
        }
        if (self.paddleB != nil) {
            def.setObject(NSStringFromCGPoint(self.paddleB!.center), forKey:"p0ngPaddleB");
        }
    }
    
    @IBAction func showMenu(sender: AnyObject) {
        
        let game = Game.sharedInstance;
        
        if(!game.opponentIsComputer) {
            game.gameOver(true);
        } else if(game.state != GameState.Over) {
            game.state = GameState.Paused;
        }
        
        self.save();
        
        if (self.appDelegate != nil) {
            self.appDelegate!.popViewControllerAnimated(true);
        }
    }
    
    func newGame(game:Game, ballPosition position: CGPoint) {
        
        if (self.playerScore != nil) {
            self.playerScore!.text = String(format:"%i", game.playerScore);
            self.playerScore!.hidden = false;
        }
        if (self.opponentScore != nil) {
            self.opponentScore!.text = String(format:"%i", game.opponentScore);
            self.opponentScore!.hidden = false;
        }
        
        if (self.ball != nil) {
            self.ball!.center = position;
        }
        
        
        if (self.lblStatus != nil) {
            self.lblStatus!.hidden = true;
        }
        
        let ySpeed = CGFloat((UInt32(arc4random_uniform(50)) >= 25) ? BallSpeed.Y : -BallSpeed.Y);
        
        let xSpeed = CGFloat((self.ball != nil && self.ball!.center.x > self.view.frame.size.width/2) ? -BallSpeed.X : BallSpeed.X);
        
        game.ballVelocity = CGPointMake(xSpeed, ySpeed);
    }
    
    func updateGame(game:Game, withOpponent location: CGFloat) {
        
        if (self.opponentPaddle != nil) {
            self.opponentPaddle!.center = CGPointMake(self.opponentPaddle!.center.x, location);
            
            if(self.ball != nil && game.state.rawValue < GameState.Running.rawValue && !game.playerTurn)
            {
                self.ball!.center = self.opponentPaddle!.center;
            }
        }
        
    }
    
    func updateGame( game: Game, withBall ballLocation: CGPoint)
    {
        if (self.ball != nil) {
            self.ball!.center = ballLocation;
        }
        
        if (self.playerScore != nil) {
            self.playerScore!.text = String(format:"%i", game.playerScore);
        }
        if (self.opponentScore != nil) {
            self.opponentScore!.text = String(format:"%i", game.opponentScore);
        }
    }
    
    func updateStatus(status: String?)
    {
        if (self.lblStatus == nil) {
            return;
        }
        
        if(status == nil) {
            self.lblStatus!.hidden = true;
            return;
        }
        
        self.lblStatus!.hidden = false;
        
        self.lblStatus!.text = status!;
        
        self.lblStatus!.sizeToFit();
        
        self.lblStatus!.center = CGPointMake(self.view.center.x, self.view.center.y);
    }
    
    func gameTick(game: Game)
    {
        if(game.state == GameState.Running)
        {
            if (self.lblStatus != nil) {
                self.lblStatus!.hidden = true;
            }
            
            if(game.syncState != GameSync.None)
            {
                NSLog("SYNC STATE: %d", game.syncState.rawValue);
                return;
            }
            
            game.updateForBall(self.ball!, andPaddle:self.playerPaddle!, andOpponent:self.opponentPaddle!);
            
            // Begin Scoring Game Logic
            if(self.ball != nil && self.ball!.center.x <= 0) {
                if(Settings.sharedInstance.playerOnLeft) {
                    game.updateOpponentScore( self.scoreB!);
                } else {
                    game.updatePlayerScore( self.scoreB! );
                }
            }
            
            if(self.ball != nil && self.ball!.center.x > self.view.bounds.size.width) {
                if(Settings.sharedInstance.playerOnLeft) {
                    game.updatePlayerScore(self.scoreA!);
                } else {
                    game.updateOpponentScore(self.scoreA!);
                }
            }
        }
        else if(game.state.rawValue > GameState.Paused.rawValue && game.state.rawValue < GameState.Running.rawValue) {
            
            if(game.interval % Settings.sharedInstance.speedInterval != 0) {
                return;
            }
            
            if(game.syncState != GameSync.None)
            {
                NSLog("SYNC STATE: %d", game.syncState.rawValue);
                return;
            }
            
            if (game.state != GameState.Countdown4) {
                self.updateStatus(String(format:"%i", game.state.rawValue));
            }
            
            game.state = GameState(rawValue: game.state.rawValue+1)!;
            
            game.broadcast(true);
            
        }
        
    }
    
    func gameOver(game: Game) {
        
        if(game.state == GameState.Disconnected) {
            self.updateStatus("Disconnected");
        }
        else if(game.playerScore <= game.opponentScore) {
            self.updateStatus("Game Over!");
        } else {
            self.updateStatus("You Win!");
        }
        
    }
    
    // MARK: Overrides
    override func viewDidLoad()
    {
        super.viewDidLoad();
    
        Game.sharedInstance.delegate = self;
    
        var font = UIFont(name:"kongtext", size:24);
        
        if(font != nil) {
            if (self.scoreA != nil) {
                self.scoreA!.font = font!;
            }
            if (self.scoreB != nil) {
                self.scoreB!.font = font!;
            }
        }
        
        font = UIFont(name:"kongtext", size:30);
        
        if(font != nil && self.lblStatus != nil) {
            self.lblStatus!.font = font!;
        }
        
        font = UIFont(name: "kongtext", size:16);
        
        if (font != nil && self.btnBack != nil && self.btnBack!.titleLabel != nil) {
            self.btnBack!.titleLabel!.font = font!;
        }
        
        if(Settings.sharedInstance.playerOnLeft) {
            if (self.paddleA != nil) {
                self.playerPaddle = self.paddleA!;
            }
            if (self.paddleB != nil) {
                self.opponentPaddle = self.paddleB!;
            }
            if (self.scoreA != nil) {
                self.playerScore = self.scoreA!;
            }
            if (self.scoreB != nil) {
                self.opponentScore = self.scoreB!;
            }
        } else {
            if (self.paddleB != nil) {
                self.playerPaddle = self.paddleB!;
            }
            if (self.paddleA != nil) {
                self.opponentPaddle = self.paddleA!;
            }
            if (self.scoreB != nil) {
                self.playerScore = self.scoreB!;
            }
            if (self.scoreA != nil) {
                self.opponentScore = self.scoreA!;
            }
        }
        
        if (self.opponentPaddle != nil) {
            self.opponentPaddle!.image = UIImage(named: "opponent_paddle.png");
        }
        self.restore();
        
        if (self.lblStatus != nil) {
            self.lblStatus!.backgroundColor = UIColor.grayColor();
            self.lblStatus!.layer.cornerRadius = 10;
            self.lblStatus!.layer.borderColor = UIColor.whiteColor().CGColor;
            self.lblStatus!.layer.borderWidth = 2;
            self.lblStatus!.topInset = 10;
            self.lblStatus!.bottomInset = 10;
            self.lblStatus!.rightInset = 15;
            self.lblStatus!.leftInset = 15;
            self.lblStatus!.hidden = true;
        }
        
    
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
    
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation:UIStatusBarAnimation.Fade);
    }
    
    override func shouldAutorotate() -> Bool {
        return true;
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
    
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation:UIStatusBarAnimation.Fade);
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape;
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.LandscapeRight;
    }
    
   override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        self.touchesMoved(touches, withEvent:event);
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        if (touches.first == nil) {
            return;
        }
        let touch = touches.first!;

        let location = touch.locationInView(touch.view);
        
        let isInPlayerZone = Settings.sharedInstance.playerOnLeft ? (location.x < 25) : (location.x > 400);
        
        if (isInPlayerZone && self.playerPaddle != nil) {
            let yLocation: CGPoint = CGPointMake(self.playerPaddle!.center.x, location.y);
        
            if(yLocation.y - (self.playerPaddle!.frame.size.height/2) > 25 &&
                yLocation.y + (self.playerPaddle!.frame.size.height/2)
                < UIScreen.mainScreen().bounds.size.width-25)
            {
                let game = Game.sharedInstance;
                
                if(self.ball != nil && CGRectContainsPoint(self.playerPaddle!.frame, self.ball!.center)
                && game.state != GameState.Running)
                {
                    self.ball!.center = yLocation;
                }
                
                self.playerPaddle!.center = yLocation;
                
                game.broadcast(false);
            }
        }
    }
    
    // MARK: Dynamic properties
    
    var playerPosition: CGPoint {
        get {
            if (self.playerPaddle == nil) {
                return CGPointZero;
            }
            return self.playerPaddle!.center;
        }
    }
    
    var opponentPosition: CGPoint {
         get {
            if (self.opponentPaddle == nil) {
                return CGPointZero;
            }
            return self.opponentPaddle!.center;
        }
    }
    
    var ballPosition: CGPoint {
         get {
            if (self.ball == nil) {
                return CGPointZero;
            }
            return self.ball!.center;
        }
    }
    

}
