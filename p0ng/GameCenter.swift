//
//  GameCenter.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 arg3 software. All rights reserved.
//

import Foundation
import GameKit

@objc
protocol GameCenterProtocol
{
    func matchFound(gameCenter: GameCenter);
}

struct GameCenterFlags
{
    static let Fast = (1 << 0)
    static let Normal = (1 << 1)
    static let Slow = (1 << 2)
    static let Match5 = (1 << 3)
    static let Match10 = (1 << 4)
    static let Match15 = (1 << 5)
    static let Match20 = (1 << 6)
}


@objc class GameCenter : NSObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate
{
    static let sharedInstance = GameCenter();
    
    private(set) var isHosting: Bool;
    
    var userAuthenticated: Bool;
    var matchStarted: Bool;
    var delegate: GameCenterProtocol?;
    

    var presentingViewController: UIViewController?;
    var match: GKMatch?;
    
    
    private override init() {
        
        self.isHosting = false;
        self.matchStarted = false;
        self.delegate = nil;
        self.userAuthenticated = false;
        
        super.init();
        
        let nc = NSNotificationCenter.defaultCenter();
    
        nc.addObserver(self, selector:Selector("authenticationChanged"),
            name:GKPlayerAuthenticationDidChangeNotificationName,
            object:nil);
    }
    
    func authenticationChanged() {
    
        if (GKLocalPlayer.localPlayer().authenticated && !self.userAuthenticated) {
            NSLog("Authentication changed: player authenticated.");
            self.userAuthenticated = true;
        } else if (!GKLocalPlayer.localPlayer().authenticated && self.userAuthenticated) {
            NSLog("Authentication changed: player not authenticated");
            self.userAuthenticated = false;
        }
    
    }
    
    func disconnect() {

        if(self.match == nil) { return; }
    
        self.match!.disconnect();
    
    }
    
    var playerGroup: Int
    {
        get {
            let settings = Settings.sharedInstance;
            
            var group:Int = 0;
            
            switch(settings.speedIndex) {
                case GameSpeed.Fast:
                    group |= GameCenterFlags.Fast;
                    break;
                case GameSpeed.Normal:
                    group |= GameCenterFlags.Normal;
                    break;
                case GameSpeed.Slow:
                    group |= GameCenterFlags.Slow;
                    break;
            }
            
            switch(settings.gamePointIndex)
            {
                case GamePointIndex.Min:
                    group |= GameCenterFlags.Match5;
                    break;
                case GamePointIndex.Min+1:
                    group |= GameCenterFlags.Match10;
                    break;
                case GamePointIndex.Max-1:
                    group |= GameCenterFlags.Match15;
                    break;
                case GamePointIndex.Max:
                    group |= GameCenterFlags.Match20;
                    break;
                default:
                    break;
            }
            
            return group;
        }
    }
    
    func findMatchWithViewController(viewController: UIViewController?) {
        
        self.matchStarted = false;
        self.isHosting = false;
        self.match = nil;
        self.presentingViewController = viewController;
            
        if (self.presentingViewController != nil) {
           self.presentingViewController!.dismissViewControllerAnimated(false, completion:nil);
        }
        
        let request = GKMatchRequest();
        request.minPlayers = 2;
        request.maxPlayers = 2;
        request.playerGroup = self.playerGroup;
        
        let mmvc:GKMatchmakerViewController! = GKMatchmakerViewController(matchRequest:request);
        
        mmvc.matchmakerDelegate = self;
        mmvc.modalPresentationStyle = UIModalPresentationStyle.FullScreen;
        
        NSLog("Finding match on game center...");
        
        if (self.presentingViewController != nil) {
            self.presentingViewController!.presentViewController(mmvc, animated:true, completion:nil);
        }
    }
    
    
    // The user has cancelled matchmaking
    func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController) {
        if (self.presentingViewController != nil) {
            self.presentingViewController!.dismissViewControllerAnimated(true, completion:nil);
        }
        NSLog("Match was cancelled");
        self.isHosting = false;
        self.matchStarted = false;
    }
    
    // Matchmaking has failed with an error
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFailWithError error: NSError) {
        viewController.dismissViewControllerAnimated(true, completion:nil);
        
        NSLog("Error %@", error);
        self.isHosting = false;
        self.matchStarted = false;
    }
    
    // A peer-to-peer match has been found, the game should start
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFindMatch theMatch: GKMatch) {
        viewController.dismissViewControllerAnimated(true, completion:nil);
    
        self.match = theMatch;
        theMatch.delegate = self;
        if (!self.matchStarted && theMatch.expectedPlayerCount == 0) {
            NSLog("Ready to start match!");
        
            let player = GKLocalPlayer.localPlayer();
            
            if (player.playerID != nil) {
                self.isHosting = player.playerID == theMatch.playerIDs[0];
            }
            NSLog("is Hosting? = %@", self.isHosting ? "YES" : "NO");
            self.matchStarted = true;
        
            if (self.delegate != nil) {
                self.delegate!.matchFound(self);
            }
        
            Game.sharedInstance.newGame(false);
        }
        else{
            NSLog("Match found, but not ready");
        }
    }
        // The match received data sent from the player.
    func match(theMatch: GKMatch, didReceiveData data: NSData, fromPlayer playerID: String) {
    
        if (self.match != theMatch) { return; }
    
        if(playerID == GKLocalPlayer.localPlayer().playerID) {
            return;
        }
    
        var packet = p0ngPacket();
    
        data.getBytes(&packet, length:sizeof(p0ngPacket));
    
        Game.sharedInstance.gotPacket(packet);
    
    }
    
    
    // The player state changed (eg. connected or disconnected)
    func match(theMatch: GKMatch, player playerID: String, didChangeState state:GKPlayerConnectionState) {
        if (self.match != theMatch) { return; }
    
        switch (state) {
        case GKPlayerConnectionState.StateConnected:
            // handle a new player connection.
            NSLog("Player connected!");
            
            if (!self.matchStarted && theMatch.expectedPlayerCount == 0) {
                NSLog("Ready to start match!");
                
                let player = GKLocalPlayer.localPlayer();
            
                if(player.playerID != nil) {
                    self.isHosting = player.playerID == theMatch.playerIDs[0];
                }
                self.matchStarted = true;
            
                if (self.delegate != nil) {
                    self.delegate!.matchFound(self);
                }
            
                Game.sharedInstance.newGame(false);
            } else {
                NSLog("Match found, but not ready");
            }
            
            break;
        case GKPlayerConnectionState.StateDisconnected:
            // a player just disconnected.
            NSLog("Player disconnected!");
            self.matchStarted = false;
            Game.sharedInstance.gameOver(true);
            break;
        default:
            break;
        }
    }
    
    // The match was unable to connect with the player due to an error.
    func match(theMatch: GKMatch, connectionWithPlayerFailed playerID:String, withError error: NSError) {
        
        NSLog("Failed to connect to player with error: %@", error);
        
        if (self.match != theMatch) { return; }
        
        self.matchStarted = false;
        Game.sharedInstance.gameOver(true);
    }
    
    // The match was unable to be established with any players due to an error.
    func match(theMatch: GKMatch, didFailWithError error: NSError?) {
        
        if (error != nil) {
            NSLog("Match failed with error: %@", error!);
        }
        
        if (self.match != theMatch) { return; }
        
        self.matchStarted = false;
        
        Game.sharedInstance.gameOver(true);
    }
    
    func sendData(data: NSData)  {
    
        if (self.match != nil) {
            do {
                try self.match!.sendDataToAllPlayers(data, withDataMode:GKMatchSendDataMode.Unreliable);
            }
            catch let error as NSError {
                NSLog("%@", error);
            }
        }
    }
    
    func sendReliableData(data: NSData)  {
        if (self.match != nil) {
            do {
                try self.match!.sendDataToAllPlayers(data, withDataMode: GKMatchSendDataMode.Reliable);
            }
            catch let error as NSError {
                NSLog("%@", error);
            }
        }
    }
    
    func authenticateLocalUser(appDelegate: AppDelegate, gameCenterDelegate: GameCenterProtocol)  {
        
        self.delegate = gameCenterDelegate;
        
        if(self.userAuthenticated)
        {
            self.findMatchWithViewController(appDelegate.window!.rootViewController);
            return;
        }
        
        // Gamekit login for ios 6
        GKLocalPlayer.localPlayer().authenticateHandler = { (viewcontroller: UIViewController?, error: NSError?) in
            if (error != nil) {
                NSLog("authenticateLocalUser: %@", error!);
            }
            
            if (appDelegate.window!.rootViewController != nil && viewcontroller != nil) {
                appDelegate.window!.rootViewController!.presentViewController(viewcontroller!, animated:true, completion:nil);
            }
            else if (GKLocalPlayer.localPlayer().authenticated)
            {
                self.userAuthenticated = true;
                self.findMatchWithViewController(appDelegate.window!.rootViewController);
            }
        };
        
    }

}

