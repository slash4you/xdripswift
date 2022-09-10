//
//  PHDLinkLayerHelper.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 26/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation
import CoreNFC // SLH

class PHDLinkLayerHelper {

    private var sequence : UInt8
    
    public init() {
        sequence = 0
    }

    func extractInnerPacket(tag : NFCISO7816Tag, bytes : Data) -> Data {
        let phdll : PHDLinkLayer = PHDLinkLayer.parse( data: bytes )
        print("NFC: " + phdll.description())
        if (!phdll.isValid()) {
            print("NFC: extractInnerPacket - invalid phdll")
            return Data()
        }
        if (phdll.seq() != sequence) {
            print("NFC: extractInnerPacket - invalid sequence (expected=" + sequence.description + " but read=" + phdll.seq().description + ")")
            return Data()
        }
        return phdll.payload()
    }
    
    func packInnerPacket(tag : NFCISO7816Tag, bytes: Data) -> Data {
        
        let phdll : PHDLinkLayer = PHDLinkLayer()
        if (sequence < 0x0F) {
            sequence += 1
        } else {
            sequence = 0
        }
        phdll.setSeq(byte: sequence)
        if (sequence < 0x0F) {
            sequence += 1
        } else {
            sequence = 0
        }
        phdll.setPayload(buf: bytes)
        phdll.enable()
        let frame = phdll.encode()
        
        if (frame.count == 0 || frame.count > 0xFD) {
            print("NFC: sendInnerPacket - invalid frame size")
            return Data()
        }
        
        print("NFC: " + PHDLinkLayer.parse(data: frame).description())
        
        // TODO : SLH :  mlcMax vs fragment management
        let len : UInt8 = UInt8(frame.count) + 2
        let dlen : UInt8 = UInt8(frame.count)
        var out : Data = Data()
        out.append(contentsOf: [len])
        out.append(contentsOf: [0x00, dlen])
        out.append(contentsOf: frame)
                
        return out
    }
}

