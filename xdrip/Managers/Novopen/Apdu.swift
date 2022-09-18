//
//  Apdu.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 27/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Apdu {

    enum ApduType : UInt16, CaseIterable {
        case Aarq = 0xE200
        case Aare = 0xE300
        case Rlrq = 0xE400
        case Rlre = 0xE500
        case Abrt = 0xE600
        case Prst = 0xE700
        case Invalid  = 0x0000
        
        static func findByValue(val : UInt16) -> ApduType {
            for a in ApduType.allCases {
                if (a.rawValue == val) {
                    return a
                }
            }
            return ApduType.Invalid
        }
        
        var description: String {
            return String(describing: self)
        }
    }
    
    private var aType : ApduType
    private var payloadData : Data
    
    public init() {
        aType = ApduType.Invalid
        payloadData = Data()
    }
    
    public init( type : ApduType ) {
        aType = type
        payloadData = Data()
    }

    func description() -> String {
        return "[APDU] Value:" + String(format: "%04X", aType.rawValue) + " Type:" + aType.description + " L:" + payloadData.count.description + " Payload:" + payloadData.toHexString()
    }
    
    func payload() -> Data {
        return payloadData
    }

    func isError() -> Bool {
        return (aType == ApduType.Invalid || aType == ApduType.Abrt)
    }
    
    func wantsRelease() -> Bool {
        return (aType == ApduType.Rlrq)
    }
    
    func type() -> ApduType {
        return aType
    }

    func encode(payload : Data) -> Data {
        
        if (aType == ApduType.Invalid) {
            print("NFC : Apdu.encode - Invalid apdu")
            return Data()
        }

        var buf : Data = Data()

        let T : UInt16 = aType.rawValue
        let A1 : UInt8 = UInt8((T >> 8) & 0xFF)
        let A0 : UInt8 = UInt8(T & 0xFF)
        buf.append(contentsOf: [A1, A0])
        
        let L1 : UInt8 = UInt8((payload.count >> 8) & 0xFF)
        let L0 : UInt8 = UInt8(payload.count & 0xFF)
        buf.append(contentsOf: [L1, L0])
        
        buf.append(contentsOf: payload)
        
        return buf
    }
    
    static func parse(data: Data) -> Apdu {

        var index : Int = data.startIndex
        let apdu : Apdu = Apdu()

        if (data.endIndex < (index+1)) {
            print("NFC : Apdu.parse - Invalid data")
            return Apdu()
        }

        let T : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        apdu.aType = ApduType.findByValue(val: T)

        if (apdu.aType == ApduType.Invalid) {
            print("NFC : Apdu.parse - Invalid apdu")
            return Apdu()
        }

        if (data.endIndex < (index+1)) {
            print("NFC : Apdu.parse - Invalid data")
            return Apdu()
        }

        let length : Int = Int(data[index]) * 256 + Int(data[index+1])
        index += 2

        if (length > 0) {
            let nextindex : Int = index + length
        
            if (data.endIndex < nextindex) {
                print("NFC : Apdu.parse - Invalid data")
                return Apdu()
            }

            apdu.payloadData = data[index ..< nextindex]
            index = nextindex
        }
        
        return apdu
    }

}
