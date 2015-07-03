//
//  OptionsController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import UIKit

@objc
class OptionsController : BaseController
{
    @IBOutlet var contentView: UIView?;
    @IBOutlet var scrollView: UIScrollView?;
    @IBOutlet var lblMatching: UILabel?;
    @IBOutlet var lblMatchSpeed: UILabel?;
    @IBOutlet var lblMatchGamePoint: UILabel?;
    @IBOutlet var lblAiDifficulty: UILabel?;
    @IBOutlet var lblSounds: UILabel?;
    @IBOutlet var lblGamePoint: UILabel?;
    @IBOutlet var segAiDifficulty: UISegmentedControl?;
    @IBOutlet var navBar: UINavigationBar?;
    @IBOutlet var navItem: UINavigationItem?;
    @IBOutlet var segBallSpeed: UISegmentedControl?;
    @IBOutlet var lblBallSpeed: UILabel?;
    @IBOutlet var lblPlayerPosition: UILabel?;
    @IBOutlet var segPlayerPosition: UISegmentedControl?;
    @IBOutlet var switchSounds: UISwitch?;
    @IBOutlet var matchSpeed: UISwitch?;
    @IBOutlet var matchGamePoint: UISwitch?;
    @IBOutlet var segNetwork: UISegmentedControl?;
    @IBOutlet var segGamePoint: UISegmentedControl?;
    
    override init(delegate: AppDelegate?, nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(delegate: delegate, nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }

    @IBAction func goBack(selected: AnyObject) {
        if (self.appDelegate != nil) {
            self.appDelegate!.popViewControllerAnimated(true);
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
    
        let settings = Settings.sharedInstance;
    
        if (self.segAiDifficulty != nil) {
            let difficulty = GameDifficulty(rawValue: self.segAiDifficulty!.selectedSegmentIndex);
            
            if (difficulty != nil) {
                settings.difficulty = difficulty!;
            }
        }
        if (self.segBallSpeed != nil) {
            let speed = GameSpeed(rawValue: self.segBallSpeed!.selectedSegmentIndex);
            
            if (speed != nil) {
                settings.speedIndex = speed!;
            }
        }
    
        if (self.switchSounds != nil) {
            settings.playSounds = self.switchSounds!.on;
        }
    
        if (self.segGamePoint != nil) {
            settings.gamePointIndex = self.segGamePoint!.selectedSegmentIndex;
        }
    
        if (self.segPlayerPosition != nil) {
            let left = (self.segPlayerPosition!.selectedSegmentIndex == 0);
        
            if(left != settings.playerOnLeft) {
                Game.sharedInstance.gameOver(true);
            }
        
            settings.playerOnLeft = left;
        }
    
        if (self.matchGamePoint != nil) {
            settings.matchGamePoint = self.matchGamePoint!.on;
        }
    
        if (self.matchSpeed != nil) {
            settings.matchSpeeds = self.matchSpeed!.on;
        }
    
        if (self.segNetwork != nil) {
            settings.lagReduction = self.segNetwork!.selectedSegmentIndex == 0;
        }
    
        settings.save();
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait;
    }
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.Portrait;
    }
    override func shouldAutorotate() -> Bool {
        return true;
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
    
        self.title = "Options";
    
        let label = UILabel(frame:CGRectMake(0, 0, 400, 44));
        label.backgroundColor = UIColor.clearColor();
        let font = UIFont(name:"kongtext", size:20.0);
        if (font != nil) {
            label.font = font!;
        }
        label.shadowColor = UIColor(white:0.0, alpha:0.5);
        label.textAlignment = NSTextAlignment.Center;
        label.textColor = UIColor.whiteColor();
        label.text = self.title;
        
        if (self.navItem != nil) {
            self.navItem!.titleView = label;
            self.navItem!.titleView!.sizeToFit();
        }
    
        let backItem = UIBarButtonItem(image: UIImage(named:"leftarrow.white.png"), style:UIBarButtonItemStyle.Plain, target:self, action:Selector("goBack:"));
    
        if (self.navItem != nil) {
            self.navItem!.leftBarButtonItem = backItem;
        }
    
        let settings = Settings.sharedInstance;
    
        if (self.segAiDifficulty != nil) {
            self.segAiDifficulty!.selectedSegmentIndex = settings.difficulty.rawValue;
        }
        
        if (self.segBallSpeed != nil) {
            self.segBallSpeed!.selectedSegmentIndex = settings.speedIndex.rawValue;
        }
        
        if (self.segPlayerPosition != nil) {
            self.segPlayerPosition!.selectedSegmentIndex = settings.playerOnLeft ? 0 : 1;
        }
        
        if (self.segGamePoint != nil) {
            self.segGamePoint!.selectedSegmentIndex = settings.gamePointIndex;
        }
    
        if (self.segNetwork != nil) {
            self.segNetwork!.selectedSegmentIndex = settings.lagReduction ? 0 : 1;
        }
    
        if (self.matchGamePoint != nil) {
            self.matchGamePoint!.on = settings.matchGamePoint;
        }
    
        if (self.matchSpeed != nil) {
            self.matchSpeed!.on = settings.matchSpeeds;
        }
    
        if (self.switchSounds != nil) {
            self.switchSounds!.on = settings.playSounds;
        }
    
        if (self.scrollView != nil && self.contentView != nil) {
            self.scrollView!.contentSize = self.contentView!.bounds.size;
            self.scrollView!.addSubview(self.contentView!);
        }
    
    }

}

