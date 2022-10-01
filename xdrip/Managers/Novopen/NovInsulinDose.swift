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
    
    private var aRelativeTime : TimeInterval
    private var aAbsoluteTime : Date
    private var aUnits : Double
    private var aFlags : UInt32
    
    public init() {
        aRelativeTime = 0.0
        aAbsoluteTime = Date(timeIntervalSince1970: 0.0)
        aUnits = -1.0
        aFlags = 0
    }

    func description() -> String {
        return "[DOSE] valid:" + isValid().description + " time:" + aAbsoluteTime.ISOStringFromDate() + " units:" + aUnits.description + " flags:" + String(format:"%08X",aFlags)
    }
    
    func unit() -> Double {
        return aUnits
    }
    
    func time() -> Date {
        return aAbsoluteTime
    }
    
    func isValid() -> Bool {
        return ((aUnits > 0.0) && (aUnits <= NovInsulinDose.MAX_UNIT_VALUE) && (aAbsoluteTime.timeIntervalSinceNow < 0.0) && (fabs(aAbsoluteTime.timeIntervalSinceNow) < ( 60.0 * 60.0 * 24.0 * 365.0 )))
    }
    
    static func parse(data: Data, time: TimeInterval) -> NovInsulinDose {
        var index : Int = data.startIndex
        let dose : NovInsulinDose = NovInsulinDose()

        if (data.endIndex < (index+3)) {
            print("NFC : NovInsulinDose.parse - Invalid data")
            return NovInsulinDose()
        }

        let T : UInt32 = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4

        dose.aRelativeTime = TimeInterval(T)
        dose.aAbsoluteTime = Date(timeIntervalSinceNow: ( dose.aRelativeTime - time ))
        
        if (data.endIndex < (index+3)) {
            print("NFC : NovInsulinDose.parse - Invalid data")
            return NovInsulinDose()
        }

        let unit : UInt32 = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4
        
        if ((unit & 0xFFFF0000) == 0xFF000000) {
            dose.aUnits = Double(unit & 0x0000FFFF) / 10.0
            if (dose.aUnits > MAX_UNIT_VALUE) {
                dose.aUnits = -1.0
            }
        } else {
            dose.aUnits = -1.0
        }

        if (data.endIndex < (index+3)) {
            print("NFC : NovInsulinDose.parse - Invalid data")
            return NovInsulinDose()
        }

        dose.aFlags = data.subdata(in: index ..< index+4).to(UInt32.self).byteSwapped
        index += 4

        return dose
    }
    
}
