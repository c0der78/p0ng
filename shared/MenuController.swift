//
//  MenuController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import UIKit
import MultipeerConnectivity

@objc class MenuController : BaseController, MultiplayerDelegate, UIAlertViewDelegate
{
    @IBOutlet var lblHeader: UILabel?
    @IBOutlet var btnPlayComputer: UIButton?
    @IBOutlet var btnPlayOnline: UIButton?
    @IBOutlet var btnSettings: UIButton?
    @IBOutlet var btnContinue: UIButton?

    override init(delegate: BaseAppDelegate?, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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
    
        self.btnContinue?.isHidden = Game.shared.state != GameState.Paused
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
        Game.shared.state = GameState.Disconnected
    
        let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil)
    
        self.appDelegate?.pushViewController(viewController: viewController, animated:true)
        
        Game.shared.newGame(isComputer: true)
    }
    
    @IBAction func continueGame(sender: UIButton) {
        let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil)
    
        self.appDelegate?.pushViewController(viewController: viewController, animated:true)
    
        Game.shared.state = GameState.Countdown1
    }
    
    @IBAction func playOnline(sender: AnyObject) {
        Game.shared.findMultiplayerMatch(forViewController: self, delegate: self)
    }
    
    func peerFound(_ multiplayer: Multiplayer, peer: NSObject) {
        Game.shared.newGame(isComputer: false)
        
        DispatchQueue.main.async {
            let viewController = GameController(delegate: self.appDelegate, nibName:"GameController", bundle:nil)
            self.appDelegate?.pushViewController(viewController: viewController, animated:true)
        }
    }
    
    func peerLost(_ multiplayer: Multiplayer, peer: NSObject) {
        
    }
    
    @IBAction func showSettings(sender: AnyObject) {
        let viewController = OptionsController(delegate: self.appDelegate, nibName:"OptionsController", bundle:nil)
        self.appDelegate?.pushViewController(viewController: viewController, animated:true)
    }

}
