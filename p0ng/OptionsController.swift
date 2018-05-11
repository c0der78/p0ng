//
//  OptionsController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import UIKit

@objc class OptionsController : BaseController {
    @IBOutlet var contentView: UIView?
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var lblMatching: UILabel?
    @IBOutlet var lblMatchSpeed: UILabel?
    @IBOutlet var lblMatchGamePoint: UILabel?
    @IBOutlet var lblAiDifficulty: UILabel?
    @IBOutlet var lblSounds: UILabel?
    @IBOutlet var lblGamePoint: UILabel?
    @IBOutlet var segAiDifficulty: UISegmentedControl?
    @IBOutlet var navBar: UINavigationBar?
    @IBOutlet var navItem: UINavigationItem?
    @IBOutlet var segBallSpeed: UISegmentedControl?
    @IBOutlet var lblBallSpeed: UILabel?
    @IBOutlet var lblPlayerPosition: UILabel?
    @IBOutlet var segPlayerPosition: UISegmentedControl?
    @IBOutlet var switchSounds: UISwitch?
    @IBOutlet var matchSpeed: UISwitch?
    @IBOutlet var matchGamePoint: UISwitch?
    @IBOutlet var segNetwork: UISegmentedControl?
    @IBOutlet var segGamePoint: UISegmentedControl?
    
    override init(delegate: AppDelegate?, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(delegate: delegate, nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBAction func goBack(_ selected: AnyObject) {
        self.appDelegate?.popViewControllerAnimated(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        let settings = Settings.sharedInstance
    
        if let value = self.segAiDifficulty?.selectedSegmentIndex {
            let difficulty = GameDifficulty(rawValue: value)
            
            if difficulty != nil {
                settings.difficulty = difficulty!
            }
        }
        
        if let value = self.segBallSpeed?.selectedSegmentIndex {
            let speed = GameSpeed(rawValue: value)
            
            if speed != nil {
                settings.speedIndex = speed!
            }
        }
    
        if let value = self.switchSounds?.isOn {
            settings.playSounds = value
        }
    
        if let value = self.segGamePoint?.selectedSegmentIndex {
            settings.gamePointIndex = value
        }
    
        if let value = self.segPlayerPosition?.selectedSegmentIndex {
            let left = (value == 0)
        
            if left != settings.playerOnLeft {
                Game.sharedInstance.gameOver(disconnected: true)
            }
        
            settings.playerOnLeft = left
        }
    
        if let value = self.matchGamePoint?.isOn {
            settings.matchGamePoint = value
        }
    
        if let value = self.matchSpeed?.isOn {
            settings.matchSpeeds = value
        }
    
        if let value = self.segNetwork?.selectedSegmentIndex {
            settings.lagReduction = (value == 0)
        }
    
        settings.save()
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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        self.title = "Options"
    
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 44))
        label.backgroundColor = UIColor.clear
        let font = UIFont(name:"kongtext", size:20.0)
        if font != nil {
            label.font = font!
        }
        label.shadowColor = UIColor(white:0.0, alpha:0.5)
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.white
        label.text = self.title
        
        self.navItem?.titleView = label
        self.navItem?.titleView!.sizeToFit()
    
        let backItem = UIBarButtonItem(image: UIImage(named:"leftarrow.white.png"), style:UIBarButtonItemStyle.plain, target:self, action:#selector(goBack(_:)))
    
        self.navItem?.leftBarButtonItem = backItem
    
        let settings = Settings.sharedInstance
    
        self.segAiDifficulty?.selectedSegmentIndex = settings.difficulty.rawValue
        
        self.segBallSpeed?.selectedSegmentIndex = settings.speedIndex.rawValue
        
        self.segPlayerPosition?.selectedSegmentIndex = settings.playerOnLeft ? 0 : 1
        
        self.segGamePoint?.selectedSegmentIndex = settings.gamePointIndex
        
        self.segNetwork?.selectedSegmentIndex = settings.lagReduction ? 0 : 1
        
        self.matchGamePoint?.isOn = settings.matchGamePoint
        
        self.matchSpeed?.isOn = settings.matchSpeeds
        
        self.switchSounds?.isOn = settings.playSounds
        
        if let content = self.contentView {
            self.scrollView?.contentSize = content.bounds.size
            self.scrollView?.addSubview(content)
        }
    }
}

