//
//  AppDelegate.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate
{
    var viewControllers: [BaseController];
    var window: UIWindow?;

    
    override init() {
        self.viewControllers = [];
        super.init();
    }
    
    func pushViewController(viewController: BaseController, animated: Bool) {
        
        let previous = self.viewControllers.last as BaseController?;
        
        self.viewControllers.append(viewController);
        
        viewController.appDelegate = self;
        
        viewController.view.layoutIfNeeded();
        
        viewController.view.alpha = 0;
        
        if (self.window != nil) {
            self.window!.rootViewController = viewController;
        }
        
        if(animated)
        {
            UIView.animateWithDuration(0.75, animations:{ () in
                
                if(previous != nil)
                {
                    previous!.view.alpha = 0;
                    previous!.view.removeFromSuperview();
                }
                
                viewController.view.alpha = 1;
                
                }, completion:{ (finished: Bool) in
                
                });
            
        } else if(previous != nil) {
            viewController.view.alpha = 1;
            previous!.view.removeFromSuperview();
        }
        
    }
    
    func popViewControllerAnimated(animated: Bool) {
        
        if(self.viewControllers.count <= 1) {
            return;
        }
        
        let current = self.viewControllers.last;
        
        self.viewControllers.removeLast();
        
        let previous = self.viewControllers.last;
        
        if (previous != nil ) {
            
            previous!.view.alpha = 0;
        
            if (self.window != nil) {
                self.window!.rootViewController = previous;
            }
        
            previous!.view.layoutIfNeeded();
        }
        
        if(animated) {
            UIView.animateWithDuration(0.75, animations:{ () in
                    current!.view.alpha = 0;
                    previous!.view.alpha = 1;
                }, completion: { (finished: Bool) in
                
                    current!.view.removeFromSuperview();
                
                });
        } else {
            current!.view.removeFromSuperview();
        }
        
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
    
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds);
    
        let viewController = MenuController(delegate: self, nibName: "MenuController", bundle:nil);
    
        viewController.appDelegate = self;
    
        self.viewControllers.append(viewController);
        
        if (self.window != nil) {
            self.window!.rootViewController = viewController;
            self.window!.makeKeyAndVisible();
        }
        return true;
    }
    
    func applicationDidEnterBackground(application: UIApplication)
    {
        if(Game.sharedInstance.state != GameState.Disconnected)
        {
            if(!Game.sharedInstance.opponentIsComputer) {
                Game.sharedInstance.gameOver(true);
            } else {
                Game.sharedInstance.state = GameState.Paused;
            }
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication)
    {
        if(Game.sharedInstance.state == GameState.Paused) {
            Game.sharedInstance.state = GameState.Countdown1;
        }
    }
    

}