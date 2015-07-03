//
//  MenuController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import UIKit

@objc
class MenuController : BaseController, GameCenterProtocol, UIAlertViewDelegate
{
    @IBOutlet var lblHeader: UILabel?;
    @IBOutlet var btnPlayComputer: UIButton?;
    @IBOutlet var btnPlayOnline: UIButton?;
    @IBOutlet var btnSettings: UIButton?;
    @IBOutlet var btnContinue: UIButton?;

    override init(delegate: AppDelegate?, nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(delegate: delegate, nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }

    override func viewDidLoad()
    {
        super.viewDidLoad();
    
        self.title = "Home";
        
        var font = UIFont(name:"kongtext", size:64);
        
        if (font != nil) {
            self.lblHeader?.font = font!;
        }
        
        font = UIFont(name:"kongtext", size:20);
        
        if (font != nil) {
            self.btnPlayComputer?.titleLabel?.font = font!;
            self.btnPlayOnline?.titleLabel?.font = font!;
            self.btnSettings?.titleLabel?.font = font!;
            self.btnContinue?.titleLabel?.font = font!;
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
    
        if(Game.sharedInstance.state == GameState.Paused) {
            self.btnContinue?.hidden = false;
        } else {
            self.btnContinue?.hidden = true;
        }
    }
    
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait;
    }
    
    override func preferredInterfaceOrientationForPresentation () -> UIInterfaceOrientation {
        return UIInterfaceOrientation.Portrait;
    }
    
    override func shouldAutorotate() -> Bool {
        return true;
    }
    
    @IBAction func playComputer(sender: AnyObject) {
        Game.sharedInstance.state = GameState.Disconnected;
    
        let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil);
    
        self.appDelegate?.pushViewController(viewController, animated:true);
        
        Game.sharedInstance.newGame(true);
    }
    
    @IBAction func continueGame(sender: AnyObject) {
        let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil);
    
        self.appDelegate?.pushViewController(viewController, animated:true);
    
        Game.sharedInstance.state = GameState.Countdown1;
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: NSInteger)
    {
        if(buttonIndex == 1) {
            self.showSettings(self);
        }
    }
    
    @IBAction func playOnline(sender: AnyObject) {
        
        Game.sharedInstance.state = GameState.Disconnected;
        
        GameCenter.sharedInstance.authenticateLocalUser(self.appDelegate, gameCenterDelegate: self);
    }
    
    func matchFound(gameCenter: GameCenter) {
        let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil);
    
        self.appDelegate?.pushViewController(viewController, animated:true);
    }
    
    @IBAction func showSettings(sender: AnyObject) {
    
        let viewController = OptionsController(delegate: self.appDelegate, nibName:"OptionsController", bundle:nil);
    
        self.appDelegate?.pushViewController(viewController, animated:true);
    }

}
