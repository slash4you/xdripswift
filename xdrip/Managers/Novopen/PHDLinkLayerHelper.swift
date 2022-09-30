//
//  PHDLinkLayerHelper.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 26/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation
import CoreNFC

class PHDLinkLayerHelper {

    private var seqnum : UInt8
    
    public init() {
        seqnum = 0
    }

    func unpackInnerPacket(tag : NFCISO7816Tag, bytes : Data) -> Data {
        let phdll : PHDLinkLayer = PHDLinkLayer.parse( data: bytes )
        print("NFC: " + phdll.description())
        if (!phdll.isValid()) {
            print("NFC: unpackInnerPacket - invalid phdll")
            return Data()
        }
        if (phdll.seqNum() != seqnum) {
            print("NFC: unpackInnerPacket - invalid sequence (expected=" + seqnum.description + " but read=" + phdll.seqNum().description + ")")
            return Data()
        }
        return phdll.payload()
    }
    
    func packInnerPacket(tag : NFCISO7816Tag, bytes: Data) -> Data {
        
        if (seqnum < 0x0F) {
            seqnum += 1
        } else {
            seqnum = 0
        }
        let phdll : PHDLinkLayer = PHDLinkLayer(seqNum: seqnum)
        if (seqnum < 0x0F) {
            seqnum += 1
        } else {
            seqnum = 0
        }
        let frame = phdll.encode(payload: bytes)
        
        if (frame.count == 0) {
            print("NFC: packInnerPacket - invalid frame size = " + frame.count.description)
            return Data()
        }
        
        print("NFC: " + PHDLinkLayer.parse(data: frame).description())
        
        // TODO : mlcMax vs fragment management
        var out : Data = Data()
        let D1 : UInt8 = UInt8((frame.count >> 8) & 0xFF)
        let D0 : UInt8 = UInt8(frame.count & 0xFF)
        out.append(contentsOf: [D1, D0])
        out.append(contentsOf: frame)
                
        return out
    }
}

