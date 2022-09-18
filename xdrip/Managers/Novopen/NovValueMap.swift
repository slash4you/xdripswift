//
//  NovValueMap.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 11/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovValueMap {

    public struct Entry {
        var type : UInt16
        var tcount : UInt16
    }
    
    private var list : [Entry]
    
    public init() {
        list = [Entry]()
    }
    
    func description() -> String {
        var log : String = "["
        for e in list {
            log = log + "(" + String(format: "%04X", e.type) + "," + String(format: "%04X", e.tcount) + ") "
        }
        log = log + "]"
        return log
    }
    
    static func parse(data : Data) -> NovValueMap {
        var index : Int = data.startIndex
        let map : NovValueMap = NovValueMap()

        if (data.endIndex < (index+1)) {
            print("NFC : NovValueMap.parse - Invalid data")
            return NovValueMap()
        }

        let count : UInt16 = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovValueMap.parse - Invalid data")
            return NovValueMap()
        }

        let _ : UInt16 = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (count > 0) {
            for _ in 1 ... count {

                if (data.endIndex < (index+1)) {
                    print("NFC : NovValueMap.parse - Invalid data")
                    return NovValueMap()
                }

                let type : UInt16 = UInt16(data[index])*256 + UInt16(data[index+1])
                index += 2

                if (data.endIndex < (index+1)) {
                    print("NFC : NovValueMap.parse - Invalid data")
                    return NovValueMap()
                }

                let tcount : UInt16 = UInt16(data[index])*256 + UInt16(data[index+1])
                index += 2

                map.list.append( Entry(type: type, tcount: tcount ) )

            }
        }


        return map
    }
    
}
