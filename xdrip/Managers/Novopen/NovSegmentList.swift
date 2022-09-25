//
//  NovSegmentList.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 20/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovSegmentList {
    
    private var aInfos : [NovSegmentInfo]
    
    public init() {
        aInfos = [NovSegmentInfo]()
    }
        
    func description() -> String {
        if (isValid()) {
            return "[SEG_LIST] info:" + aInfos[0].description()
        } else {
            return "[SEG_LIST] Invalid"
        }
    }
    
    func isValid() -> Bool {
        return (aInfos.count == 1 && aInfos[0].isValid())
    }

    func id() -> UInt16 {
        return aInfos[0].instnum()
    }

    func usage() -> Int32 {
        return aInfos[0].usage()
    }
    
    static func parse(data: Data) -> NovSegmentList {
        
        var index : Int = data.startIndex
        let list : NovSegmentList = NovSegmentList()

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentList.parse - Invalid data 1")
            return NovSegmentList()
        }

        let acount : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentList.parse - Invalid data 2")
            return NovSegmentList()
        }

        let _ : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        if (acount > 0) {
            for _ in 1 ... acount {
                
                if (data.endIndex < (index+5)) {
                    print("NFC : NovSegmentList.parse - Invalid data 3")
                    return NovSegmentList()
                }

                let length : UInt16 = UInt16(data[index+4]) * 256 + UInt16(data[index+5])

                let nextIndex : Int = index + 6 + Int(length)
                
                if (data.endIndex < nextIndex) {
                    print("NFC : NovSegmentList.parse - Invalid data 4")
                    return NovSegmentList()
                }

                list.aInfos.append(NovSegmentInfo.parse(data: data[ index ..< nextIndex]))
                index = nextIndex
                
            }
        }
        
        return list
    }
    
}
