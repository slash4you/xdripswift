//
//  Aare.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 01/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Aare {
    
    private var result : UInt16
    private var proto : UInt16
    private var apoep : Apoep
    
    public init()
    {
        result = 0
        proto = 0
        apoep = Apoep()
    }

    public init(res: UInt16, pro: UInt16, a : Apoep)
    {
        result = res
        proto = pro
        apoep = a
    }
    
    func description() -> String {
        return "[AARE] result:" + String(format: "%04X", result) + " proto:" + String(format: "%04X", proto) + "  -> " + apoep.description()
    }
    
    func isValid() -> Bool {
        return (proto == Apoep.APOEP && apoep.id().count == 8)
    }

    func payload() -> Apoep {
        return apoep
    }

    func encode() -> Data {
        var buf : Data = Data()

        let R1 : UInt8 = UInt8((result >> 8) & 0xFF)
        let R0 : UInt8 = UInt8(result & 0xFF)
        buf.append(contentsOf: [R1, R0])

        let P1 : UInt8 = UInt8((proto >> 8) & 0xFF)
        let P0 : UInt8 = UInt8(proto & 0xFF)
        buf.append(contentsOf: [P1, P0])

        let payload : Data = apoep.encode(mode: 0, config: 0, type: Apoep.SYS_TYPE_MANAGER, ocount: 0, olen: 0)
        
        let L1 : UInt8 = UInt8((payload.count >> 8) & 0xFF)
        let L0 : UInt8 = UInt8(payload.count & 0xFF)
        buf.append(contentsOf: [L1, L0])

        buf.append(contentsOf: payload)
        
        return buf
    }
    
    static func parse(data: Data) -> Aare {

        var index : Int = data.startIndex
        let response : Aare = Aare()
        
        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Aare()
        }

        response.result = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Aare()
        }

        response.proto = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        if (response.proto == Apoep.APOEP) {
            
            if (data.endIndex < (index+1)) {
                print("Invalid data len")
                return Aare()
            }

            let len = UInt16(data[index]) << 8 + UInt16(data[index+1])
            index += 2

            let nextIndex : Int = index + Int(len)

            if (data.endIndex < nextIndex) {
                print("Invalid data len")
                return Aare()
            }

            response.apoep = Apoep.parse(data: data[ index ..< nextIndex])
        }

        return response
    }
    
}
