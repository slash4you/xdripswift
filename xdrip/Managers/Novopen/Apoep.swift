//
//  Apoep.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 28/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Apoep {

    static let APOEP : UInt16 = 0x5079 // 20601
    static let SYS_TYPE_MANAGER : UInt32 = 0x80000000
    static let SYS_TYPE_AGENT : UInt32 = 0x00800000
    
    private var aVersion : UInt32
    private var aEncoding : UInt16
    private var aNomenclature : UInt32
    private var aFunctional : UInt32
    private var aSystemType : UInt32
    private var aSystemId : Data
    private var aConfigId : UInt16
    private var aRecMode : UInt32
    private var aListCount : UInt16
    private var aListLen : UInt16
    
    public init() {
        aVersion = 0
        aEncoding = 0
        aNomenclature = 0
        aFunctional = 0
        aSystemType = 0
        aSystemId = Data()
        aConfigId = 0
        aRecMode = 0
        aListCount = 0
        aListLen = 0
    }
    
    func description() -> String {
        return "[APOEP] V:" + String(format: "%08X", aVersion) + " E:" + String(format: "%04X", aEncoding) + " N:" + String(format: "%08X", aNomenclature) + " F:" + String(format: "%08X", aFunctional) + " S:" + String(format: "%08X", aSystemType) + " I:" + aSystemId.toHexString() + " C:" + String(format: "%04X", aConfigId) + " R:" + String(format: "%08X", aRecMode) + " O1:" + String(format: "%04X", aListCount) + " O2:" + String(format: "%04X", aListLen)
    }
    
    func id() -> Data {
        return aSystemId
    }
        
    func encode(mode: UInt32, config: UInt16, type: UInt32, ocount: UInt16, olen: UInt16) -> Data {
        var buf : Data = Data()
        
        let V3 : UInt8 = UInt8((aVersion >> 24) & 0xFF)
        let V2 : UInt8 = UInt8((aVersion >> 16) & 0xFF)
        let V1 : UInt8 = UInt8((aVersion >> 8) & 0xFF)
        let V0 : UInt8 = UInt8(aVersion & 0xFF)
        buf.append(contentsOf: [V3, V2, V1, V0])
        
        let E1 : UInt8 = UInt8((aEncoding >> 8) & 0xFF)
        let E0 : UInt8 = UInt8(aEncoding & 0xFF)
        buf.append(contentsOf: [E1, E0])

        let N3 : UInt8 = UInt8((aNomenclature >> 24) & 0xFF)
        let N2 : UInt8 = UInt8((aNomenclature >> 16) & 0xFF)
        let N1 : UInt8 = UInt8((aNomenclature >> 8) & 0xFF)
        let N0 : UInt8 = UInt8(aNomenclature & 0xFF)
        buf.append(contentsOf: [N3, N2, N1, N0])

        let F3 : UInt8 = UInt8((aFunctional >> 24) & 0xFF)
        let F2 : UInt8 = UInt8((aFunctional >> 16) & 0xFF)
        let F1 : UInt8 = UInt8((aFunctional >> 8) & 0xFF)
        let F0 : UInt8 = UInt8(aFunctional & 0xFF)
        buf.append(contentsOf: [F3, F2, F1, F0])

        let S3 : UInt8 = UInt8((type >> 24) & 0xFF)
        let S2 : UInt8 = UInt8((type >> 16) & 0xFF)
        let S1 : UInt8 = UInt8((type >> 8) & 0xFF)
        let S0 : UInt8 = UInt8(type & 0xFF)
        buf.append(contentsOf: [S3, S2, S1, S0])

        let L1 : UInt8 = UInt8((aSystemId.count >> 8) & 0xFF)
        let L0 : UInt8 = UInt8(aSystemId.count & 0xFF)
        buf.append(contentsOf: [L1, L0])

        buf.append(contentsOf: aSystemId)
        
        let C1 : UInt8 = UInt8((config >> 8) & 0xFF)
        let C0 : UInt8 = UInt8(config & 0xFF)
        buf.append(contentsOf: [C1, C0])

        let R3 : UInt8 = UInt8((mode >> 24) & 0xFF)
        let R2 : UInt8 = UInt8((mode >> 16) & 0xFF)
        let R1 : UInt8 = UInt8((mode >> 8) & 0xFF)
        let R0 : UInt8 = UInt8(mode & 0xFF)
        buf.append(contentsOf: [R3, R2, R1, R0])

        let OC1 : UInt8 = UInt8((ocount >> 8) & 0xFF)
        let OC0 : UInt8 = UInt8(ocount & 0xFF)
        buf.append(contentsOf: [OC1, OC0])

        let OL1 : UInt8 = UInt8((olen >> 8) & 0xFF)
        let OL0 : UInt8 = UInt8(olen & 0xFF)
        buf.append(contentsOf: [OL1, OL0])

        return buf
    }

    
    static func parse(data: Data) -> Apoep {
        
        var index : Int = data.startIndex
        let apoep : Apoep = Apoep()

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aVersion = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aEncoding = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aNomenclature = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aFunctional = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aSystemType = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4

        
        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        let len : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        let nextindex : Int = index + Int(len)
        if (data.endIndex < nextindex) {
            print("Invalid data len")
            return Apoep()
        }
        
        apoep.aSystemId = data[ index ..< nextindex ]
        index = nextindex
        
        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aConfigId = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aRecMode = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aListCount = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.aListLen = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        return apoep
    }
    
}
