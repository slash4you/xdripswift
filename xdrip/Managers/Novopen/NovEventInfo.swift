//
//  NovEventInfo.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 18/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovEventInfo {
    
    var aHandle : UInt16
    var aSpecification : NovSpecification
    var aModel : NovModel
    var aTime : NovRelativeTime
 
    public init() {
        aHandle = 0
        aSpecification = NovSpecification()
        aModel = NovModel()
        aTime = NovRelativeTime()
    }
    
    func description() -> String {
        return "[INFO] handle:" + String(format: "%04X", aHandle) + " > " + aSpecification.description() + " > " + aModel.description() + " > " + aTime.description()
    }
    
    func isAsExpected() -> Bool {
        return (aSpecification.serial() != "?") && (aTime.relative() != 0)
    }

    //NFC:  [DPDU] invokeId:0000 Choice:0203 L:203 Payload:0000 0008 00c5
    //  SYS_ID                       TIME_REL         TIME_INFO
    // 0984000a0008001465004008931b 098f000400518efd 0a45001020001f00ffffffff00001f4000000000
    //  PROD_SPECN      SN=AAREY3                PN=D21491065500000 D21491065500000
    //092d004b00040047 000100010006414152455933 0002000100204432313439313036353530303030302044323134393130363535303030303020
    //  HW=00          SW=01.08.00
    // 00030001000100 00040001000830312e30382e3030
    //  SPEC_LIST                ID_MODEL
    // 0a5a00080001000410480001 0928001c00104e6f766f204e6f726469736b20412f5300084e6f766f50656e00
    //  CONFIG_ID    CERT_DATA_LIST
    // 0a440002400a 0a4b00160002001202010008040000010002a048020200020000
    //NFC : [INFO] handle:0000 > [SPEC] SN:AAREY3 PN:D21491065500000 D21491065500000  SW:01.08.00 HW:? > [MODEL] name:Novo Nordisk A/S > [TIME] relative:00519842 absolute:2022-09-19 16:49:55 +0000

    static func parse(data: Data) -> NovEventInfo {
        
        var index : Int = data.startIndex
        let info : NovEventInfo = NovEventInfo()

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventInfo.parse - Invalid data")
            return NovEventInfo()
        }

        info.aHandle = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventInfo.parse - Invalid data")
            return NovEventInfo()
        }

        let icount : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventInfo.parse - Invalid data")
            return NovEventInfo()
        }

        let _ : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (icount > 0) {
            for _ in 1 ... icount {

                if (data.endIndex < (index+3)) {
                    print("NFC : NovEventInfo.parse - Invalid data")
                    return NovEventInfo()
                }

                let attrlen : UInt16 = UInt16(data[index+2])*256 + UInt16(data[index+3])
                let nextIndex : Int = index + 4 + Int(attrlen)
                
                if (data.endIndex < nextIndex) {
                    print("NFC : NovEventInfo.parse - Invalid data")
                    return NovEventInfo()
                }

                let attr : NovAttribute = NovAttribute.parse(data: data[index ..< nextIndex])
                index = nextIndex

                switch (attr.kind()) {
                    
                case .MDC_ATTR_ID_PROD_SPECN:
                    info.aSpecification = NovSpecification.parse(data: attr.bytes())
                    break

                case .MDC_ATTR_TIME_REL:
                    info.aTime = NovRelativeTime.parse(data: attr.bytes())
                    break

                case .MDC_ATTR_ID_MODEL:
                    info.aModel = NovModel.parse(data: attr.bytes())
                    break

                case .MDC_ATTR_INVALID:
                    print("NFC : NovEventInfo.parse - Invalid data")
                    return NovEventInfo()
                    
                default:
                    break
                }
                
            }
        }
        
        return info
    }
    
}
