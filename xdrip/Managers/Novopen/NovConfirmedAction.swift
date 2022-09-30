//
//  NovConfirmedAction.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 19/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovConfirmedAction {
    
    private var aHandle : UInt16
    private var aType : UInt16
    private var payloadData : Data
    
    public init() {
        aHandle = 0
        aType = 0
        payloadData = Data()
    }
    
    public init(handle: UInt16, type: UInt16) {
        aHandle = handle
        aType = type
        payloadData = Data()
    }

    func description() -> String {
        return "[ACTION] handle:" + String(format: "%04X", aHandle) + " type:" + String(format: "%04X", aType) + " payload:" + payloadData.toHexString()
    }
    
    func type() -> UInt16 {
        return aType
    }
    
    func payload() -> Data {
        return payloadData
    }
    
    func encode_all_segments() -> Data {
        
        var buf : Data = Data()

        let H1 : UInt8 = UInt8((aHandle >> 8) & 0xFF)
        let H0 : UInt8 = UInt8(aHandle & 0xFF)
        buf.append(contentsOf: [H1, H0])

        let T1 : UInt8 = UInt8((aType >> 8) & 0xFF)
        let T0 : UInt8 = UInt8(aType & 0xFF)
        buf.append(contentsOf: [T1, T0])

        buf.append(contentsOf: [0x00, 0x06])
        
        buf.append(contentsOf: [0x00, 0x01, 0x00, 0x02, 0x00 ,0x00])

        return buf
    }
    
    func encode_segment(segment: UInt16) -> Data {
        
        var buf : Data = Data()

        let H1 : UInt8 = UInt8((aHandle >> 8) & 0xFF)
        let H0 : UInt8 = UInt8(aHandle & 0xFF)
        buf.append(contentsOf: [H1, H0])

        let T1 : UInt8 = UInt8((aType >> 8) & 0xFF)
        let T0 : UInt8 = UInt8(aType & 0xFF)
        buf.append(contentsOf: [T1, T0])

        buf.append(contentsOf: [0x00, 0x02])

        let S1 : UInt8 = UInt8((segment >> 8) & 0xFF)
        let S0 : UInt8 = UInt8(segment & 0xFF)
        buf.append(contentsOf: [S1, S0])
        
        return buf
    }

    static func parse(data: Data) -> NovConfirmedAction {
        
        var index : Int = data.startIndex
        let action : NovConfirmedAction = NovConfirmedAction()

        if (data.endIndex < (index+1)) {
            print("NFC : NovConfirmedAction.parse - Invalid data")
            return NovConfirmedAction()
        }

        action.aHandle = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovConfirmedAction.parse - Invalid data")
            return NovConfirmedAction()
        }

        action.aType = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovConfirmedAction.parse - Invalid data")
            return NovConfirmedAction()
        }

        let length : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (length > 0) {

            let nextIndex : Int = index + Int(length)
            
            if (data.endIndex < nextIndex) {
                print("NFC : NovConfirmedAction.parse - Invalid data")
                return NovConfirmedAction()
            }

            action.payloadData = data[ index ..< nextIndex]

            index = nextIndex
        }

        return action
    }
    
}
