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
    
    private var version : UInt32
    private var encoding : UInt16
    private var nomenclature : UInt32
    private var functional : UInt32
    private var systemtype : UInt32
    private var systemid : Data
    private var configid : UInt16
    private var recmode : UInt32
    private var olistcount : UInt16
    private var olistlen : UInt16
    
    public init() {
        version = 0
        encoding = 0
        nomenclature = 0
        functional = 0
        systemtype = 0
        systemid = Data()
        configid = 0
        recmode = 0
        olistcount = 0
        olistlen = 0
    }
    
    func description() -> String {
        return "[APOEP] V:" + String(format: "%08X", version) + " E:" + String(format: "%04X", encoding) + " N:" + String(format: "%08X", nomenclature) + " F:" + String(format: "%08X", functional) + " S:" + String(format: "%08X", systemtype) + " I:" + systemid.toHexString() + " C:" + String(format: "%04X", configid) + " R:" + String(format: "%08X", recmode) + " O1:" + String(format: "%04X", olistcount) + " O2:" + String(format: "%04X", olistlen)
    }
    
    func id() -> Data {
        return systemid
    }
        
    func encode(mode: UInt32, config: UInt16, type: UInt32, ocount: UInt16, olen: UInt16) -> Data {
        var buf : Data = Data()
        
        let V3 : UInt8 = UInt8((version >> 24) & 0xFF)
        let V2 : UInt8 = UInt8((version >> 16) & 0xFF)
        let V1 : UInt8 = UInt8((version >> 8) & 0xFF)
        let V0 : UInt8 = UInt8(version & 0xFF)
        buf.append(contentsOf: [V3, V2, V1, V0])
        
        let E1 : UInt8 = UInt8((encoding >> 8) & 0xFF)
        let E0 : UInt8 = UInt8(encoding & 0xFF)
        buf.append(contentsOf: [E1, E0])

        let N3 : UInt8 = UInt8((nomenclature >> 24) & 0xFF)
        let N2 : UInt8 = UInt8((nomenclature >> 16) & 0xFF)
        let N1 : UInt8 = UInt8((nomenclature >> 8) & 0xFF)
        let N0 : UInt8 = UInt8(nomenclature & 0xFF)
        buf.append(contentsOf: [N3, N2, N1, N0])

        let F3 : UInt8 = UInt8((functional >> 24) & 0xFF)
        let F2 : UInt8 = UInt8((functional >> 16) & 0xFF)
        let F1 : UInt8 = UInt8((functional >> 8) & 0xFF)
        let F0 : UInt8 = UInt8(functional & 0xFF)
        buf.append(contentsOf: [F3, F2, F1, F0])

        let S3 : UInt8 = UInt8((type >> 24) & 0xFF)
        let S2 : UInt8 = UInt8((type >> 16) & 0xFF)
        let S1 : UInt8 = UInt8((type >> 8) & 0xFF)
        let S0 : UInt8 = UInt8(type & 0xFF)
        buf.append(contentsOf: [S3, S2, S1, S0])

        let L1 : UInt8 = UInt8((systemid.count >> 8) & 0xFF)
        let L0 : UInt8 = UInt8(systemid.count & 0xFF)
        buf.append(contentsOf: [L1, L0])

        buf.append(contentsOf: systemid)
        
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

        apoep.version = UInt32(data[index]) << 24 + UInt32(data[index+1]) << 16 + UInt32(data[index+2]) << 8 + UInt32(data[index+3])
        index += 4

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.encoding = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.nomenclature = UInt32(data[index]) << 24 + UInt32(data[index+1]) << 16 + UInt32(data[index+2]) << 8 + UInt32(data[index+3])
        index += 4

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.functional = UInt32(data[index]) << 24 + UInt32(data[index+1]) << 16 + UInt32(data[index+2]) << 8 + UInt32(data[index+3])
        index += 4

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.systemtype = UInt32(data[index]) << 24 + UInt32(data[index+1]) << 16 + UInt32(data[index+2]) << 8 + UInt32(data[index+3])
        index += 4

        
        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        let len : UInt16 = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        let nextindex : Int = index + Int(len)
        if (data.endIndex < nextindex) {
            print("Invalid data len")
            return Apoep()
        }
        
        apoep.systemid = data[ index ..< nextindex ]
        index = nextindex
        
        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.configid = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.recmode = UInt32(data[index]) << 24 + UInt32(data[index+1]) << 16 + UInt32(data[index+2]) << 8 + UInt32(data[index+3])
        index += 4

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.olistcount = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Apoep()
        }

        apoep.olistlen = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        return apoep
    }
    
}
