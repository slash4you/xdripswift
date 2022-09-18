//
//  NovInsulinDose.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 11/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovInsulinDose {

    static let MAX_UNIT_VALUE : Double = 60.0
    
    private var relativeTime : TimeInterval
    private var absoluteTime : Date
    private var units : Double
    private var flags : UInt32
    
    public init() {
        relativeTime = 0.0
        absoluteTime = Date(timeIntervalSince1970: 0.0)
        units = -1.0
        flags = 0
    }

    func description() -> String {
        return "[DOSE] valid:" + isValid().description + " time:" + absoluteTime.description + " units:" + units.description + " flags:" + String(format:"%08X",flags)
    }
    
    func isValid() -> Bool {
        return ((units > 0.0) && (units <= NovInsulinDose.MAX_UNIT_VALUE) && (absoluteTime.timeIntervalSinceNow < 0.0) && (fabs(absoluteTime.timeIntervalSinceNow) < ( 60.0 * 60.0 * 24.0 * 365.0 )))
    }
    
    static func parse(data: Data, time: TimeInterval) -> NovInsulinDose {
        var index : Int = data.startIndex
        let dose : NovInsulinDose = NovInsulinDose()

        if (data.endIndex < (index+3)) {
            print("NFC : NovInsulinDose.parse - Invalid data")
            return NovInsulinDose()
        }

        let T : UInt32 = (UInt32(data[index]) << 24) + (UInt32(data[index+1]) << 16) + (UInt32(data[index+2]) << 8) + UInt32(data[index+3])
        index += 4

        dose.relativeTime = TimeInterval(T)
        dose.absoluteTime = Date(timeIntervalSinceNow: ( dose.relativeTime - time ))
        
        if (data.endIndex < (index+3)) {
            print("NFC : NovInsulinDose.parse - Invalid data")
            return NovInsulinDose()
        }

        let unit : UInt32 = (UInt32(data[index]) << 24) + (UInt32(data[index+1]) << 16) + (UInt32(data[index+2]) << 8) + UInt32(data[index+3])
        index += 4
        
        if ((unit & 0xFFFF0000) == 0xFF000000) {
            dose.units = Double(unit & 0x0000FFFF) / 10.0
            if (dose.units > MAX_UNIT_VALUE) {
                dose.units = -1.0
            }
        } else {
            dose.units = -1.0
        }

        if (data.endIndex < (index+3)) {
            print("NFC : NovInsulinDose.parse - Invalid data")
            return NovInsulinDose()
        }

        dose.flags = (UInt32(data[index]) << 24) + (UInt32(data[index+1]) << 16) + (UInt32(data[index+2]) << 8) + UInt32(data[index+3])
        index += 4

        return dose
    }
    
}
