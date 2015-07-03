//
//  BaseController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import UIKit

@objc
class BaseController: UIViewController
{
    var appDelegate: AppDelegate?;
    
    init(delegate: AppDelegate?, nibName nibNameOrNil: String?, bundle bundleNameOrNil: NSBundle?) {
        self.appDelegate = delegate;
        super.init(nibName: nibNameOrNil, bundle: bundleNameOrNil);
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
}