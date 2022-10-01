//
//  NovAttribute.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 10/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovAttribute {

    enum AttributeType : UInt16, CaseIterable {
        
        case MDC_ATTR_INVALID = 0
        case MDC_ATTR_SYS_ID = 0x0984 //2436
        case MDC_ATTR_ID_INSTNO = 0x0922 //2338
        case MDC_ATTR_ID_MODEL = 0x0928 //2344
        case MDC_ATTR_ID_PROD_SPECN = 0x092D //2349
        case MDC_ATTR_ID_TYPE = 0x092F //2351
        case MDC_ATTR_METRIC_STORE_CAPAC_CNT = 0x0941 //2369
        case MDC_ATTR_METRIC_STORE_SAMPLE_ALG  = 0x0943 //2371
        case MDC_ATTR_METRIC_STORE_USAGE_CNT  = 0x0944 //2372
        case MDC_ATTR_NUM_SEG  = 0x0951 //2385
        case MDC_ATTR_OP_STAT  = 0x0953 //2387
        case MDC_ATTR_SEG_USAGE_CNT  = 0x097B //2427
        case MDC_ATTR_TIME_REL  = 0x098F //2447
        case MDC_ATTR_UNIT_CODE  = 0x0996 //2454
        case MDC_ATTR_DEV_CONFIG_ID  = 0x0A44 //2628
        case MDC_ATTR_MDS_TIME_INFO  = 0x0A45 //2629
        case MDC_ATTR_METRIC_SPEC_SMALL  = 0x0A46 //2630
        case MDC_ATTR_REG_CERT_DATA_LIST  = 0x0A4B //2635
        case MDC_ATTR_PM_STORE_CAPAB  = 0x0A4D //2637
        case MDC_ATTR_PM_SEG_MAP  = 0x0A4E //2638
        case MDC_ATTR_ATTRIBUTE_VAL_MAP  = 0x0A55 //2645
        case MDC_ATTR_NU_VAL_OBS_SIMP  = 0x0A56 //2646
        case MDC_ATTR_PM_STORE_LABEL_STRING  = 0x0A57 //2647
        case MDC_ATTR_PM_SEG_LABEL_STRING  = 0x0A58 //2648
        case MDC_ATTR_SYS_TYPE_SPEC_LIST  = 0x0A5A //2650
        case MDC_ATTR_CLEAR_TIMEOUT  = 0x0A63 //2659
        case MDC_ATTR_TRANSFER_TIMEOUT  = 0x0A64 //2660
        case MDC_ATTR_ENUM_OBS_VAL_BASIC_BIT_STR  = 0x0A66 //2662

        static func findByValue(val : UInt16) -> AttributeType {
            for a in AttributeType.allCases {
                if (a.rawValue == val) {
                    return a
                }
            }
            return AttributeType.MDC_ATTR_INVALID
        }
        
        var description: String {
            return String(describing: self)
        }
    }

    private var aKind : AttributeType
    private var aType : UInt16
    private var aValue : Int32
    private var aBytes : Data

    public init() {
        aType = 0
        aKind = .MDC_ATTR_INVALID
        aValue = -1
        aBytes = Data()
    }
    
    func description() -> String {
        return "[ATTR] kind=" + aKind.description + " ivalue=" + aValue.description + " bytes=" + aBytes.toHexString()
    }
    
    func kind() -> AttributeType {
        return aKind
    }
    
    func value() -> Int32 {
        return aValue
    }
    
    func bytes() -> Data {
        return aBytes
    }
    
    static func parse(data : Data) -> NovAttribute {
        var index : Int = data.startIndex
        let attr : NovAttribute = NovAttribute()
        
        if (data.endIndex < (index+1)) {
            print("NFC : NovAttribute.parse - Invalid data")
            return NovAttribute()
        }

        attr.aType = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovAttribute.parse - Invalid data")
            return NovAttribute()
        }

        let length : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2

        let nextindex : Int = index + Int(length)
        
        if (data.endIndex < nextindex) {
            print("NFC : NovAttribute.parse - Invalid data")
            return NovAttribute()
        }

        attr.aBytes = data[index ..< nextindex]

        attr.aKind = AttributeType.findByValue(val: attr.aType)
        
        if (length == 4) {
            // TODO : 32 bits length data is signed ?
            attr.aValue = data.subdata(in: index ..< index+4).to(Int32.self).byteSwapped
        }
        else if (length == 2) {
            // TODO : 16 bits length data is signed ?
            attr.aValue = Int32(data.subdata(in: index ..< index+2).to(Int16.self).byteSwapped)
        }
        else {
            attr.aValue = -1
        }
        
        index = nextindex

        return attr
    }
    
}
