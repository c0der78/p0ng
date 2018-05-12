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
        switch(self) {
        case .Ack, .PaddleMove:
            return false
        default:
            return true
        }
    }
    
    static func decode(data: Data) -> PacketType {
        if let coding = NSKeyedUnarchiver.unarchiveObject(with: data) as? Archive {
            return PacketType(rawValue: coding.type) ?? PacketType.State
        }
        return PacketType.State
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: Archive(self))
    }
    
    @objc(PacketType) class Archive : NSObject, NSCoding {
        let type: UInt8
        
        init(_ packet: PacketType) {
            self.type = packet.rawValue
        }
        
        required init?(coder: NSCoder) {
            if let val = coder.decodeObject(forKey: "type") as? NSNumber {
                self.type = val.uint8Value
            } else {
                self.type = 0
            }
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(NSNumber(value: self.type), forKey: "type")
        }
    }
}

//! flags on a packet
struct PacketFlags {
    static var PlayerTurn:UInt8 = (1 << 0)
    static var PlayerOnLeft:UInt8 = (1 << 1)
}

//! a packet
struct StatePacket
{
    var state: GameState
    var playerScore: UInt16
    var opponentScore: UInt16
    var hostingFlags: UInt8
    
    init() {
        self.state = GameState.Paused
        self.playerScore = 0
        self.opponentScore = 0
        self.hostingFlags = 0
    }
    init?(data: Data) {
        guard let archive = NSKeyedUnarchiver.unarchiveObject(with: data) as? Archive else {
            return nil
        }
        self.state = archive.state
        self.playerScore = archive.playerScore
        self.opponentScore = archive.opponentScore
        self.hostingFlags = archive.hostingFlags
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: Archive(self))
    }
    
    @objc(StatePacket) class Archive: NSObject, NSCoding {
        let state: GameState
        let playerScore: UInt16
        let opponentScore: UInt16
        let hostingFlags: UInt8
        
        init(_ packet: StatePacket) {
            self.state = packet.state
            self.playerScore = packet.playerScore
            self.opponentScore = packet.opponentScore
            self.hostingFlags = packet.hostingFlags
        }
        
        required init?(coder aDecoder: NSCoder) {
            guard let state = aDecoder.decodeObject(forKey: "state") as? NSNumber else {
                return nil
            }
            self.state = GameState(rawValue: state.int16Value) ?? GameState.Disconnected
            
            guard let player = aDecoder.decodeObject(forKey: "playerScore") as? NSNumber else {
                return nil
            }
            self.playerScore = player.uint16Value
            
            guard let opponent = aDecoder.decodeObject(forKey: "opponentScore") as? NSNumber else {
                return nil
            }
            self.opponentScore = opponent.uint16Value
            
            guard let flags = aDecoder.decodeObject(forKey: "hostingFlags") as? NSNumber else {
                return nil
            }
            self.hostingFlags = flags.uint8Value
        }
        
        func encode(with aCoder: NSCoder) {
            aCoder.encode(NSNumber( value: self.state.rawValue), forKey: "state")
            aCoder.encode(NSNumber( value: self.playerScore), forKey: "playerScore")
            aCoder.encode(NSNumber( value: self.opponentScore), forKey: "opponentScore")
            aCoder.encode(NSNumber( value: self.hostingFlags), forKey: "hostingFlags")
        }
    }
}

struct BallPacket
{
    var ballX: CGFloat
    var ballY: CGFloat
    var velocityX: CGFloat
    var velocityY: CGFloat
    var screenHeight: CGFloat
    var screenWidth: CGFloat
    var hostingFlags: UInt8
    
    init() {
        self.ballX = 0
        self.ballY = 0
        self.velocityX = 0
        self.velocityY = 0
        self.screenHeight = UIScreen.main.bounds.height
        self.screenWidth = UIScreen.main.bounds.width
        self.hostingFlags = 0
    }
    
    init?(data: Data) {
        guard let archive = NSKeyedUnarchiver.unarchiveObject(with: data) as? Archive else {
            return nil
        }
        self.ballX = archive.ballX
        self.ballY = archive.ballY
        self.velocityX = archive.velocityX
        self.velocityY = archive.velocityY
        self.screenHeight = archive.screenHeight
        self.screenWidth = archive.screenWidth
        self.hostingFlags = archive.hostingFlags
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: Archive(self))
    }
    
    @objc(BallPacket) class Archive: NSObject, NSCoding {
        let ballX: CGFloat
        let ballY: CGFloat
        let velocityX: CGFloat
        let velocityY: CGFloat
        let screenHeight: CGFloat
        let screenWidth: CGFloat
        let hostingFlags: UInt8
        
        init(_ packet: BallPacket) {
            self.ballX = packet.ballX
            self.ballY = packet.ballY
            self.velocityY = packet.velocityY
            self.velocityX = packet.velocityX
            self.screenWidth = packet.screenWidth
            self.screenHeight = packet.screenHeight
            self.hostingFlags = packet.hostingFlags
        }
        
        required init?(coder aDecoder: NSCoder) {
            self.ballX = CGFloat(aDecoder.decodeFloat(forKey: "ballX"))
            self.ballY = CGFloat(aDecoder.decodeFloat(forKey: "ballY"))
            self.velocityX = CGFloat(aDecoder.decodeFloat(forKey: "velocityX"))
            self.velocityY = CGFloat(aDecoder.decodeFloat(forKey: "velocityY"))
            self.screenHeight = CGFloat(aDecoder.decodeFloat(forKey: "screenHeight"))
            self.screenWidth = CGFloat(aDecoder.decodeFloat(forKey: "screenWidth"))
            if let flags = aDecoder.decodeObject(forKey: "hostingFlags") as? NSNumber {
                self.hostingFlags = flags.uint8Value
            } else {
                self.hostingFlags = 0
            }
        }
        
        func encode(with aCoder: NSCoder) {
            aCoder.encode(Float(self.ballX), forKey: "ballX")
            aCoder.encode(Float(self.ballY), forKey: "ballY")
            aCoder.encode(Float(self.velocityX), forKey: "velocityX")
            aCoder.encode(Float(self.velocityY), forKey: "velocityY")
            aCoder.encode(Float(self.screenHeight), forKey: "screenHeight")
            aCoder.encode(Float(self.screenWidth), forKey: "screenWidth")
            aCoder.encode(NSNumber(value: self.hostingFlags), forKey: "hostingFlags")
        }
    }
}

struct PaddlePacket
{
    var paddleY: CGFloat
    var screenWidth: CGFloat
    
    init() {
        self.paddleY = 0
        self.screenWidth = UIScreen.main.bounds.width
    }
    
    init?(data: Data) {
        guard let coding = NSKeyedUnarchiver.unarchiveObject(with: data) as? Archive else {
            return nil
        }
        self.paddleY = coding.paddleY
        self.screenWidth = coding.screenWidth
    }
    
    func asData() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: Archive(self))
    }
    
    @objc(PaddlePacket) class Archive: NSObject, NSCoding {
        let paddleY: CGFloat
        let screenWidth: CGFloat
        
        init(_ packet: PaddlePacket) {
            self.paddleY = packet.paddleY
            self.screenWidth = packet.screenWidth
        }
        
        required init?(coder: NSCoder) {
            self.paddleY = CGFloat(coder.decodeFloat(forKey: "paddleY"))
            self.screenWidth = CGFloat(coder.decodeFloat(forKey: "screenWidth"))
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(Float(self.paddleY), forKey: "paddleY")
            coder.encode(Float(self.screenWidth), forKey: "screenWidth")
        }
    }
}
