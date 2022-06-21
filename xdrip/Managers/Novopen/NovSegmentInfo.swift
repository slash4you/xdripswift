//
//  NovSegmentInfo.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 20/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovSegmentInfo {
    
    private var aInstNum : UInt16
    private var aUsage : Int32
    private var aMap : NovSegmentMap

    public init() {
        aInstNum = 0
        aUsage = -1
        aMap = NovSegmentMap()
    }
    
    func description() -> String {
        return "[SEG_INFO] valid:" + isValid().description + " instnum:" + String(format: "%04X", aInstNum) + " usage:" + String(format: "%04X", aUsage) + " map:" + aMap.description()
    }

    func isValid() -> Bool {
        return (aUsage >= 0) && aMap.isValid()
    }
        
    func instnum() -> UInt16 {
        return aInstNum
    }
    
    func usage() -> Int32 {
        return aUsage
    }

    static func parse(data: Data) -> NovSegmentInfo {
        
        var index : Int = data.startIndex
        let info : NovSegmentInfo = NovSegmentInfo()

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentInfo.parse - Invalid data")
            return NovSegmentInfo()
        }

        info.aInstNum = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentInfo.parse - Invalid data")
            return NovSegmentInfo()
        }

        let acount : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentInfo.parse - Invalid data")
            return NovSegmentInfo()
        }

        let _ : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (acount > 0) {
            for _ in 1 ... acount {
                
                if (data.endIndex < (index+3)) {
                    print("NFC : NovSegmentInfo.parse - Invalid data")
                    return NovSegmentInfo()
                }

                let attrlen : UInt16 = UInt16(data[index+2])*256 + UInt16(data[index+3])
                let nextIndex : Int = index + 4 + Int(attrlen)
                
                if (data.endIndex < nextIndex) {
                    print("NFC : NovSegmentInfo.parse - Invalid data")
                    return NovSegmentInfo()
                }

                let attr : NovAttribute = NovAttribute.parse(data: data[index ..< nextIndex])
                index = nextIndex

                switch (attr.kind()) {
                    
                case .MDC_ATTR_PM_SEG_MAP:
                    info.aMap = NovSegmentMap.parse( data: attr.bytes() )
                    break

                case .MDC_ATTR_SEG_USAGE_CNT:
                    info.aUsage = attr.value()
                    break

                case .MDC_ATTR_INVALID:
                    print("NFC : NovEventInfo.parse - Invalid data")
                    return NovSegmentInfo()
                    
                default:
                    break
                }
            }
        }
        
        
        return info
    }
    
}
