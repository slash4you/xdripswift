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
    
    //NFC:  [DPDU] invokeId:0000 Choice:0203 L:62 Payload:0100 0008 0038 0a4d0002080009430002000009410004000003200953000200000a5700040002504d0951000200010a630004000000000944000400000018
    //NFC : [INFO] > [SPEC] SN:? PN:? SW:? HW:? > [MODEL] name:? > [TIME] relative:00000000 absolute:1970-01-01 00:00:00 +0000

    static func parse(data: Data) -> NovEventInfo {
        
        var index : Int = data.startIndex
        let info : NovEventInfo = NovEventInfo()

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventInfo.parse - Invalid data")
            return NovEventInfo()
        }

        info.aHandle = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventInfo.parse - Invalid data")
            return NovEventInfo()
        }

        let icount : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovEventInfo.parse - Invalid data")
            return NovEventInfo()
        }

        let _ : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
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
