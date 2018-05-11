//
//  Settings.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import Foundation

enum GameDifficulty: Int
{
    case Easy, Normal, Hard
    
    func toSpeedValue() -> Float {
        switch(self) {
        case GameDifficulty.Easy:
            return 3.7
        case GameDifficulty.Normal:
            return 4.3
        case GameDifficulty.Hard:
            return 5
        }
    }
}

struct GamePointIndex
{
    static let Min = 0
    static let Max = 3
    static let Default = Min
}

enum GameSpeed: Int
{
    case Slow, Normal, Fast
    
}

class Settings : NSObject
{
    static let sharedInstance:Settings = Settings()
    
    static let DidChangeNotificationName = NSNotification.Name("SettingsDidChangeNotifcation")

    private static let ComputerMoveSpeed: Float = 3.5
    
    private static let GamePointValues: [UInt16] = [ 5, 10, 15, 20 ]
    
    var playSounds:Bool
    var difficulty:GameDifficulty
    var gamePointIndex:Int
    var speedIndex:GameSpeed
    var matchSpeeds:Bool
    var matchGamePoint:Bool
    var playerOnLeft:Bool
    var lagReduction:Bool

    private override init() {
        let defaults = UserDefaults.standard
        
        let initialized = defaults.bool(forKey: "p0nginitialized")
        
        self.difficulty = GameDifficulty.Normal
        self.speedIndex = GameSpeed.Normal
        self.gamePointIndex = 0
        self.matchGamePoint = true
        self.matchSpeeds = true
        self.playSounds = true
        self.playerOnLeft = false
        self.lagReduction = false
        
        super.init()

        if initialized {
            self.load(defaults: defaults)
        } else {
            self.save()
        }
    }

    
    private func load(defaults: UserDefaults) {
        let difficulty = GameDifficulty(rawValue: defaults.integer(forKey: "p0ngAIDifficulty"))
    
        self.difficulty = difficulty ?? GameDifficulty.Normal
    
        let speedIndex = GameSpeed(rawValue: defaults.integer(forKey: "p0ngGameSpeed"))
    
        self.speedIndex = speedIndex ?? GameSpeed.Normal
        
        self.playerOnLeft = defaults.bool(forKey: "p0ngPlayerOnLeft")
        
        self.playSounds = !defaults.bool(forKey: "p0ngSoundsOff")
        
        self.gamePointIndex = defaults.integer(forKey: "p0ngGamePoint")
        
        if self.gamePointIndex < GamePointIndex.Min || self.gamePointIndex > GamePointIndex.Max {
            self.gamePointIndex = GamePointIndex.Default
        }
        
        self.matchGamePoint = defaults.bool(forKey: "p0ngMatchGamePoint")
        
        self.matchSpeeds = defaults.bool(forKey: "p0ngMatchSpeed")
        
        self.lagReduction = defaults.bool(forKey: "p0ngLagReduction")
    }
    
    
    var speed: TimeInterval {
        return TimeInterval(GameSpeed.Fast.rawValue - self.speedIndex.rawValue+1) / 100.0
    }
    
    var speedInterval: TimeInterval {
        return 100.0/TimeInterval(GameSpeed.Fast.rawValue - self.speedIndex.rawValue+1)
    }
    
    var gamePoint: UInt16 {
        return Settings.GamePointValues[self.gamePointIndex]
    }
    
    func save()
    {
        let defaults = UserDefaults.standard
        
        defaults.set(self.difficulty.rawValue, forKey:"p0ngAIDifficulty")
        
        defaults.set(self.speedIndex.rawValue, forKey:"p0ngGameSpeed")
        
        defaults.set(self.playerOnLeft, forKey:"p0ngPlayerOnLeft")
        
        defaults.set(!self.playSounds, forKey:"p0ngSoundsOff")
        
        defaults.set(self.gamePointIndex, forKey:"p0ngGamePoint")
        
        defaults.set(self.matchSpeeds, forKey:"p0ngMatchSpeed")
        
        defaults.set(self.matchGamePoint, forKey:"p0ngMatchGamePoint")
        
        defaults.set(self.lagReduction, forKey:"p0ngLagReduction")
        
        defaults.set(true, forKey:"p0nginitialized")
        
        NotificationCenter.default.post(name: Settings.DidChangeNotificationName, object:self)
    }
    
    static func addListener(_ delegate: AnyObject, selector: Selector) {
        
        let nc = NotificationCenter.default
        
        nc.addObserver(delegate, selector:selector, name:Settings.DidChangeNotificationName, object:nil)
    }
}
