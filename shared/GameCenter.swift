//
//  GameCenter.swift
//  p0ng
//
//  Created by Ryan Jennings on 2015-07-02.
//  Copyright © 2015 Micrantha Software. All rights reserved.
//

import Foundation
import GameKit

struct GameCenterFlags
{
    static let Fast = (1 << 0)
    static let Normal = (1 << 1)
    static let Slow = (1 << 2)
    static let Match5 = (1 << 3)
    static let Match10 = (1 << 4)
    static let Match15 = (1 << 5)
    static let Match20 = (1 << 6)
    static let Screen320x480 = (1 << 7)
    static let Screen320x568 = (1 << 8)
    static let Screen375x667 = (1 << 9)
    static let Screen414x736 = (1 << 10)
    static let Screen768x1024 = (1 << 11)
    static let Screen1024x1366 = (1 << 12)
}

class GameCenter : NSObject, Multiplayer, GKMatchmakerViewControllerDelegate, GKMatchDelegate
{
    static let ScreenSizes = ["320x480", "320x568", "375x667", "414x736", "768x1024", "1024x1366"]
    
    private(set) var isHosting: Bool
    
    var userAuthenticated: Bool
    var matchStarted: Bool
    var presentingViewController: UIViewController?
    var match: GKMatch?
    var delegate: MultiplayerDelegate?
    
    private override init() {
        
        self.isHosting = false
        self.matchStarted = false
        self.userAuthenticated = false
        self.delegate = nil
        
        super.init()
        
        let nc = NotificationCenter.default
    
        nc.addObserver(self, selector:#selector(GameCenter.authenticationChanged),
            name: .GKPlayerAuthenticationDidChangeNotificationName,
            object:nil)
    }
    
    @objc func authenticationChanged() {
        if GKLocalPlayer.localPlayer().isAuthenticated && !self.userAuthenticated {
            NSLog("Authentication changed: player authenticated.")
            self.userAuthenticated = true
        } else if !GKLocalPlayer.localPlayer().isAuthenticated && self.userAuthenticated {
            NSLog("Authentication changed: player not authenticated")
            self.userAuthenticated = false
        }
    }
    
    func disconnect() {
        self.match?.disconnect()
    }
    
    private func gameSpeedFlags() -> Int {
        var group:Int = 0

        let settings = Settings.sharedInstance
        
        switch settings.speedIndex {
        case GameSpeed.Fast:
            group |= GameCenterFlags.Fast
            break
        case GameSpeed.Normal:
            group |= GameCenterFlags.Normal
            break
        case GameSpeed.Slow:
            group |= GameCenterFlags.Slow
            break
        }
        return group
    }
    
    private func gameMatchFlags() -> Int {
        var group = 0
        
        let settings = Settings.sharedInstance
        
        switch settings.gamePointIndex {
        case GamePointIndex.Min:
            group |= GameCenterFlags.Match5
            break
        case GamePointIndex.Min+1:
            group |= GameCenterFlags.Match10
            break
        case GamePointIndex.Max-1:
            group |= GameCenterFlags.Match15
            break
        case GamePointIndex.Max:
            group |= GameCenterFlags.Match20
            break
        default:
            break
        }
        return group
    }
    
    private func gameScreenFlags() -> Int {
        
        var group = 0
        
        var screenSize = UIScreen.main.bounds.size
        
        screenSize = CGSize(width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
        
        let sizeStr = String(format: "%dx%d", screenSize.width, screenSize.height)
        
        switch GameCenter.ScreenSizes.index(of: sizeStr) {
        case 0:
            group |= GameCenterFlags.Screen320x480
            break
        case 1:
            group |= GameCenterFlags.Screen320x568
            break
        case 2:
            group |= GameCenterFlags.Screen375x667
            break
        case 3:
            group |= GameCenterFlags.Screen414x736
            break
        case 4:
            group |= GameCenterFlags.Screen768x1024
            break
        case 5:
            group |= GameCenterFlags.Screen1024x1366
            break
        default:
            break
        }
        return group
    }
    
    var playerGroup: Int {
        get {
            var group = gameSpeedFlags()
            
            group |= gameMatchFlags()
            
            group |= gameScreenFlags()
            
            return group
        }
    }
    
    func findMatch(forViewController viewController: UIViewController) {
        self.findMatchWithViewController(viewController: viewController)
    }
    
    func findMatchWithViewController(viewController: UIViewController?) {
        
        self.matchStarted = false
        self.isHosting = false
        self.match = nil
        self.presentingViewController = viewController
            
        self.presentingViewController?.dismiss(animated: false, completion:nil)
        
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.playerGroup = self.playerGroup
        
        if let mmvc = GKMatchmakerViewController(matchRequest:request) {
            
            mmvc.matchmakerDelegate = self
            mmvc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            
            print("Finding match on game center...")
            
            self.presentingViewController?.present(mmvc, animated:true, completion:nil)
        }
    }
    
    // The user has cancelled matchmaking
    func matchmakerViewControllerWasCancelled(_ matchmakerViewController: GKMatchmakerViewController) {
        self.presentingViewController?.dismiss(animated: true, completion:nil)
        print("Match was cancelled")
        self.isHosting = false
        self.matchStarted = false
    }
    
    // Matchmaking has failed with an error
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true, completion:nil)
        
        print("Error \(error.localizedDescription)")
        self.isHosting = false
        self.matchStarted = false
    }
    
    // A peer-to-peer match has been found, the game should start
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind theMatch: GKMatch) {
        viewController.dismiss(animated: true, completion:nil)
    
        if self.matchStarted || theMatch.expectedPlayerCount > 0 {
            print("Match found, but not ready")
            return
        }
        
        self.match = theMatch
        theMatch.delegate = self
        
        print("Ready to start match!")
    
        let player = GKLocalPlayer.localPlayer()
        
        self.isHosting = player.playerID == theMatch.players[0].playerID
        
        print("is Hosting? = \(self.isHosting ? "YES" : "NO")")
        
        self.matchStarted = true
        
        self.delegate?.peerFound(self, peer: theMatch.players[0])
        
        Game.shared.newGame(isComputer: false)
    }
    
    // The match received data sent from the player.
    func match(theMatch: GKMatch, didReceiveData data: Data, fromPlayer playerID: String) {
    
        if self.match != theMatch { return; }
    
        if playerID == GKLocalPlayer.localPlayer().playerID {
            return
        }
        
        let type = PacketType.decode(data: data)
        
        switch type {
        case .Paddle, .PaddleMove:
            if let packet = PaddlePacket(data: data) {
                Game.shared.gotPaddlePacket(type: type, packet: packet)
            }
            break
        case .Ball:
            if let packet = BallPacket(data: data) {
                Game.shared.gotBallPacket(packet)
            }
            break
        case .State:
            if let packet = StatePacket(data: data) {
                Game.shared.gotStatePacket(packet)
            }
            break
        case .Ack:
            Game.shared.syncState = GameSync.None
            break
        }
        
        if type.needsAck {
            Game.shared.sendPacket(type: PacketType.Ack)
        }
    }
    
    
    // The player state changed (eg. connected or disconnected)
    func match(theMatch: GKMatch, player playerID: String, didChangeState state:GKPlayerConnectionState) {
        if self.match != theMatch { return; }
    
        switch state {
        case GKPlayerConnectionState.stateConnected:
            
            if self.matchStarted || theMatch.expectedPlayerCount > 0 {
                print("Match found, but already started")
                break
            }
            
            // handle a new player connection.
            print("Player connected, ready to start match!")
            
            let player = GKLocalPlayer.localPlayer()
        
            self.isHosting = player.playerID == theMatch.players[0].playerID
            
            self.matchStarted = true
            
            self.delegate?.peerFound(self, peer: theMatch.players[0])
        
            Game.shared.newGame(isComputer: false)
            
            break
            
        case GKPlayerConnectionState.stateDisconnected:
            // a player just disconnected.
            print("Player disconnected!")
            self.matchStarted = false
            self.delegate?.peerLost(self, peer: theMatch.players[0])
            break
        default:
            break
        }
    }
    
    // The match was unable to connect with the player due to an error.
    func match(theMatch: GKMatch, connectionWithPlayerFailed playerID:String, withError error: NSError) {
        
        print("Failed to connect to player with error: \(error)")
        
        if self.match != theMatch { return; }
        
        self.matchStarted = false
        
        Game.shared.gameOver(disconnected: true)
    }
    
    // The match was unable to be established with any players due to an error.
    func match(theMatch: GKMatch, didFailWithError error: NSError?) {
        
        if error != nil {
            print("Match failed with error: \(error.debugDescription)")
        }
        
        if self.match != theMatch { return; }
        
        self.matchStarted = false
        
        Game.shared.gameOver(disconnected: true)
    }
    
    func send(data: Data)  {
        do {
            try self.match?.sendData(toAllPlayers: data, with:GKMatchSendDataMode.unreliable)
        }
        catch let error as NSError {
            print(error)
        }
    }
    
    /**
     * less efficient
     */
    func sendReliable(data: Data)  {
        do {
            try self.match?.sendData(toAllPlayers: data, with: GKMatchSendDataMode.reliable)
        }
        catch let error as NSError {
            print(error)
        }
    }
    
    func authenticateLocalUser(appDelegate: AppDelegate?, gameDelegate: MultiplayerDelegate)  {
        
        self.delegate = gameDelegate
        
        if self.userAuthenticated {
            self.findMatchWithViewController(viewController: appDelegate?.window?.rootViewController)
            return
        }
        
        // Gamekit login for ios 6
        GKLocalPlayer.localPlayer().authenticateHandler = { (viewcontroller: UIViewController?, error: Error?) in
            if error != nil {
                print("authenticateLocalUser: \(error.debugDescription)")
            }
            
            if viewcontroller != nil {
                appDelegate?.window?.rootViewController?.present(viewcontroller!, animated:true, completion:nil)
            } else if GKLocalPlayer.localPlayer().isAuthenticated {
                self.userAuthenticated = true
                self.findMatchWithViewController(viewController: appDelegate?.window?.rootViewController)
            }
        }
    }
}

