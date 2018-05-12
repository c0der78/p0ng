//
//  NearbyServiceManager.swift
//  p0ng
//
//  Created by Ryan Jennings on 2018-05-11.
//  Copyright © 2018 Micrantha Software. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class NearbyServiceManager: NSObject {
    private static let ServiceType = "p0ng"
    
    private let peerId: MCPeerID
    private let assistant : MCAdvertiserAssistant
    private let browser: MCBrowserViewController
    private let session: MCSession
    
    override init() {
        self.peerId = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: self.peerId)
        self.browser = MCBrowserViewController(serviceType: NearbyServiceManager.ServiceType, session: self.session)
        self.assistant = MCAdvertiserAssistant(serviceType: NearbyServiceManager.ServiceType, discoveryInfo: nil, session: self.session)
        super.init()
    }
    
    func start() {
        self.assistant.start()
    }
    
    func stop() {
        self.assistant.stop()
    }
    
    var browserDelegate: MCBrowserViewControllerDelegate? {
        set(value) {
            self.browser.delegate = value
        }
        get {
            return self.browser.delegate
        }
    }

    var sessionDelegate: MCSessionDelegate? {
        set(value) {
            self.session.delegate = value
        }
        get {
            return self.session.delegate
        }
    }
}
