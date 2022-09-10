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
    
    private var at : UInt16
    private var kind : ApduType
    private var choiceLen : UInt16
    private var choiceData : Data
    
    public init() {
        at = 0
        kind = ApduType.Invalid
        choiceLen = 0
        choiceData = Data()
    }
    
    public init( type : ApduType ) {
        at = type.rawValue
        kind = type
        choiceLen = 0
        choiceData = Data()
    }

    func description() -> String {
        return "[APDU] AT:" + String(format: "%04X", at) + " T:" + kind.description + " L:" + String(format: "%04X", choiceLen) + " P:" + choiceData.toHexString()
    }
    
    func payload() -> Data {
        return choiceData
    }
    
    func encode(payload : Data) -> Data {
        
        if (at == 0 || kind == ApduType.Invalid) {
            print("NFC : Apdu.encode - Invalid apdu")
            return Data()
        }

        var buf : Data = Data()

        let A1 : UInt8 = UInt8((at >> 8) & 0xFF)
        let A0 : UInt8 = UInt8(at & 0xFF)
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

        apdu.at = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        apdu.kind = ApduType.findByValue(val: apdu.at)

        if (apdu.kind == ApduType.Invalid) {
            print("NFC : Apdu.parse - Invalid apdu")
            return Apdu()
        }

        if (data.endIndex < (index+1)) {
            print("NFC : Apdu.parse - Invalid data")
            return Apdu()
        }

        // TODO : SLH : valider si choicelen vaut data.endIndex
        apdu.choiceLen = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        if (apdu.choiceLen == 0) {
            print("NFC : Apdu.parse - Invalid data")
            return Apdu()
        }

        let nextindex : Int = index + Int(apdu.choiceLen)
        
        if (data.endIndex < nextindex) {
            print("NFC : Apdu.parse - Invalid data")
            return Apdu()
        }

        apdu.choiceData = data[index ..< nextindex]
        index = nextindex
        
        return apdu
    }

    func isError() -> Bool {
        return (kind == ApduType.Invalid || kind == ApduType.Abrt)
    }
    
    func wantsRelease() -> Bool {
        return (kind == ApduType.Rlrq)
    }
    
    func type() -> ApduType {
        return kind
    }
}
