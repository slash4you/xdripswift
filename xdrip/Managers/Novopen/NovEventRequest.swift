//
//  NovEventRequest.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 10/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovEventRequest {
    
    static let FIRST : UInt8 = 0x80
    static let MIDDLE : UInt8 = 0x00
    static let LAST : UInt8 = 0x40
    static let MARK : UInt8 = 0x80

    private var evHandle : UInt16
    private var evTime : UInt32
    private var evType : UInt16
    private var evReplyLen : UInt16
    private var evReportId : UInt16
    private var evReportResult : UInt16
    
    
    public init() {
        evHandle = 0
        evTime = 0
        evType = 0
        evReplyLen = 0
        evReportId = 0
        evReportResult = 0
    }

    public init(handle : UInt16,time : UInt32,type : UInt16) {
        evHandle = handle
        evTime = time
        evType = type
        evReplyLen = 0
        evReportId = 0
        evReportResult = 0
    }

    func description() -> String {
        return "[REQUEST] handle:" + String(format: "%04X", evHandle) + " time:" + String(format: "%08X", evTime) + " type:" + String(format: "%04X", evType) + " replyLen:" + String(format: "%04X", evReplyLen) + " reportId:" + String(format: "%04X", evReportId) + " reportResult:" + String(format: "%04X", evReportResult)
    }
    
    func encode(reportId : UInt16, reportResult : UInt16) -> Data {
        var buf : Data = Data()
        
        let H1 : UInt8 = UInt8((evHandle >> 8) & 0xFF)
        let H0 : UInt8 = UInt8(evHandle & 0xFF)
        buf.append(contentsOf: [H1, H0])

        let T3 : UInt8 = UInt8((evTime >> 24) & 0xFF)
        let T2 : UInt8 = UInt8((evTime >> 16) & 0xFF)
        let T1 : UInt8 = UInt8((evTime >> 8) & 0xFF)
        let T0 : UInt8 = UInt8(evTime & 0xFF)
        buf.append(contentsOf: [T3, T2, T1, T0])

        let K1 : UInt8 = UInt8((evType >> 8) & 0xFF)
        let K0 : UInt8 = UInt8(evType & 0xFF)
        buf.append(contentsOf: [K1, K0])

        buf.append(contentsOf: [0, 4])

        let I1 : UInt8 = UInt8((reportId >> 8) & 0xFF)
        let I0 : UInt8 = UInt8(reportId & 0xFF)
        buf.append(contentsOf: [I1, I0])
            
        let R1 : UInt8 = UInt8((reportResult >> 8) & 0xFF)
        let R0 : UInt8 = UInt8(reportResult & 0xFF)
        buf.append(contentsOf: [R1, R0])
        
        return buf
    }

    func encode(instance : UInt16, index : UInt16, count : UInt16, block : UInt8, confirmed : Bool) -> Data {
        var buf : Data = Data()
        
        let H1 : UInt8 = UInt8((evHandle >> 8) & 0xFF)
        let H0 : UInt8 = UInt8(evHandle & 0xFF)
        buf.append(contentsOf: [H1, H0])

        let T3 : UInt8 = UInt8((evTime >> 24) & 0xFF)
        let T2 : UInt8 = UInt8((evTime >> 16) & 0xFF)
        let T1 : UInt8 = UInt8((evTime >> 8) & 0xFF)
        let T0 : UInt8 = UInt8(evTime & 0xFF)
        buf.append(contentsOf: [T3, T2, T1, T0])

        let K1 : UInt8 = UInt8((evType >> 8) & 0xFF)
        let K0 : UInt8 = UInt8(evType & 0xFF)
        buf.append(contentsOf: [K1, K0])

        buf.append(contentsOf: [0, 12])

        let S1 : UInt8 = UInt8((instance >> 8) & 0xFF)
        let S0 : UInt8 = UInt8(instance & 0xFF)
        buf.append(contentsOf: [S1, S0])
        buf.append(contentsOf: [0, 0])

        let I1 : UInt8 = UInt8((index >> 8) & 0xFF)
        let I0 : UInt8 = UInt8(index & 0xFF)
        buf.append(contentsOf: [I1, I0])
        buf.append(contentsOf: [0, 0])

        let C1 : UInt8 = UInt8((count >> 8) & 0xFF)
        let C0 : UInt8 = UInt8(count & 0xFF)
        buf.append(contentsOf: [C1, C0])

        buf.append(contentsOf: [block])

        if (confirmed) {
            buf.append(contentsOf: [NovEventRequest.MARK])
        } else {
            buf.append(contentsOf: [0])
        }
        
        return buf
    }

    static func parse(data: Data) -> NovEventRequest {
        var index : Int = data.startIndex
        let er : NovEventRequest = NovEventRequest()

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventRequest.parse - Invalid data")
            return NovEventRequest()
        }

        er.evHandle = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+3)) {
            print("NFC : NovEventRequest.parse - Invalid data")
            return NovEventRequest()
        }

        er.evTime = (UInt32(data[index]) << 24) + (UInt32(data[index+1]) << 16) + (UInt32(data[index+2]) << 8) + UInt32(data[index+3])
        index += 4

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventRequest.parse - Invalid data")
            return NovEventRequest()
        }

        er.evType = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventRequest.parse - Invalid data")
            return NovEventRequest()
        }

        er.evReplyLen = UInt16(data[index])*256 + UInt16(data[index+1])
        index += 2

        if (er.evReplyLen == 4) {
            
            if (data.endIndex < (index+1)) {
                print("NFC : NovEventRequest.parse - Invalid data")
                return NovEventRequest()
            }

            er.evReportId = UInt16(data[index])*256 + UInt16(data[index+1])
            index += 2

            if (data.endIndex < (index+1)) {
                print("NFC : NovEventRequest.parse - Invalid data")
                return NovEventRequest()
            }

            er.evReportResult = UInt16(data[index])*256 + UInt16(data[index+1])
            index += 2
        }
        
        
        return er
    }
    
    
}