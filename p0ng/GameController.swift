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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
    }

    // MARK: Functions
    
    func restore() {
        
        let def = NSUserDefaults.standardUserDefaults();
        
        // this only matters if we're coming from a Paused state
        if(Game.sharedInstance.state == GameState.Paused)
        {
            // parse the defaults into the values
            
            var defVal:String? = def.stringForKey("p0ngBall");
            
            if (defVal != nil) {
                self.ball?.center = CGPointFromString(defVal!);
            }
            defVal = def.stringForKey("p0ngPaddleA");
            
            if (defVal != nil) {
                self.paddleA?.center = CGPointFromString(defVal!);
            }
            
            defVal = def.stringForKey("p0ngPaddleB");
            
            if (defVal != nil) {
                self.paddleB?.center = CGPointFromString(defVal!);
            }
            
            self.playerScore?.text = String(format:"%ld", Game.sharedInstance.playerScore);
            
            self.opponentScore?.text = String(format:"%ld", Game.sharedInstance.opponentScore);
            
        }
        
        // cleanup the defaults
        def.removeObjectForKey("p0ngBall");
        def.removeObjectForKey("p0ngPaddleA");
        def.removeObjectForKey("p0ngPaddleB");
    }
    
    func save() {
        
        // if we're not paused this shouldn't run
        if(Game.sharedInstance.state != GameState.Paused) {
            return;
        }
    
        let def = NSUserDefaults.standardUserDefaults();
    
        // set the defaults
        
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
    
    //! returns to the menu screen
    @IBAction func showMenu(sender: AnyObject) {
        
        let game = Game.sharedInstance;
        
        // if this is a networked game, returning to the menu will end the game
        if(!game.opponentIsComputer) {
            game.gameOver(true);
        }
        // otherwise we can pause the state
        else if(game.state != GameState.Over) {
            game.state = GameState.Paused;
        }
        
        self.save();
        
        // pop the view
        self.appDelegate?.popViewControllerAnimated(true);
        
    }
    
    //! starts a new game
    func newGame(game:Game, ballPosition position: CGPoint) {
        
        // set the score values
        self.playerScore?.text = String(format:"%i", game.playerScore);
        self.playerScore?.hidden = false;
        
        self.opponentScore?.text = String(format:"%i", game.opponentScore);
        self.opponentScore?.hidden = false;
        
        // set the ball position
        self.ball?.center = position;
        
        self.lblStatus?.hidden = true;
        
        // make some ball velocity
        let ySpeed = CGFloat((UInt32(arc4random_uniform(50)) >= 25) ? BallSpeed.Y : -BallSpeed.Y);
        
        let xSpeed = CGFloat((self.ball?.center.x > self.view.frame.size.width/2) ? -BallSpeed.X : BallSpeed.X);
        
        game.ballVelocity = CGPointMake(xSpeed, ySpeed);
    }
    
    //! update the game for an opponent
    func setOpponentPaddle(game:Game, withYLocation location: CGFloat) {
        if (self.opponentPaddle == nil) {
            return;
        }
        
        self.opponentPaddle!.center = CGPointMake(self.opponentPaddle!.center.x, location);
        
        // if the game isn't running, and its not the players turn, set the ball location as well
        if(game.state.rawValue < GameState.Running.rawValue && !game.playerTurn)
        {
            self.ball?.center = self.opponentPaddle!.center;
        }
    
    }
    
    //! sets the ball location and scores
    func updateGame( game: Game, withBall ballLocation: CGPoint)
    {
        self.ball?.center = ballLocation;
        
        self.playerScore?.text = String(format:"%i", game.playerScore);
        
        self.opponentScore?.text = String(format:"%i", game.opponentScore);
    }
    
    //! updates the status label
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
    
    //! a tick in the game loop
    func gameTick(game: Game)
    {
        if(game.state == GameState.Running)
        {
            // we're running so hide the status label
            self.lblStatus?.hidden = true;
            
            // if we're waiting for a network sync, just return
            if(game.syncState == GameSync.WaitingForAck)
            {
                NSLog("TICK SYNC WAIT: %@", game.state.description);
                return;
            }
            
            // now apply the game logic
            game.update(self.ball!, playerPaddle:self.playerPaddle!, opponentPaddle:self.opponentPaddle!);
            
            // do the scoring
            if(self.ball?.center.x <= 0 && self.scoreB != nil) {
                if(Settings.sharedInstance.playerOnLeft) {
                    game.updateOpponentScore( self.scoreB! );
                } else {
                    game.updatePlayerScore( self.scoreB! );
                }
            }
            
            if(self.ball?.center.x > self.view.bounds.size.width && self.scoreA != nil) {
                if(Settings.sharedInstance.playerOnLeft) {
                    game.updatePlayerScore(self.scoreA!);
                } else {
                    game.updateOpponentScore(self.scoreA!);
                }
            }
        }
        // if we're in a countdown
        else if(game.state.rawValue > GameState.Paused.rawValue && game.state.rawValue < GameState.Running.rawValue) {
            
            // if we haven't hit an interval...
            if(game.interval % Settings.sharedInstance.speedInterval != 0) {
                return;
            }
            
            // if we're waiting for a network sync
            if(game.syncState == GameSync.WaitingForAck/* && game.syncState != GameSync.HasToAck*/)
            {
                NSLog("TICK SYNC WAIT: %@", game.state.description);
                return;
            }
            
            // set the status label to the current countdown
            self.updateStatus(String(format:"%i", game.state.rawValue));
            
            game.state = GameState(rawValue: game.state.rawValue+1)!;
            
            game.broadcast(PacketType.State);
            
        }
        
    }
    
    //! handle a game over
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
            self.scoreA?.font = font!;
            self.scoreB?.font = font!;
        }
        
        font = UIFont(name:"kongtext", size:30);
        
        if(font != nil) {
            self.lblStatus?.font = font!;
        }
        
        font = UIFont(name: "kongtext", size:16);
        
        if (font != nil) {
            self.btnBack?.titleLabel?.font = font!;
        }
        
        if(Settings.sharedInstance.playerOnLeft) {
            self.playerPaddle = self.paddleA;
            self.opponentPaddle = self.paddleB;
            self.playerScore = self.scoreA;
            self.opponentScore = self.scoreB;
            
        } else {
            self.playerPaddle = self.paddleB;
            self.opponentPaddle = self.paddleA;
            self.playerScore = self.scoreB;
            self.opponentScore = self.scoreA;
        }
        
        self.opponentPaddle?.image = UIImage(named: "opponent_paddle.png");
        
        self.restore();
        
        if let status = self.lblStatus {
            status.backgroundColor = UIColor.grayColor();
            status.layer.cornerRadius = 10;
            status.layer.borderColor = UIColor.whiteColor().CGColor;
            status.layer.borderWidth = 2;
            status.topInset = 10;
            status.bottomInset = 10;
            status.rightInset = 15;
            status.leftInset = 15;
            status.hidden = true;
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
                
                // let network player know the paddle has moved
                game.broadcast(PacketType.PaddleMove);
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        super.touchesEnded(touches, withEvent: event);
        
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
                
                // let network player know the paddle final state
                game.broadcast(PacketType.Paddle);
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
