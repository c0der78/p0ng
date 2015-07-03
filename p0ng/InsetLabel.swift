//
//  InsetLabel.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import UIKit

class InsetLabel : UILabel
{
    var topInset: CGFloat;
    var leftInset: CGFloat;
    var bottomInset: CGFloat;
    var rightInset: CGFloat;

    
    override init(frame: CGRect)
    {
        self.topInset = 0;
        self.leftInset = 0;
        self.bottomInset = 0;
        self.rightInset = 0;
        super.init(frame: frame);
    }

    required init(coder aDecoder: NSCoder) {
        self.topInset = 0;
        self.leftInset = 0;
        self.bottomInset = 0;
        self.rightInset = 0;
        super.init(coder: aDecoder);
    }
    
    override func drawTextInRect(rect: CGRect)
    {
        let insets = UIEdgeInsets(top: self.topInset, left: self.leftInset, bottom: self.bottomInset, right: self.rightInset);
    
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets));
    }
    
    override func sizeToFit() {
        super.sizeToFit();
    
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width+self.leftInset+self.rightInset, self.frame.size.height+self.topInset+self.bottomInset);
    }

}
