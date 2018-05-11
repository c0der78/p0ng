//
//  MenuController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import UIKit

@objc class MenuController : BaseController, GameCenterProtocol, UIAlertViewDelegate
{
    @IBOutlet var lblHeader: UILabel?
    @IBOutlet var btnPlayComputer: UIButton?
    @IBOutlet var btnPlayOnline: UIButton?
    @IBOutlet var btnSettings: UIButton?
    @IBOutlet var btnContinue: UIButton?

    override init(delegate: AppDelegate?, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(delegate: delegate, nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.title = "Home"
        
        var font = UIFont(name:"kongtext", size:64)
        
        if font != nil {
            self.lblHeader?.font = font!
        }
        
        font = UIFont(name:"kongtext", size:20)
        
        if font != nil {
            self.btnPlayComputer?.titleLabel?.font = font!
            self.btnPlayOnline?.titleLabel?.font = font!
            self.btnSettings?.titleLabel?.font = font!
            self.btnContinue?.titleLabel?.font = font!
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        self.btnContinue?.isHidden = Game.sharedInstance.state != GameState.Paused
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func playComputer(sender: UIButton) {
        Game.sharedInstance.state = GameState.Disconnected
    
        let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil)
    
        self.appDelegate?.pushViewController(viewController: viewController, animated:true)
        
        Game.sharedInstance.newGame(isComputer: true)
    }
    
    @IBAction func continueGame(sender: UIButton) {
        let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil)
    
        self.appDelegate?.pushViewController(viewController: viewController, animated:true)
    
        Game.sharedInstance.state = GameState.Countdown1
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: NSInteger) {
        if buttonIndex == 1 {
            self.showSettings(sender: self)
        }
    }
    
    @IBAction func playOnline(sender: AnyObject) {
        Game.sharedInstance.state = GameState.Disconnected
        
        GameCenter.sharedInstance.authenticateLocalUser(appDelegate: self.appDelegate, gameCenterDelegate: self)
    }
    
    func matchFound(gameCenter: GameCenter) {
        let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil)
    
        self.appDelegate?.pushViewController(viewController: viewController, animated:true)
    }
    
    @IBAction func showSettings(sender: AnyObject) {
        let viewController = OptionsController(delegate: self.appDelegate, nibName:"OptionsController", bundle:nil)
    
        self.appDelegate?.pushViewController(viewController: viewController, animated:true)
    }

}
