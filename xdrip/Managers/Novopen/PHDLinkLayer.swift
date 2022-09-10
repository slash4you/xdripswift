//
//  PHDLinkLayer.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 22/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class PHDLinkLayer
{
    static let MB : UInt8 = 1 << 7
    static let ME : UInt8 = 1 << 6
    static let CF : UInt8 = 1 << 5
    static let SR : UInt8 = 1 << 4
    static let IL : UInt8 = 1 << 3
    static let WELL_KNOWN : UInt8 = 1
    static let DEFAULT_OPCODE : UInt8 = 0xD1

    private var opcode : UInt8
    private var sequences : UInt8
    private var checksum : UInt8
    private var headerData : Data
    private var payloadData : Data
    private var valid : Bool
    
    public init() {
        opcode = 0
        sequences = 0
        checksum = 0
        headerData = Data()
        payloadData = Data()
        valid = false
    }
    
    func description() -> String {
        if (valid) {
            return " [PHDLL] Opcode:" + String(format: "%02X", opcode) + " Header:" + headerData.toHexString() + " Sum:" + String(format: "%02X", checksum) + " Seq:" + String(format: "%02d", sequences) + " Payload:" + payloadData.toHexString() 
        } else {
            return " [PHDLL] Invalid"
        }
    }
    
    private func checkBit( bit : Int ) -> Bool {
        return (((checksum >> bit) & 0x01 ) != 0x00)
    }

    private func setCheckBit( bit : Int ) -> Void {
        checksum |= ( 1 << bit )
    }
    
    func encode() -> Data {
        if (!valid) {
            return Data()
        }
        let pLen : UInt8 = UInt8(payloadData.count)
        let hLen : UInt8 = UInt8(headerData.count)
        let hasHeader : Bool = (hLen > 0)
        let hasPayload : Bool = (pLen > 0)
        var buf : Data = Data()
        buf.append( contentsOf: [ PHDLinkLayer.MB | PHDLinkLayer.ME | PHDLinkLayer.SR | ( hasHeader ? PHDLinkLayer.IL : 0 ) | PHDLinkLayer.WELL_KNOWN ])
        buf.append( contentsOf: [3]) // "PHD".length()
        buf.append( contentsOf: [pLen + 1])
        if (hasHeader) {
            buf.append( contentsOf: [hLen] )
        }
        buf.append( contentsOf: [0x50, 0x48, 0x44] ) // "PHD"
        if (hasHeader) {
            buf.append( headerData )
        }
        buf.append( contentsOf: [ (sequences & 0x0F) | 0x80 | checksum])
        if (hasPayload) {
            buf.append(contentsOf: payloadData)
        }
        return buf
    }
    
    func setOpCode(byte : UInt8) -> Void {
        opcode = byte
    }
    
    func setPayload(buf: Data) -> Void {
        payloadData = buf
    }
    
    func payload() -> Data {
        return payloadData
    }
    
    func setHeader(buf: Data) -> Void {
        headerData = buf
    }
    
    func setChecksum(byte: UInt8) -> Void {
        checksum = byte
    }
    
    func setSeq(byte: UInt8) -> Void {
        sequences = byte
    }
    
    func seq() -> UInt8 {
        return sequences
    }
    
    func enable() -> Void {
        valid = true
    }

    func isValid() -> Bool {
        return valid
    }

    static func parse(data : Data) -> PHDLinkLayer {
                
        var index : Int = data.startIndex
        let phd : PHDLinkLayer = PHDLinkLayer()
        
        // b0 : opcode
        if (data.endIndex < index) {
            print("Invalid data len")
            return PHDLinkLayer()
        }

        let O : UInt8 = data[index]
        phd.setOpCode( byte: O )
        index += 1

        let hasHeader : Bool = ( (O & PHDLinkLayer.IL) != 0x00 )

        // b1 : Type length = "PHD".length() = 3
        if (data.endIndex < index) {
            print("Invalid data len")
            return PHDLinkLayer()
        }

        let T : UInt8 = data[index]
        index += 1

        if (T != 3) {
            print("Invalid type len")
            return PHDLinkLayer()
        }

        // b2 : payload length
        if (data.endIndex < index) {
            print("Invalid data len")
            return PHDLinkLayer()
        }

        var pLen : UInt8 = data[index]
        index += 1

        if (pLen == 0) {
            print("Invalid payload len")
            return PHDLinkLayer()
        }
        
        pLen = pLen - 1
        
        // b3 : header id length
        if (data.endIndex < index) {
            print("Invalid data len")
            return PHDLinkLayer()
        }

        let hLen : UInt8 = data[index]
        if (hasHeader) {
            index += 1
        }
        
        // b4 : "PHD"
        if (data.endIndex < index) {
            print("Invalid data len")
            return PHDLinkLayer()
        }

        let T1 : UInt8 = data[index]
        index += 1

        // b5 : "PHD"
        if (data.endIndex < index) {
            print("Invalid data len")
            return PHDLinkLayer()
        }

        let T2 : UInt8 = data[index]
        index += 1

        // b6 : "PHD"
        if (data.endIndex < index) {
            print("Invalid data len")
            return PHDLinkLayer()
        }

        let T3 : UInt8 = data[index]
        index += 1

        if (T1 != 0x50 || T2 != 0x48 || T3 != 0x44) {
            print("Invalid type")
            return PHDLinkLayer()
        }
        
        // b7..b(7+H) : header id
        if (hasHeader) {
            let nextIndex : Int = index + Int(hLen)
            
            if (data.endIndex < nextIndex) {
                print("Invalid data len")
                return PHDLinkLayer()
            }

            phd.setHeader(buf: data[ index ..< nextIndex ])
            index = nextIndex
        }
        
        // b(8+H) : checksum
        if (data.endIndex < index) {
            print("Invalid data len")
            return PHDLinkLayer()
        }

        let C : UInt8 = data[index]
        phd.setChecksum(byte: C)
        index += 1

        phd.setSeq(byte: (C & 0x0F))

        // b(9+H) : payload
        if (pLen > 0) {
            let nextIndex : Int = index + Int(pLen)

            if (data.endIndex < nextIndex) {
                print("Invalid data len")
                return PHDLinkLayer()
            }

            phd.setPayload(buf: data[ index ..< nextIndex ])
            index = nextIndex
        }
        
        phd.enable()
        
        return phd
    }
}
