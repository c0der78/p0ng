//
//  Settings.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import Foundation

@objc enum GameDifficulty: Int
{
    case Easy, Normal, Hard;
    
    func toSpeedValue() -> Float {
        switch(self) {
        case Easy:
            return 3.7;
        case Normal:
            return 4.3;
        case Hard:
            return 5;
        }
    }
}

struct GamePointIndex
{
    static let Min = 0;
    static let Max = 3;
    static let Default = Min;
}

@objc enum GameSpeed: Int
{
    case Slow, Normal, Fast;
    
}

@objc class Settings
{
    static let sharedInstance:Settings = Settings();
    
    static let DidChangeNotificationName = "SettingsDidChangeNotifcation";

    private static let ComputerMoveSpeed: Float = 3.5;
    
    private static let GamePointValues: [UInt] = [ 5, 10, 15, 20 ];
    
    var playSounds:Bool;
    var difficulty:GameDifficulty;
    var gamePointIndex:Int;
    var speedIndex:GameSpeed;
    var matchSpeeds:Bool;
    var matchGamePoint:Bool;
    var playerOnLeft:Bool;
    var lagReduction:Bool;

    private init() {
        let defaults = NSUserDefaults.standardUserDefaults();
        
        let initialized = defaults.boolForKey("p0nginiialized");
        
        self.difficulty = GameDifficulty.Normal;
        self.speedIndex = GameSpeed.Normal;
        self.gamePointIndex = 0;
        self.matchGamePoint = true;
        self.matchSpeeds = true;
        self.playSounds = true;
        self.playerOnLeft = false;
        self.lagReduction = false;

        if(initialized) {
            self.load(defaults);
        }
        else
        {
            self.save();
        }
    }

    
    private func load(defaults: NSUserDefaults) {
        let difficulty = GameDifficulty(rawValue: defaults.integerForKey("p0ngAIDifficulty"));
    
        if(difficulty == nil ) {
            self.difficulty = GameDifficulty.Normal;
        } else {
            self.difficulty = difficulty!;
        }
    
        let speedIndex = GameSpeed(rawValue: defaults.integerForKey("p0ngGameSpeed"));
    
        if(speedIndex == nil) {
            self.speedIndex = GameSpeed.Normal;
        } else {
            self.speedIndex = speedIndex!;
        }
        
        self.playerOnLeft = defaults.boolForKey("p0ngPlayerOnLeft");
        
        self.playSounds = !defaults.boolForKey("p0ngSoundsOff");
        
        self.gamePointIndex = defaults.integerForKey("p0ngGamePoint");
        
        if(self.gamePointIndex < GamePointIndex.Min || self.gamePointIndex > GamePointIndex.Max) {
            self.gamePointIndex = GamePointIndex.Default;
        }
        
        self.matchGamePoint = defaults.boolForKey("p0ngMatchGamePoint");
        
        self.matchSpeeds = defaults.boolForKey("p0ngMatchSpeed");
        
        self.lagReduction = defaults.boolForKey("p0ngLagReduction");
    }
    
    
    var speed: NSTimeInterval {
        get
        {
            return NSTimeInterval(GameSpeed.Fast.rawValue - self.speedIndex.rawValue+1) / 100.0;
        }
    }
    
    var speedInterval: NSTimeInterval {
        get {
            return 100.0/NSTimeInterval(GameSpeed.Fast.rawValue - self.speedIndex.rawValue+1);
        }
    }
    
    var gamePoint: UInt {
        get { return Settings.GamePointValues[self.gamePointIndex]; }
    }
    
    func save()
    {
        let defaults = NSUserDefaults.standardUserDefaults();
        
        defaults.setInteger(self.difficulty.rawValue, forKey:"p0ngAIDifficulty");
        
        defaults.setInteger(self.speedIndex.rawValue, forKey:"p0ngGameSpeed");
        
        defaults.setBool(self.playerOnLeft, forKey:"p0ngPlayerOnLeft");
        
        defaults.setBool(!self.playSounds, forKey:"p0ngSoundsOff");
        
        defaults.setInteger(self.gamePointIndex, forKey:"p0ngGamePoint");
        
        defaults.setBool(self.matchSpeeds, forKey:"p0ngMatchSpeed");
        
        defaults.setBool(self.matchGamePoint, forKey:"p0ngMatchGamePoint");
        
        defaults.setBool(self.lagReduction, forKey:"p0ngLagReduction");
        
        defaults.setBool(true, forKey:"p0nginitialized");
        
        NSNotificationCenter.defaultCenter().postNotificationName(Settings.DidChangeNotificationName, object:self);
    }
    
    static func addListener(delegate: AnyObject, selector: Selector) {
        
        let nc:NSNotificationCenter = NSNotificationCenter.defaultCenter();
        
        nc.addObserver(delegate, selector:selector, name:Settings.DidChangeNotificationName, object:nil);
    }
}
