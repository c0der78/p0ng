//
//  Multiplayer.swift
//  p0ng
//
//  Created by Ryan Jennings on 2018-05-12.
//  Copyright © 2018 micrantha software. All rights reserved.
//

import UIKit

protocol Multiplayer {
    var delegate: MultiplayerDelegate? {
        get set
    }
    func findMatch(forViewController viewController: UIViewController)
    func disconnect();
    func send(data: Data)
    func sendReliable(data: Data)
}

protocol MultiplayerDelegate {
    func peerFound(_ multiplayer: Multiplayer, peer: NSObject)
    
    func peerLost(_ multiplayer: Multiplayer, peer: NSObject)
}
