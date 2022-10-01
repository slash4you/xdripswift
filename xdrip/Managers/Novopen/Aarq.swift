//
//  Aarq.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 28/08/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Aarq {
    
    private var aProto : UInt16
    private var aVersion : UInt32
    private var aElements : UInt16
    private var apoep : Apoep
    
    public init() {
        aProto = 0
        aVersion = 0
        aElements = 0
        apoep = Apoep()
    }
    
    func description() -> String {
        var log : String = "[AARQ] proto:" + String(format: "%04X", aProto) + " version:" + String(format: "%08X", aVersion) + " elements:" + String(format: "%04X", aElements)
        if isValid() {
            log += " -> " + apoep.description()
        } else {
            log += " -> Invalid"
        }
        return log
    }
    
    func isValid() -> Bool {
        return (aProto == Apoep.APOEP && apoep.id().count == 8)
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

        req.aVersion = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4
        
        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Aarq()
        }

        req.aElements = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("Invalid data len")
            return Aarq()
        }

        let _ : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (req.aElements > 0) {
            for _ in 1 ... req.aElements {
                
                if (data.endIndex < (index+1)) {
                    print("Invalid data len")
                    return Aarq()
                }

                req.aProto = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
                index += 2

                if (data.endIndex < (index+1)) {
                    print("Invalid data len")
                    return Aarq()
                }

                let len : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
                index += 2

                let nextindex = index + Int(len)
                
                if (data.endIndex < nextindex) {
                    print("Invalid data len")
                    return Aarq()
                }

                if (req.aProto == Apoep.APOEP) {
                    req.apoep = Apoep.parse(data: data[ index ..< nextindex ])
                }
                
                index = nextindex
            }
        }
        
        return req
    }
    
    
}
