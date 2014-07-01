//
//  A3AppDelegate.h
//  p0ng
//
//  Created by Ryan Jennings on 2013-01-08.
//  Copyright (c) 2013 arg3 software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class A3ViewController;

@interface A3AppDelegate : UIResponder <UIApplicationDelegate>
{
    NSMutableArray *_viewControllers;
}

@property (strong, nonatomic) UIWindow *window;

- (void) pushViewController: (A3ViewController *)viewController animated:(BOOL) animated;

- (void) popViewControllerAnimated: (BOOL) animated;

@end
