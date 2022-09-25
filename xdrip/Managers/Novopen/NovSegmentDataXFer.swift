//
//  NovSegmentDataXFer.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 24/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovSegmentDataXFer {
    
    private var aSegmentId : UInt16
    private var aResponseCode : UInt16
    
    public init() {
        aSegmentId = 0
        aResponseCode = 0
    }
    
    func description() -> String {
        return "[XFER] segmentId:" + String(format: "%04X", aSegmentId) + " code:" + String(format: "%04X", aResponseCode)
    }
    
    func isValid() -> Bool {
        return (aSegmentId > 0) && (aResponseCode == 0)
    }
    
    func encode() -> Data {
        var buf : Data = Data()
        
        let S1 : UInt8 = UInt8( (aSegmentId >> 8) & 0xFF )
        let S0 : UInt8 = UInt8( aSegmentId & 0xFF )
        buf.append(contentsOf: [S1, S0])

        let C1 : UInt8 = UInt8( (aResponseCode >> 8) & 0xFF )
        let C0 : UInt8 = UInt8( aResponseCode & 0xFF )
        buf.append(contentsOf: [C1, C0])

        return buf
    }
    
    static func parse(data: Data) -> NovSegmentDataXFer {
        
        var index : Int = data.startIndex
        let xfer : NovSegmentDataXFer = NovSegmentDataXFer()

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentDataXFer.parse - Invalid data")
            return NovSegmentDataXFer()
        }

        xfer.aSegmentId = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentDataXFer.parse - Invalid data")
            return NovSegmentDataXFer()
        }

        xfer.aResponseCode = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        return xfer
    }
    
}
