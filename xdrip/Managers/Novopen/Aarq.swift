//
//  Aarq.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 28/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Aarq {
    
    private var proto : UInt16
    private var version : UInt32
    private var elements : UInt16
    private var apoep : Apoep
    
    public init() {
        proto = 0
        version = 0
        elements = 0
        apoep = Apoep()
    }
    
    func description() -> String {
        var log : String = "[AARQ] proto:" + String(format: "%04X", proto) + " version:" + String(format: "%08X", version) + " elements:" + String(format: "%04X", elements)
        if isValid() {
            log += " -> " + apoep.description()
        } else {
            log += " -> Invalid"
        }
        return log
    }
    
    func isValid() -> Bool {
        return (proto == Apoep.APOEP && apoep.id().count == 8)
    }

    func payload() -> Apoep {
        return apoep
    }
    
    static func parse(data: Data) -> Aarq {
        
        var index : Int = data.startIndex
        let req : Aarq = Aarq()
        
        if (data.endIndex < (index+3)) {
            print("Invalid data len")
            return Aarq()
        }

        req.version = UInt32(data[index]) << 24 + UInt32(data[index+1]) << 16 + UInt32(data[index+2]) << 8 + UInt32(data[index+3])
        index += 4
        
        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Aarq()
        }

        req.elements = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Aarq()
        }

        let _ = UInt16(data[index]) << 8 + UInt16(data[index+1])
        index += 2

        if (req.elements > 0) {
            for _ in 1 ... req.elements {
                
                if (data.endIndex < (index+1)) {
                    print("Invalid data len")
                    return Aarq()
                }

                req.proto = UInt16(data[index]) << 8 + UInt16(data[index+1])
                index += 2

                if (data.endIndex < (index+1)) {
                    print("Invalid data len")
                    return Aarq()
                }

                let len = UInt16(data[index]) << 8 + UInt16(data[index+1])
                index += 2

                let nextindex = index + Int(len)
                
                if (data.endIndex < nextindex) {
                    print("Invalid data len")
                    return Aarq()
                }

                if (req.proto == Apoep.APOEP) {
                    req.apoep = Apoep.parse(data: data[ index ..< nextindex ])
                }
                
                index = nextindex
            }
        }
        
        return req
    }
    
    
}
