//
//  A3AppDelegate.m
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-08.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import "A3AppDelegate.h"

#import "A3MenuViewController.h"

#import "A3PongGame.h"

@implementation A3AppDelegate

/*+ (void) loadViewController:(UIViewController *)viewController {
    A3AppDelegate *delegate = (A3AppDelegate*)[UIApplication sharedApplication].delegate;
    
    //UIViewController *root = delegate.window.rootViewController;
    
    delegate.window.rootViewController = delegate.viewController = viewController;
    
    //[root.view removeFromSuperview];
    
}*/

- (void) resetOrientation
{
    /* hack to reset orientation */
    /*UIViewController *c = [[UIViewController alloc]init];
    [self.window.rootViewController presentModalViewController:c animated:NO];
    [self.window.rootViewController dismissModalViewControllerAnimated:NO];*/
    
}

- (void) pushViewController: (A3ViewController *)viewController animated:(BOOL) animated {
    
    A3ViewController *previous = [_viewControllers lastObject];
    
    [_viewControllers addObject:viewController];
    
    viewController.appDelegate = self;
    
    [viewController.view layoutIfNeeded];
                   
    viewController.view.alpha = 0;
    
    self.window.rootViewController = viewController;
    
    if(animated)
    {
        [UIView animateWithDuration:0.75 animations:^(void) {;
            
            if(previous)
            {
                previous.view.alpha = 0;
                [previous.view removeFromSuperview];
            }
            
            viewController.view.alpha = 1;
            
        } completion:^(BOOL finished) {
            
        }];
    } else if(previous) {
        viewController.view.alpha = 1;
        [previous.view removeFromSuperview];
    }
    
}

- (void) popViewControllerAnimated:(BOOL)animated {
    
    if(_viewControllers.count <= 1)
        return;
    
    A3ViewController *current = [_viewControllers lastObject];
    
    [_viewControllers removeLastObject];
    
    A3ViewController *previous = [_viewControllers lastObject];
    
    previous.view.alpha = 0;
    
    self.window.rootViewController = previous;
    
    [previous.view layoutIfNeeded];
    
    [self resetOrientation];
    
    if(animated) {
        [UIView animateWithDuration:0.75 animations:^(void) {
            current.view.alpha = 0;
            previous.view.alpha = 1;
        } completion: ^(BOOL finished) {
            
            [current.view removeFromSuperview];

        }];
    } else {
        [current.view removeFromSuperview];
    }
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    A3ViewController *viewController = [[A3MenuViewController alloc] initWithNibName:@"A3MenuViewController" bundle:nil];
    
    viewController.appDelegate = self;
    
    _viewControllers = [[NSMutableArray alloc] initWithObjects:viewController, nil];
    
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if([A3PongGame sharedInstance].state != kGameStateDisconnected)
    {
        
        if(![A3PongGame sharedInstance].opponentIsComputer)
            [[A3PongGame sharedInstance] gameOver:YES];
        
        else
            [A3PongGame sharedInstance].state = kGameStatePaused;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if([A3PongGame sharedInstance].state == kGameStatePaused)
        [A3PongGame sharedInstance].state = kGameCountdown1;
    
    [self resetOrientation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
