//
//  NearbyServiceManager.swift
//  p0ng
//
//  Created by Ryan Jennings on 2018-05-11.
//  Copyright © 2018 Micrantha Software. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class NearbyServiceManager: NSObject, Multiplayer, MCSessionDelegate {

    private static let ServiceType = "p0ng"
    
    private let peerId: MCPeerID
    private let session: MCSession
    private let assistant: MCAdvertiserAssistant
    let browser: MCBrowserViewController
    
    var delegate: MultiplayerDelegate?
    
    override init() {
        self.peerId = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: self.peerId)
        self.assistant = MCAdvertiserAssistant(serviceType: NearbyServiceManager.ServiceType, discoveryInfo: nil, session: self.session)
        self.browser = MCBrowserViewController(serviceType: NearbyServiceManager.ServiceType, session: self.session)
        super.init()
        self.session.delegate = self
    }
    
    deinit {
        self.assistant.stop()
    }
    
    func findMatch(forViewController viewController: UIViewController) {
        
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: { (alert: UIAlertAction)->Void in
            print("Starting multipeer hosting")
            self.assistant.start()
            self.notifyHosting(viewController)
        }))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: { (alert: UIAlertAction)->Void in
            print("Starting multipeer join")
            viewController.present(self.browser, animated: true)
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController.present(ac, animated: true)
    }
    
    private func notifyHosting(_ viewController: UIViewController) {
        let ac = UIAlertController(title: "Hosting Game", message: nil, preferredStyle: .alert)
        ac.message = "Started hosting a game, please wait for other players to join."
        viewController.present(ac, animated: true)
        self.perform(#selector(dismissNotification), with: ac, afterDelay: 2)
    }
    
    @objc private func dismissNotification(alert: UIAlertController) {
        alert.dismiss(animated: true, completion: nil)
    }
    
    func disconnect() {
        self.assistant.stop();
    }
    
    func send(_ data: Data, mode: MCSessionSendDataMode = .unreliable) {
        
        if self.session.connectedPeers.isEmpty {
            return
        }
        
        do {
            try self.session.send(data, toPeers: self.session.connectedPeers, with: mode)
        } catch let error {
            print(error)
        }
    }
    
    func send(data: Data) {
        self.send(data, mode: .unreliable)
    }
    
    func sendReliable(data: Data) {
        self.send(data, mode: .reliable)
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            if self.browser.isViewLoaded {
                self.browser.dismiss(animated: true)
            }
            self.delegate?.peerFound(self, peer: peerID)
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            self.delegate?.peerLost(self, peer: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
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

    // Received a byte stream from remote peer.
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    // Start receiving a resource from remote peer.
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
