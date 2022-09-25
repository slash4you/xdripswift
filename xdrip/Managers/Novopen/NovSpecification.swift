//
//  NovSpecification.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 18/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovSpecification {
    
    enum SpecType : UInt16, CaseIterable {
        case INVALID = 0
        case SERIAL_NUMBER = 1
        case PART_NUMBER = 2
        case HW_VERSION = 3
        case SW_VERSION = 4
        
        static func findByValue(val : UInt16) -> SpecType {
            for a in SpecType.allCases {
                if (a.rawValue == val) {
                    return a
                }
            }
            return SpecType.INVALID
        }
        
        var description: String {
            return String(describing: self)
        }
    }

    private var aSerialNumber : String
    private var aPartNumber : String
    private var aSoftwareVersion : String
    private var aHardwareVersion : String
    
    public init() {
        aSerialNumber = "?"
        aPartNumber = "?"
        aSoftwareVersion = "?"
        aHardwareVersion = "?"
    }
    
    func description() -> String {
        return "[SPEC] SN:" + aSerialNumber + " PN:" + aPartNumber + " SW:" + aSoftwareVersion + " HW:" + aHardwareVersion
    }
    
    func serial() -> String {
        return aSerialNumber
    }

    func partNumber() -> String {
        return aPartNumber
    }

    func softwareVersion() -> String {
        return aSoftwareVersion
    }

    func hardwareVersion() -> String {
        return aHardwareVersion
    }

    static func parse(data: Data) -> NovSpecification {
        var index : Int = data.startIndex
        let spec : NovSpecification = NovSpecification()

        if (data.endIndex < (index+1)) {
            print("NFC : NovSpecification.parse - Invalid data")
            return NovSpecification()
        }

        let scount : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        if (data.endIndex < (index+1)) {
            print("NFC : NovSpecification.parse - Invalid data")
            return NovSpecification()
        }

        let _ : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
        index += 2

        if (scount > 0) {
            for _ in 1 ... scount {
                
                if (data.endIndex < (index+1)) {
                    print("NFC : NovSpecification.parse - Invalid data")
                    return NovSpecification()
                }

                let type : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
                index += 2

                if (data.endIndex < (index+1)) {
                    print("NFC : NovSpecification.parse - Invalid data")
                    return NovSpecification()
                }

                let _ : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
                index += 2

                if (data.endIndex < (index+1)) {
                    print("NFC : NovSpecification.parse - Invalid data")
                    return NovSpecification()
                }

                let length : UInt16 = UInt16(data[index]) * 256 + UInt16(data[index+1])
                index += 2

                let nextIndex : Int = index + Int(length)
                
                if (data.endIndex < nextIndex) {
                    print("NFC : NovSpecification.parse - Invalid data")
                    return NovSpecification()
                }

                let bytes : Data = data[index ..< nextIndex]
                index = nextIndex
                
                switch (type)
                {
                case SpecType.SERIAL_NUMBER.rawValue:
                    if (bytes.count > 0 && bytes.first != 0 ) {
                        spec.aSerialNumber = String(decoding: bytes, as: Unicode.ASCII.self)
                    }
                    break
                case SpecType.PART_NUMBER.rawValue:
                    if (bytes.count > 0 && bytes.first != 0 ) {
                        spec.aPartNumber = String(decoding: bytes, as: Unicode.ASCII.self)
                    }
                    break
                case SpecType.HW_VERSION.rawValue:
                    if (bytes.count > 0 && bytes.first != 0 ) {
                        spec.aHardwareVersion = String(decoding: bytes, as: Unicode.ASCII.self)
                    }
                    break
                case SpecType.SW_VERSION.rawValue:
                    if (bytes.count > 0 && bytes.first != 0 ) {
                        spec.aSoftwareVersion = String(decoding: bytes, as: Unicode.ASCII.self)
                    }
                    break
                default:
                    break
                }
                
            }
        }
        
        return spec
    }
    
}
