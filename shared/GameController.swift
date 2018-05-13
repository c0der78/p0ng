//
//  GameController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import UIKit

class GameController : BaseController, GameViewDelegate, MultiplayerDelegate
{
    
    // MARK: IBOutlets
    @IBOutlet var paddleA: UIImageView?
    @IBOutlet var paddleB: UIImageView?
    @IBOutlet var scoreA: UILabel?
    @IBOutlet var scoreB: UILabel?
    @IBOutlet var ball: UIImageView?
    @IBOutlet var lblStatus: InsetLabel?
    @IBOutlet var btnBack: UIButton?
    
    // MARK: Internal variables
    var playerPaddle: UIImageView?
    var opponentPaddle: UIImageView?
    var playerScore: UILabel?
    var opponentScore: UILabel?
    
    // MARK: Initializers
    override init(delegate: BaseAppDelegate?, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(delegate: delegate, nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: Functions
    
    func restore() {
        
        let def = UserDefaults.standard
        
        // this only matters if we're coming from a Paused state
        // TODO: put in a method
        if(Game.shared.state == GameState.Paused)
        {
            // parse the defaults into the values
            var defVal:String? = def.string(forKey:"p0ngBall")
            
            if defVal != nil {
                self.ball?.center = CGPointFromString(defVal!)
            }
            
            defVal = def.string(forKey:"p0ngPaddleA")
            
            if defVal != nil {
                self.paddleA?.center = CGPointFromString(defVal!)
            }
            
            defVal = def.string(forKey:"p0ngPaddleB")
            
            if defVal != nil {
                self.paddleB?.center = CGPointFromString(defVal!)
            }
            
            self.playerScore?.text = String(format:"%ld", Game.shared.playerScore)

            self.opponentScore?.text = String(format:"%ld", Game.shared.opponentScore)
        }
        
        // cleanup the defaults
        def.removeObject(forKey: "p0ngBall")
        def.removeObject(forKey: "p0ngPaddleA")
        def.removeObject(forKey: "p0ngPaddleB")
    }
    
    func save() {
        
        // if we're not paused this shouldn't run
        if Game.shared.state != GameState.Paused {
            return
        }
    
        let def = UserDefaults.standard
    
        // set the defaults
        
        if let ball = self.ball {
            def.set(NSStringFromCGPoint(ball.center), forKey:"p0ngBall")
        }
        
        if let paddle = self.paddleA {
            def.set(NSStringFromCGPoint(paddle.center), forKey:"p0ngPaddleA")
        }
        
        if let paddle = self.paddleB {
            def.set(NSStringFromCGPoint(paddle.center), forKey:"p0ngPaddleB")
        }
    }
    
    //! returns to the menu screen
    @IBAction func showMenu(sender: AnyObject) {
        
        let game = Game.shared
        
        // if this is a networked game, returning to the menu will end the game
        if !game.opponentIsComputer {
            game.gameOver(disconnected: true)
        }
            
        // otherwise we can pause the state
        else if game.state != GameState.Over {
            game.state = GameState.Paused
        }
        
        self.save()
        
        // pop the view
        self.appDelegate?.popViewControllerAnimated(animated: true)
    }
    
    //! starts a new game
    func newGame(_ game:Game, ballPosition position: CGPoint) {
        
        // set the score values
        self.playerScore?.text = String(format:"%i", game.playerScore)
        self.playerScore?.isHidden = false
        
        self.opponentScore?.text = String(format:"%i", game.opponentScore)
        self.opponentScore?.isHidden = false
        
        self.lblStatus?.isHidden = true
        
        if let ball = self.ball {
            // set the ball position
            ball.center = position
            
            // make some ball velocity
            let ySpeed = CGFloat((UInt32(arc4random_uniform(50)) >= 25) ? BallSpeed.Y : -BallSpeed.Y)
            
            let xSpeed = CGFloat((self.ball!.center.x > self.view.frame.size.width/2) ? -BallSpeed.X : BallSpeed.X)
        
            game.ballVelocity = CGPoint(x: xSpeed, y: ySpeed)
        }
    }
    
    //! update the game for an opponent
    func setOpponentPaddle(_ game:Game, withYLocation location: CGFloat) {
        if self.opponentPaddle == nil {
            return
        }
        
        let paddle = self.opponentPaddle!
        
        paddle.center = CGPoint(x: paddle.center.x, y: location)
        
        // if the game isn't running, and its not the players turn, set the ball location as well
        if game.state.rawValue < GameState.Running.rawValue && !game.playerTurn {
            self.ball?.center = paddle.center
        }
    }
    
    //! sets the ball location and scores
    func updateGame( _ game: Game, withBall ballLocation: CGPoint) {
        self.ball?.center = ballLocation
        
        self.playerScore?.text = String(format:"%i", game.playerScore)
        
        self.opponentScore?.text = String(format:"%i", game.opponentScore)
    }
    
    //! updates the status label
    func updateStatus(_ status: String?) {
        if(status == nil) {
            self.lblStatus?.isHidden = true
            return
        }
        
        self.lblStatus?.isHidden = false
        
        self.lblStatus?.text = status!
        
        self.lblStatus?.sizeToFit()
        
        self.lblStatus?.center = CGPoint(x: self.view.center.x, y: self.view.center.y)
    }
    
    private func gameTickRunning(game: Game) {
        // we're running so hide the status label
        self.lblStatus?.isHidden = true
        
        // if we're waiting for a network sync, just return
        if game.syncState == GameSync.WaitingForAck {
            print("TICK SYNC WAIT: \(game.state.description)")
            return
        }
        
        guard let ball = self.ball else {
            return
        }
    
        // now apply the game logic
        game.update(ball: ball, playerPaddle:self.playerPaddle!, opponentPaddle:self.opponentPaddle!)
        
        // do the scoring
        if ball.center.x <= 0 && self.scoreB != nil {
            if Settings.sharedInstance.playerOnLeft {
                game.updateOpponentScore( label: self.scoreB! )
            } else {
                game.updatePlayerScore( label: self.scoreB! )
            }
        }
        
        if ball.center.x > self.view.bounds.size.width && self.scoreA != nil {
            if Settings.sharedInstance.playerOnLeft {
                game.updatePlayerScore(label: self.scoreA!)
            } else {
                game.updateOpponentScore(label: self.scoreA!)
            }
        }
    }
    
    //! a tick in the game loop
    func gameTick(_ game: Game) {
        if game.state == GameState.Running {
            gameTickRunning(game: game)
            return
        }
            
        // if we're in a countdown
        if game.state.rawValue <= GameState.Paused.rawValue || game.state.rawValue >= GameState.Running.rawValue {
            return
        }
    
        // if we haven't hit an interval...
        if game.interval.truncatingRemainder(dividingBy: Settings.sharedInstance.speedInterval) != 0 {
            return
        }
        
        // if we're waiting for a network sync
        if game.syncState == GameSync.WaitingForAck {
            print("TICK SYNC WAIT: \(game.state.description)")
            return
        }
        
        // set the status label to the current countdown
        self.updateStatus(String(format:"%i", game.state.rawValue))
        
        game.state = GameState(rawValue: game.state.rawValue+1) ?? GameState.Disconnected
        
        game.broadcast(type: PacketType.State)
    }
    
    //! handle a game over
    func gameOver(_ game: Game) {
        
        if game.state == GameState.Disconnected {
            self.updateStatus("Disconnected")
        } else if game.playerScore <= game.opponentScore {
            self.updateStatus("Game Over!")
        } else {
            self.updateStatus("You Win!")
        }
    }
    
    // MARK: Overrides
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Game.shared.start(self)
    
        var font = UIFont(name:"kongtext", size:24)
        
        if font != nil {
            self.scoreA?.font = font!
            self.scoreB?.font = font!
        }
        
        font = UIFont(name:"kongtext", size:30)
        
        if font != nil {
            self.lblStatus?.font = font!
        }
        
        font = UIFont(name: "kongtext", size:16)
        
        if font != nil {
            self.btnBack?.titleLabel?.font = font!
        }
        
        if Settings.sharedInstance.playerOnLeft {
            self.playerPaddle = self.paddleA
            self.opponentPaddle = self.paddleB
            self.playerScore = self.scoreA
            self.opponentScore = self.scoreB
        } else {
            self.playerPaddle = self.paddleB
            self.opponentPaddle = self.paddleA
            self.playerScore = self.scoreB
            self.opponentScore = self.scoreA
        }
        
        self.opponentPaddle?.image = UIImage(named: "opponent_paddle.png")
        
        self.restore()
        
        if let status = self.lblStatus {
            status.backgroundColor = UIColor.gray
            status.layer.cornerRadius = 10
            status.layer.borderColor = UIColor.white.cgColor
            status.layer.borderWidth = 2
            status.topInset = 10
            status.bottomInset = 10
            status.rightInset = 15
            status.leftInset = 15
            status.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.landscapeRight
    }
    
    func movePaddleOnTouch(_ touches: Set<UITouch>, type: PacketType) {
        if touches.first == nil || self.playerPaddle == nil {
            return
        }
        
        let touch = touches.first!
        
        let paddle = self.playerPaddle!
        
        let location = touch.location(in: touch.view)
        
        let isInPlayerZone = Settings.sharedInstance.playerOnLeft ? (location.x < 25) : (location.x > 400)
        
        if !isInPlayerZone {
            return
        }
        
        let yLocation: CGPoint = CGPoint(x: paddle.center.x, y: location.y)
        
        if yLocation.y - (paddle.frame.size.height/2) > 25 &&
            yLocation.y + (paddle.frame.size.height/2)
            < UIScreen.main.bounds.size.width-25
        {
            let game = Game.shared
            
            if self.ball != nil && paddle.frame.contains(self.ball!.center) && game.state != GameState.Running {
                self.ball!.center = yLocation
            }
            
            paddle.center = yLocation
            
            // let network player know the paddle has moved
            game.broadcast(type: type)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        movePaddleOnTouch(touches, type: PacketType.PaddleMove)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
       
        movePaddleOnTouch(touches, type: PacketType.Paddle)
    }
    
    // MARK: Dynamic properties
    
    var playerPosition: CGPoint {
        return self.playerPaddle != nil ? self.playerPaddle!.center : CGPoint.zero
    }
    
    var opponentPosition: CGPoint {
        return self.opponentPaddle != nil ? self.playerPaddle!.center : CGPoint.zero
    }
    
    var ballPosition: CGPoint {
        return self.ball != nil ? self.ball!.center : CGPoint.zero
    }
    
    func peerFound(_ multiplayer: Multiplayer, peer: NSObject) {
        
    }
    
    func peerLost(_ multiplayer: Multiplayer, peer: NSObject) {
        
    }
}
