//
//  Dpdu.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 27/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Dpdu {

    private var dInvokeId : UInt16
    private var dChoice : UInt16
    private var payloadData : Data

    public init()
    {
        dInvokeId = 0
        dChoice = 0
        payloadData = Data()
    }
   
    public init(invokeId : UInt16, choice : UInt16)
    {
        dInvokeId = invokeId
        dChoice = choice
        payloadData = Data()
    }

    func description() -> String {
        return "[DPDU] invokeId:" + String(format: "%04X", dInvokeId) + " Choice:" + String(format: "%04X", dChoice) + " L:" + payloadData.count.description + " Payload:" + payloadData.toHexString()
    }
    
    func payload() -> Data {
        return payloadData
    }
    
    func choice() -> UInt16 {
        return dChoice
    }
    
    func invokeId() -> UInt16 {
        return dInvokeId
    }
    
    static func parse(data: Data) -> Dpdu {
        var index : Int = data.startIndex
        let apdu : Dpdu = Dpdu()
        
        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        let _ = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.dInvokeId = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.dChoice = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        let length : Int = Int(data[index])*256 + Int(data[index+1])
        index += 2

        if (length > 0) {
            let nextindex : Int = index + length
        
            if (data.endIndex < nextindex) {
                print("NFC : Dpdu.parse - Invalid data")
                return Dpdu()
            }

            apdu.payloadData = data[index ..< nextindex]
            index = nextindex
        }
        
        return apdu
    }
    
    func encode(payload: Data) -> Data {
        var buf : Data = Data()
        
        let len : UInt16 = UInt16(payload.count + 6)
        let H1 : UInt8 = UInt8((len >> 8) & 0xFF)
        let H0 : UInt8 = UInt8(len & 0xFF)
        buf.append(contentsOf: [H1, H0])

        let I1 : UInt8 = UInt8((dInvokeId >> 8) & 0xFF)
        let I0 : UInt8 = UInt8(dInvokeId & 0xFF)
        buf.append(contentsOf: [I1, I0])

        let C1 : UInt8 = UInt8((dChoice >> 8) & 0xFF)
        let C0 : UInt8 = UInt8(dChoice & 0xFF)
        buf.append(contentsOf: [C1, C0])

        let L1 : UInt8 = UInt8((payload.count >> 8) & 0xFF)
        let L0 : UInt8 = UInt8(payload.count & 0xFF)
        buf.append(contentsOf: [L1, L0])

        buf.append(contentsOf: payload)
        
        return buf
    }
    
    
}
