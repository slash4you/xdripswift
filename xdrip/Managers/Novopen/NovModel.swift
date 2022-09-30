//
//  NovModel.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 18/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class NovModel {
    
    private var aModel : String
    
    public init() {
        aModel = "?"
    }
 
    func description() -> String {
        return "[MODEL] name:" + aModel
    }
    
    static func parse(data: Data) -> NovModel {
        var index : Int = data.startIndex
        let model : NovModel = NovModel()
        
        if (data.endIndex < (index+1)) {
            print("NFC : NovModel.parse - Invalid data")
            return NovModel()
        }
        
        let length : UInt16 = data.subdata(in: index ..< index+2).to(UInt16.self).byteSwapped
        index += 2
        
        let nextIndex : Int = index + Int(length)

        if (data.endIndex < nextIndex) {
            print("NFC : NovModel.parse - Invalid data")
            return NovModel()
        }
        
        model.aModel = String(decoding: data[ index ..< nextIndex ], as: UTF8.self)
        index = nextIndex

        return model
    }
    
}
