//
//  NovRelativeTime.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 18/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovRelativeTime {
 
    private var aRelativeTime : UInt32
    private var aAbsoluteTime : Date
    
    public init() {
        aRelativeTime = 0
        aAbsoluteTime = Date(timeIntervalSince1970: 0)
    }
    
    func description() -> String {
        return "[TIME] relative:" + String(format: "%08X", aRelativeTime) + " absolute:" + aAbsoluteTime.description
    }
    
    func relative() -> UInt32 {
        return aRelativeTime
    }
    
    func absolute() -> Date {
        return aAbsoluteTime
    }
    
    static func parse(data: Data) -> NovRelativeTime {
        var index : Int = data.startIndex
        let time : NovRelativeTime = NovRelativeTime()

        if (data.endIndex < (index+3)) {
            print("NFC : NovRelativeTime.parse - Invalid data")
            return NovRelativeTime()
        }

        time.aRelativeTime = UInt32(data[index]) << 24 + UInt32(data[index+1]) << 16 + UInt32(data[index+2]) << 8 + UInt32(data[index+3])
        index += 4

        time.aAbsoluteTime = Date()

        return time
    }
    
}
