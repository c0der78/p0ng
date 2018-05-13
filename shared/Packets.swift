//
//  Packets.swift
//  p0ng
//
//  Created by Ryan Jennings on 2018-05-11.
//  Copyright © 2018 Micrantha Software. All rights reserved.
//

import UIKit

//! type of network packet
enum PacketType: UInt8 {
    case State, PaddleMove, Paddle, Ball, Ack
    
    var description : String {
        switch(self) {
        case .State: return "State"
        case .Paddle: return "Paddle"
        case .PaddleMove: return "PaddleMove"
        case .Ball: return "Ball"
        case .Ack: return "Ack"
        }
    }
    
    var needsAck : Bool {
//        switch(self) {
//        case .Ack, .PaddleMove:
//            return false
//        default:
//            return true
//        }
        return false
    }
    
    static func decode(_ archive: NSKeyedUnarchiver) -> PacketType? {
            
        guard let type = archive.decodeObject(forKey: "type") as? UInt8 else {
            return nil
        }
        
        return PacketType(rawValue: type)
    }
    
    func archive() -> NSKeyedArchiver {
        let archive = NSKeyedArchiver()
        archive.encode(self.rawValue, forKey: "type")
        return archive
    }
}

//! flags on a packet
struct PacketFlags {
    static var PlayerTurn:UInt8 = (1 << 0)
    static var PlayerOnLeft:UInt8 = (1 << 1)
}

//! a packet
class StatePacket : NSObject, NSCoding
{
    var state: GameState
    var playerScore: UInt16
    var opponentScore: UInt16
    var hostingFlags: UInt8
    
    override init() {
        self.state = GameState.Paused
        self.playerScore = 0
        self.opponentScore = 0
        self.hostingFlags = 0
    }
    init?(archive: NSKeyedUnarchiver) {
        guard let other = archive.decodeObject() as? StatePacket else {
            return nil
        }
        self.state = other.state
        self.playerScore = other.playerScore
        self.opponentScore = other.opponentScore
        self.hostingFlags = other.hostingFlags
    }
    
    required init?(coder decoder: NSCoder) {
        guard let state = decoder.decodeObject(forKey: "state") as? Int16,
              let player = decoder.decodeObject(forKey: "playerScore") as? UInt16,
              let opponent = decoder.decodeObject(forKey: "opponentScore") as? UInt16,
              let flags = decoder.decodeObject(forKey: "hostingFlags") as? UInt8
        else {
            return nil
        }
        self.state = GameState(rawValue: state) ?? GameState.Disconnected
        self.playerScore = player
        self.opponentScore = opponent
        self.hostingFlags = flags
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.state.rawValue, forKey: "state")
        coder.encode(self.playerScore, forKey: "playerScore")
        coder.encode(self.opponentScore, forKey: "opponentScore")
        coder.encode(self.hostingFlags, forKey: "hostingFlags")
    }
}

class BallPacket : NSObject, NSCoding
{
    var ballX: CGFloat
    var ballY: CGFloat
    var velocityX: CGFloat
    var velocityY: CGFloat
    var screenHeight: CGFloat
    var screenWidth: CGFloat
    var hostingFlags: UInt8
    
    override init() {
        self.ballX = 0
        self.ballY = 0
        self.velocityX = 0
        self.velocityY = 0
        self.screenHeight = UIScreen.main.bounds.height
        self.screenWidth = UIScreen.main.bounds.width
        self.hostingFlags = 0
    }
    
    init?(archive: NSKeyedUnarchiver) {
        guard let other = archive.decodeObject() as? BallPacket else {
            return nil
        }
        self.ballX = other.ballX
        self.ballY = other.ballY
        self.velocityX = other.velocityX
        self.velocityY = other.velocityY
        self.screenHeight = other.screenHeight
        self.screenWidth = other.screenWidth
        self.hostingFlags = other.hostingFlags
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject:self)
    }
    
    required init?(coder decoder: NSCoder) {
        self.ballX = CGFloat(decoder.decodeFloat(forKey: "ballX"))
        self.ballY = CGFloat(decoder.decodeFloat(forKey: "ballY"))
        self.velocityX = CGFloat(decoder.decodeFloat(forKey: "velocityX"))
        self.velocityY = CGFloat(decoder.decodeFloat(forKey: "velocityY"))
        self.screenHeight = CGFloat(decoder.decodeFloat(forKey: "screenHeight"))
        self.screenWidth = CGFloat(decoder.decodeFloat(forKey: "screenWidth"))
        if let flags = decoder.decodeObject(forKey: "hostingFlags") as? UInt8 {
            self.hostingFlags = flags
        } else {
            self.hostingFlags = 0
        }
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(Float(self.ballX), forKey: "ballX")
        coder.encode(Float(self.ballY), forKey: "ballY")
        coder.encode(Float(self.velocityX), forKey: "velocityX")
        coder.encode(Float(self.velocityY), forKey: "velocityY")
        coder.encode(Float(self.screenHeight), forKey: "screenHeight")
        coder.encode(Float(self.screenWidth), forKey: "screenWidth")
        coder.encode(self.hostingFlags, forKey: "hostingFlags")
    }
}

class PaddlePacket : NSObject, NSCoding
{
    var paddleY: CGFloat
    var screenWidth: CGFloat
    
    override init() {
        self.paddleY = 0
        self.screenWidth = UIScreen.main.bounds.width
    }
    
    init?(archive: NSKeyedUnarchiver) {
        guard let other = archive.decodeObject() as? PaddlePacket else {
            return nil
        }
        self.paddleY = other.paddleY
        self.screenWidth = other.screenWidth
    }
    
    required init?(coder decoder: NSCoder) {
        self.paddleY = CGFloat(decoder.decodeFloat(forKey: "paddleY"))
        self.screenWidth = CGFloat(decoder.decodeFloat(forKey: "screenWidth"))
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(Float(self.paddleY), forKey: "paddleY")
        coder.encode(Float(self.screenWidth), forKey: "screenWidth")
    }
}
