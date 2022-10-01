//
//  NovSegmentMap.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 20/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovSegmentMap {
    
    static let MDC_ATTR_NU_VAL_OBS_SIMP : UInt16 = 0x0A56 //2646
    static let MDC_ATTR_ENUM_OBS_VAL_BASIC_BIT_STR : UInt16 = 0x0A66 //2662
    
    private var aBits : UInt16
    private var aEntries : [NovSegmentEntry]
    
    public init() {
        aBits = 0
        aEntries = [NovSegmentEntry]()
    }
    
    func isValid() -> Bool {
        return (aEntries.count == 3 && aEntries[0].isTypical() && aEntries[1].isTypical() && aEntries[2].isTypical() )
    }
    
    func description() -> String {
        var log : String = "[SEG_MAP] bits:" + String(format: "%04X", aBits) + " size:" + aEntries.count.description + " entries: ["
        
        for e in aEntries {
            log += " " + e.description()
        }
        
        log += "]"
        
        return log
    }
    
    static func parse(data: Data) -> NovSegmentMap {
        
        var index : Int = data.startIndex
        let seg : NovSegmentMap = NovSegmentMap()

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentMap.parse - Invalid data")
            return NovSegmentMap()
        }

        seg.aBits = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentMap.parse - Invalid data")
            return NovSegmentMap()
        }

        let acount : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentMap.parse - Invalid data")
            return NovSegmentMap()
        }

        let _ : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (acount > 0) {
            for _ in 1 ... acount {
                
                if (data.endIndex < (index+11)) {
                    print("NFC : NovSegmentMap.parse - Invalid data")
                    return NovSegmentMap()
                }

                let vlen : UInt16 = UInt16(data[index+10]) * 256 + UInt16(data[index+11])
                
                let nextIndex : Int = index + 12 + Int(vlen)
                
                if (data.endIndex < nextIndex) {
                    print("NFC : NovSegmentMap.parse - Invalid data")
                    return NovSegmentMap()
                }

                seg.aEntries.append(NovSegmentEntry.parse(data: data[index ..< nextIndex]))
                
                index = nextIndex
                
            }
        }
        
        return seg
    }
    
}
