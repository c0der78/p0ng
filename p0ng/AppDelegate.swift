//
//  AppDelegate.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate
{
    var viewControllers: [BaseController]
    var window: UIWindow?

    override init() {
        self.viewControllers = []
        super.init()
    }
    
    func pushViewController(viewController: BaseController, animated: Bool) {
        
        let previous = self.viewControllers.last as BaseController?
        
        self.viewControllers.append(viewController)
        
        viewController.appDelegate = self
        
        viewController.view.layoutIfNeeded()
        
        viewController.view.alpha = 0
        
        self.window?.rootViewController = viewController
        
        viewController.view.alpha = 1
        
        if !animated {
            // remove from previous view
            previous?.view.removeFromSuperview()
            return
        }
        
        UIView.animate(withDuration: 0.75, animations:{ () in
            // hide previous view and remove it
            previous?.view.alpha = 0
            previous?.view.removeFromSuperview()
        }, completion:nil)
    }
    
    func popViewControllerAnimated(animated: Bool) {
        
        if self.viewControllers.isEmpty {
            return
        }
        
        let current = self.viewControllers.last
        
        self.viewControllers.removeLast()
        
        let previous = self.viewControllers.last
    
        previous?.view.alpha = 0
    
        self.window?.rootViewController = previous
    
        previous?.view.layoutIfNeeded()
        
        if !animated {
            current?.view.removeFromSuperview()
            return
        }
        
        UIView.animate(withDuration: 0.75, animations:{ () in
            current?.view.alpha = 0
            previous?.view.alpha = 1
        }, completion: { (finished: Bool) in
            current?.view.removeFromSuperview()
        })
    }
    
    func applicationDidFinishLaunching(_ application: UIApplication) {

        self.window = UIWindow(frame: UIScreen.main.bounds)
    
        let viewController = MenuController(delegate: self, nibName: "MenuController", bundle:nil)
    
        viewController.appDelegate = self
    
        self.viewControllers.append(viewController)
        
        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if Game.sharedInstance.state == GameState.Disconnected {
            return
        }
        
        if !Game.sharedInstance.opponentIsComputer {
            Game.sharedInstance.gameOver(disconnected: true)
        } else {
            Game.sharedInstance.state = GameState.Paused
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if Game.sharedInstance.state == GameState.Paused {
            Game.sharedInstance.state = GameState.Countdown1
        }
    }
}
