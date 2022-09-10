//
//  Dpdu.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 27/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Dpdu {

    private var olen : UInt16
    private var invokeId : UInt16
    private var dchoice : UInt16
    private var payloadLen : UInt16
    private var payloadData : Data

    public init()
    {
        olen = 0
        invokeId = 0
        dchoice = 0
        payloadLen = 0
        payloadData = Data()
    }
    
    func description() -> String {
        return "[DPDU] O:" + String(format: "%04X", olen) + " Id:" + String(format: "%04X", invokeId) + " C:" + String(format: "%04X", dchoice) + " L:" + String(format: "%04X", payloadLen) + " P:" + payloadData.toHexString()
    }
    
    func payload() -> Data {
        return payloadData
    }
    
    static func parse(data: Data) -> Dpdu {
        var index : Int = data.startIndex
        let apdu : Dpdu = Dpdu()
        
        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.olen = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.invokeId = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.dchoice = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.payloadLen = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        let nextindex : Int = index + Int(apdu.payloadLen)
        
        if (data.endIndex < nextindex) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.payloadData = data[index ..< nextindex]
        index = nextindex

        return apdu
    }
    
    func encode(payload: Data) -> Data {
        var buf : Data = Data()
        
        let len : UInt16 = UInt16(payload.count + 8)
        let H1 : UInt8 = UInt8((len >> 8) & 0xFF)
        let H0 : UInt8 = UInt8(len & 0xFF)
        buf.append(contentsOf: [H1, H0])

        let I1 : UInt8 = UInt8((invokeId >> 8) & 0xFF)
        let I0 : UInt8 = UInt8(invokeId & 0xFF)
        buf.append(contentsOf: [I1, I0])

        let C1 : UInt8 = UInt8((dchoice >> 8) & 0xFF)
        let C0 : UInt8 = UInt8(dchoice & 0xFF)
        buf.append(contentsOf: [C1, C0])

        let L1 : UInt8 = UInt8((payload.count >> 8) & 0xFF)
        let L0 : UInt8 = UInt8(payload.count & 0xFF)
        buf.append(contentsOf: [L1, L0])

        buf.append(contentsOf: payload)
        
        return buf
    }
    
    
}
