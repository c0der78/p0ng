//
//  BaseController.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import UIKit

@objc
class BaseController: UIViewController
{
    var appDelegate: AppDelegate?
    
    init(delegate: AppDelegate?, nibName nibNameOrNil: String?, bundle bundleNameOrNil: Bundle?) {
        self.appDelegate = delegate
        super.init(nibName: nibNameOrNil, bundle: bundleNameOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
