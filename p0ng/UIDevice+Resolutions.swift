//
//  UIDevice+Resolutions.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import UIKit

enum UIDeviceResolution: UInt16 {
    
    case iPhoneStandardRes      = 1;    // iPhone 1,3,3GS Standard Resolution   (320x480px)
    case iPhoneHiRes            = 2;    // iPhone 4,4S High Resolution          (640x960px)
    case iPhoneTallerHiRes      = 3;    // iPhone 5 High Resolution             (640x1136px)
    case iPadStandardRes        = 4;    // iPad 1,2 Standard Resolution         (1024x768px)
    case iPadHiRes              = 5;    // iPad 3 High Resolution               (2048x1536px)
}

extension UIDevice {
    
    static func currentResolution() -> UIDeviceResolution {
        let screen = UIScreen.mainScreen();
        
        if(UIDevice.currentDevice().userInterfaceIdiom == .Phone){
            if (screen.respondsToSelector(#selector(NSDecimalNumberBehaviors.scale))) {
                var result = screen.bounds.size;
                result = CGSizeMake(result.width * screen.scale, result.height * screen.scale);
                if (result.height == 480) {
                    return UIDeviceResolution.iPhoneStandardRes;
                }
                return (result.height == 960 ? UIDeviceResolution.iPhoneHiRes : UIDeviceResolution.iPhoneTallerHiRes);
            } else {
                return UIDeviceResolution.iPhoneStandardRes;
            }
        } else if (screen.respondsToSelector(#selector(NSDecimalNumberBehaviors.scale))) {
            var result = screen.bounds.size;
            result = CGSizeMake(result.width * screen.scale, result.height * screen.scale);
            if (result.height == 1024) {
                return UIDeviceResolution.iPadStandardRes;
            }
            return UIDeviceResolution.iPadHiRes;
        } else {
            return UIDeviceResolution.iPadStandardRes;
        }
    }
}
