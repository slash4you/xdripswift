//
//  Dpdu.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 27/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Dpdu {

    private var aInvokeId : UInt16
    private var aChoice : UInt16
    private var payloadData : Data

    public init()
    {
        aInvokeId = 0
        aChoice = 0
        payloadData = Data()
    }
   
    public init(invokeId : UInt16, choice : UInt16)
    {
        aInvokeId = invokeId
        aChoice = choice
        payloadData = Data()
    }

    func description() -> String {
        return "[DPDU] invokeId:" + String(format: "%04X", aInvokeId) + " Choice:" + String(format: "%04X", aChoice) + " L:" + payloadData.count.description + " Payload:" + payloadData.toHexString()
    }
    
    func payload() -> Data {
        return payloadData
    }
    
    func choice() -> UInt16 {
        return aChoice
    }
    
    func invokeId() -> UInt16 {
        return aInvokeId
    }
    
    static func parse(data: Data) -> Dpdu {
        var index : Int = data.startIndex
        let apdu : Dpdu = Dpdu()
        
        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        let _ : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.aInvokeId = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        apdu.aChoice = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : Dpdu.parse - Invalid data")
            return Dpdu()
        }

        let length : Int = Int(data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped)
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

        let I1 : UInt8 = UInt8((aInvokeId >> 8) & 0xFF)
        let I0 : UInt8 = UInt8(aInvokeId & 0xFF)
        buf.append(contentsOf: [I1, I0])

        let C1 : UInt8 = UInt8((aChoice >> 8) & 0xFF)
        let C0 : UInt8 = UInt8(aChoice & 0xFF)
        buf.append(contentsOf: [C1, C0])

        let L1 : UInt8 = UInt8((payload.count >> 8) & 0xFF)
        let L0 : UInt8 = UInt8(payload.count & 0xFF)
        buf.append(contentsOf: [L1, L0])

        buf.append(contentsOf: payload)
        
        return buf
    }
    
    
}
