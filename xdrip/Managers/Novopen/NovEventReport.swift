//
//  NovEventReport.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 10/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovEventReport {
    
    enum EventType : UInt16, CaseIterable {
        
        case MDC_NOTI_INVALID = 0x0000
        case MDC_NOTI_CONFIG = 0x0D1C // 3356
        case MDC_NOTI_SEGMENT_DATA = 0x0D21 // 3361
    
        static func findByValue(val : UInt16) -> EventType {
            for a in EventType.allCases {
                if (a.rawValue == val) {
                    return a
                }
            }
            return EventType.MDC_NOTI_INVALID
        }
        
        var description: String {
            return String(describing: self)
        }

    }
    
    private var evHandle : UInt16
    private var evInstance : UInt16
    private var evIndex : UInt32
    private var evCount : UInt32
    private var evConfig : NovConfiguration
    private var evDoses : [NovInsulinDose]
    private var evLength : UInt16
    private var evTime : UInt32
    private var evType : EventType
    
    public init() {
        evHandle = 0
        evInstance = 0
        evIndex = 0
        evCount = 0
        evConfig = NovConfiguration()
        evDoses = [NovInsulinDose]()
        evLength = 0
        evTime = 0
        evType = .MDC_NOTI_INVALID
    }
    
    func doses() -> [NovInsulinDose] {
        return evDoses
    }
    
    func config() -> NovConfiguration {
        return evConfig
    }
    
    func description() -> String {
        
        var log : String = "[REPORT] L:" + evLength.description + " handle:" + String(format: "%04X", evHandle) + " time:" + String(format: "%08X", evTime) + "type:" + evType.description
        
        switch (evType)
        {
        case .MDC_NOTI_CONFIG:
            log += " " + evConfig.description()
            break
        case .MDC_NOTI_SEGMENT_DATA:
            log += " instance:" + String(format: "%04X", evInstance) + " index:" + String(format: "%08X", evIndex) + " count:" + evCount.description + " doses: "
            for d in evDoses {
                log = log + d.description()
            }
            break
        case .MDC_NOTI_INVALID:
            log += " INVALID"
            break
        }

        return log
    }
    
    static func parse(data: Data) -> NovEventReport {
        var index : Int = data.startIndex
        let er : NovEventReport = NovEventReport()

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventReport.parse - Invalid data")
            return NovEventReport()
        }

        er.evHandle = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+3)) {
            print("NFC : NovEventReport.parse - Invalid data")
            return NovEventReport()
        }

        er.evTime = (UInt32(data[index]) << 24) + (UInt32(data[index+1]) << 16) + (UInt32(data[index+2]) << 8) + UInt32(data[index+3])
        index += 4

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventReport.parse - Invalid data")
            return NovEventReport()
        }

        let eventType : UInt16 = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        er.evType = EventType.findByValue(val: eventType)
        
        if (data.endIndex < (index+1)) {
            print("NFC : NovEventReport.parse - Invalid data")
            return NovEventReport()
        }

        er.evLength = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2
        
        let nextIndex : Int = index + Int(er.evLength)
        
        if (data.endIndex < nextIndex) {
            print("NFC : NovEventReport.parse - Invalid data")
            return NovEventReport()
        }

        switch (er.evType)
        {
        case .MDC_NOTI_SEGMENT_DATA:
            
            if (data.endIndex < (index+1)) {
                print("NFC : NovEventReport.parse - Invalid data")
                return NovEventReport()
            }

            er.evInstance = UInt16(data[index])*256 + UInt16(data[index+1])
            index += 2

            if (data.endIndex < (index+3)) {
                print("NFC : NovEventReport.parse - Invalid data")
                return NovEventReport()
            }

            er.evIndex = (UInt32(data[index]) << 24) + (UInt32(data[index+1]) << 16) + (UInt32(data[index+2]) << 8) + UInt32(data[index+3])
            index += 4

            if (data.endIndex < (index+3)) {
                print("NFC : NovEventReport.parse - Invalid data")
                return NovEventReport()
            }

            er.evCount = (UInt32(data[index]) << 24) + (UInt32(data[index+1]) << 16) + (UInt32(data[index+2]) << 8) + UInt32(data[index+3])
            index += 4

            if (data.endIndex < (index+1)) {
                print("NFC : NovEventReport.parse - Invalid data")
                return NovEventReport()
            }

            let _ : UInt16 = UInt16(data[index])*256 + UInt16(data[index+1])
            index += 2

            if (data.endIndex < (index+1)) {
                print("NFC : NovEventReport.parse - Invalid data")
                return NovEventReport()
            }

            let _ : UInt16 = UInt16(data[index])*256 + UInt16(data[index+1])
            index += 2

            if (er.evCount > 0) {
                for _ in 1 ... er.evCount {
                    let endIndex : Int = index + 12
                    
                    if (data.endIndex < endIndex) {
                        print("NFC : NovConfiguration.parse - Invalid data")
                        return NovEventReport()
                    }

                    er.evDoses.append( NovInsulinDose.parse(data: data[index ..< endIndex], time: TimeInterval(er.evTime)))
                    index = endIndex
                }
            }
            
            break
        case .MDC_NOTI_CONFIG:
            er.evConfig = NovConfiguration.parse(data: data[index ..< nextIndex])
            index = nextIndex
            break
        case .MDC_NOTI_INVALID:
            print("NFC : NovEventReport.parse - Unknown event type")
            break
        }
        
        return er
    }
    
}
