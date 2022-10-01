//
//  NovConfiguration.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 10/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovConfiguration {
    
    static let MDC_DIM_INTL_UNIT : Int32 = 0x1560 //5472
    
    private var cfgId : UInt16
    private var cfgHandle : UInt16
    private var cfgNbOfSegments : Int32
    private var cfgTotalStoredEntries : Int32
    private var cfgTotalStorageCapacity : Int32
    private var cfgUnitCode : Int32
    private var cfgMaps : [NovValueMap]
    private var cfgLength : UInt16
    
    public init() {
        cfgId = 0
        cfgHandle = 0
        cfgNbOfSegments = -1
        cfgTotalStoredEntries = -1
        cfgTotalStorageCapacity = -1
        cfgUnitCode = -1
        cfgMaps = [NovValueMap]()
        cfgLength = 0
    }
    
    func description() -> String {
        var log : String = "[CONF] L:" + cfgLength.description + " valid:" + isAsExpected().description + " id:" + String(format: "%04X", cfgId) + " handle:" + String(format: "%04X", cfgHandle) + " nbSegments:" + cfgNbOfSegments.description + " totalEntries:" + cfgTotalStoredEntries.description + " totalStorage:" + cfgTotalStorageCapacity.description + " unitCode:" + cfgUnitCode.description + " maps:"

        log = log + "{"
        for v in cfgMaps {
            log = log + v.description() + " "
        }
        log = log + "}"

        return log
    }
    
    func id() -> UInt16 {
        return cfgId
    }
    
    func handle() -> UInt16 {
        return cfgHandle
    }
    
    func isAsExpected() -> Bool {
        return (cfgUnitCode == NovConfiguration.MDC_DIM_INTL_UNIT) && (cfgNbOfSegments == 1) && (cfgTotalStoredEntries > 0)
    }

    
    //NFC:  [DPDU] invokeId:0000 Choice:0101 L:188 Payload:
    //  H   TIME      T   L
    // 0000 00000000 0d1c 00b2
    //  ID   N    L
    // 400a 0004 00ac
    //  _    H   NAT  _     STORE_CAPAB  SAMPLE_ALG    CAPAC_CNT       OPSTAT        STORE_LABEL      NUM_SEG      TIMEOUT          USAGE_CNT
    // 003d 0100 0008 0038 0a4d00020800 094300020000 0941000400000320 095300020000 0a5700040002504d 095100020001 0a63000400000000 0944000400000017
    //  _    H    NAT _     ID               SPEC_SMALL   UNIT_CODE   MAP
    // 0006 0002 0004 0020 092f000400823401 0a460002f040 099600021560 0a550008 0001 0004 0a56 0004
    //  _    H   NAT  _     ID               SPEC_SMALL   MAP
    // 0005 0003 0003 001a 092f000400823402 0a460002f040 0a550008 0001 0004 0a66 0002
    //  _    H   NAT  _     ID               SPEC_SMALL   MAP
    // 0006 0004 0003 001a 092f00040082f000 0a460002f040 0a550008 0001 0004 0a66 0002
    //NFC : [REPORT] L:178 handle:0000 instance:0000 index:0 count:0 doses:  config: [CONF] L:172 valid:true id:400A handle:0100 nbSegments:1 totalEntries:23 totalStorage:800 unitCode:5472 maps:{[(0A56,0004) ] [(0A66,0002) ] [(0A66,0002) ] }
    
    //NFC: NovStateMachine.processPayload -  [MSG] Valid:false
    //NFC:  [REQUEST] handle:0000 time:00000000 type:0D1C replyLen:0004 reportId:400A reportResult:0000
    //NFC: NovStateMachine.processPayload - AWAIT_CONFIGURATION [APDU] Value:E700 Type:Prst L:22 Payload:001400000201000e0000000000000d1c0004400a0000
    //NFC: readDataFromLinkLayer - OUT L:26 P:e7000016001400000201000e0000000000000d1c0004400a0000
    //NFC:  [PHDLL] Opcode:D1 Header: Sum:83 Seq:03 Payload:e7000016 001400000201000e 0000 00000000 0d1c 0004 400a 0000

    static func parse(data: Data) -> NovConfiguration {
        var initialized : Bool = false
        var index : Int = data.startIndex
        let cfg : NovConfiguration = NovConfiguration()
        
        if (data.endIndex < (index+1)) {
            print("NFC : NovConfiguration.parse - Invalid data")
            return NovConfiguration()
        }

        let I : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovConfiguration.parse - Invalid data")
            return NovConfiguration()
        }

        let count : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovConfiguration.parse - Invalid data")
            return NovConfiguration()
        }

        cfg.cfgLength = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (count > 0) {
            for _ in 1 ... count {
                
                if (data.endIndex < (index+1)) {
                    print("NFC : NovConfiguration.parse - Invalid data")
                    return NovConfiguration()
                }

                let _ : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
                index += 2

                if (data.endIndex < (index+1)) {
                    print("NFC : NovConfiguration.parse - Invalid data")
                    return NovConfiguration()
                }

                let H : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
                index += 2

                if (data.endIndex < (index+1)) {
                    print("NFC : NovConfiguration.parse - Invalid data")
                    return NovConfiguration()
                }

                let acount : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
                index += 2

                if (data.endIndex < (index+1)) {
                    print("NFC : NovConfiguration.parse - Invalid data")
                    return NovConfiguration()
                }

                let _ : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
                index += 2

                if (acount > 0) {
                    for _ in 1 ... acount {
                        
                        if (initialized == false) {
                            cfg.cfgId = I
                            cfg.cfgHandle = H
                            initialized = true
                        }
                        
                        if (data.endIndex < (index+3)) {
                            print("NFC : NovConfiguration.parse - Invalid data")
                            return NovConfiguration()
                        }

                        let attrlen : UInt16 = UInt16(data[index+2])*256 + UInt16(data[index+3])
                        let nextIndex : Int = index + 4 + Int(attrlen)
                        
                        if (data.endIndex < nextIndex) {
                            print("NFC : NovConfiguration.parse - Invalid data")
                            return NovConfiguration()
                        }

                        let attr : NovAttribute = NovAttribute.parse(data: data[index ..< nextIndex])
                        index = nextIndex

                        switch (attr.kind()) {
                            case .MDC_ATTR_NUM_SEG:
                                cfg.cfgNbOfSegments = attr.value()
                                break
                            case .MDC_ATTR_METRIC_STORE_USAGE_CNT:
                                cfg.cfgTotalStoredEntries = attr.value()
                                break
                            case .MDC_ATTR_UNIT_CODE:
                                cfg.cfgUnitCode = attr.value()
                                break
                            case .MDC_ATTR_METRIC_STORE_CAPAC_CNT:
                                cfg.cfgTotalStorageCapacity = attr.value()
                                break
                            case .MDC_ATTR_ATTRIBUTE_VAL_MAP:
                                cfg.cfgMaps.append( NovValueMap.parse(data: attr.bytes()) )
                                break
                            case .MDC_ATTR_INVALID:
                                print("NFC : NovConfiguration.parse - Invalid data")
                                return NovConfiguration()
                            default:
                                break
                        }
                    }
                }
            }
        }

        return cfg
    }
    
}
