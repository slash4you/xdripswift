//
//  NovSegmentEntry.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 23/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovSegmentEntry {
    
    fileprivate enum EntryType  {
        case VALUES
        case BYTES
        case INVALID
        
        var description: String {
            return String(describing: self)
        }
    }

    fileprivate enum ValueType : UInt16, CaseIterable  {
        case MDC_ATTR_NU_VAL_OBS_SIMP = 0x0A56 //2646
        case MDC_ATTR_ENUM_OBS_VAL_BASIC_BIT_STR = 0x0A66 //2662
        case MDC_ATTR_VAL_INVALID = 0x0000

        var description: String {
            return String(describing: self)
        }

        static func findByValue(val : UInt16) -> ValueType {
            for a in ValueType.allCases {
                if (a.rawValue == val) {
                    return a
                }
            }
            return ValueType.MDC_ATTR_VAL_INVALID
        }
    }

    private var aEntryType : EntryType
    private var aValueType : ValueType
    private var aClassId : UInt16
    private var aOType : UInt16
    private var aMetricType : UInt16
    private var aHandle : UInt16
    private var aMCount : UInt16
    private var aMLen : UInt16
    private var aVal1 : UInt16
    private var aVal2 : UInt16
    private var aBytes : Data
    
    public init() {
        aClassId = 0
        aOType = 0
        aMetricType = 0
        aHandle = 0
        aMCount = 0
        aMLen = 0
        aEntryType = .INVALID
        aValueType = .MDC_ATTR_VAL_INVALID
        aVal1 = 0
        aVal2 = 0
        aBytes = Data()
    }

    func isTypical() -> Bool {
        return (aEntryType == .VALUES) && ((aOType == 0x3401 && aMetricType == 0x82 && aValueType == .MDC_ATTR_NU_VAL_OBS_SIMP) || (aOType == 0x3402 && aMetricType == 0x82 && aValueType == .MDC_ATTR_ENUM_OBS_VAL_BASIC_BIT_STR) || (aOType == 0xF000 && aMetricType == 0x82 && aValueType == .MDC_ATTR_ENUM_OBS_VAL_BASIC_BIT_STR))
    }

    func description() ->String {
        var log : String = "[SEG_ENTRY] classId:" + String(format: "%04X", aClassId) + " OType:" + String(format: "%04X", aOType) + " metricType:" + String(format: "%04X", aMetricType) + " handle:" + String(format: "%04X", aHandle) + " mcount:" + String(format: "%04X", aMCount) + " mlen:" + String(format: "%04X", aMLen)
        if (aEntryType == .VALUES) {
            log += " val1:" + String(format: "%04X", aVal1) + " val2:" + String(format: "%04X", aVal2)
            log += " isTypical: " + isTypical().description
        } else if (aEntryType == .BYTES) {
            log += " bytes:" + aBytes.toHexString()
        } else {
            log += " invalid format"
        }
        
        return log
    }
    
    static func parse(data: Data) -> NovSegmentEntry {
        
        var index : Int = data.startIndex
        let seg : NovSegmentEntry = NovSegmentEntry()

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentEntry.parse - Invalid data")
            return NovSegmentEntry()
        }

        seg.aClassId = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentEntry.parse - Invalid data")
            return NovSegmentEntry()
        }

        seg.aMetricType = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentEntry.parse - Invalid data")
            return NovSegmentEntry()
        }

        seg.aOType = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentEntry.parse - Invalid data")
            return NovSegmentEntry()
        }

        seg.aHandle = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentEntry.parse - Invalid data")
            return NovSegmentEntry()
        }

        seg.aMCount = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSegmentEntry.parse - Invalid data")
            return NovSegmentEntry()
        }

        seg.aMLen = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (seg.aMLen == 4) {
            
            seg.aEntryType = .VALUES

            if (data.endIndex < (index+1)) {
                print("NFC : NovSegmentEntry.parse - Invalid data")
                return NovSegmentEntry()
            }

            seg.aVal1 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
            index += 2

            if (data.endIndex < (index+1)) {
                print("NFC : NovSegmentEntry.parse - Invalid data")
                return NovSegmentEntry()
            }

            seg.aVal2 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
            index += 2
            
            
            seg.aValueType = ValueType.findByValue(val: seg.aVal1)
            
        } else {
            
            seg.aEntryType = .BYTES

            let nextIndex : Int = index + Int(seg.aMLen)
            
            if (data.endIndex < nextIndex) {
                print("NFC : NovSegmentEntry.parse - Invalid data")
                return NovSegmentEntry()
            }

            seg.aBytes = data[ index ..< nextIndex]
            index = nextIndex
            
        }
        
        return seg
    }
    
}
