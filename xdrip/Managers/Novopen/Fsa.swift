//
//  Fsa.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 01/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

class Fsa {

    enum Action {
        case WRITE
        case WRITE_READ
        case READ
        case LOOP
        case DONE
        
        var description: String {
            return String(describing: self)
        }
    }

    private var a : Action
    private var d : Data
        
    public init(action : Action, data : Data) {
        a = action
        d = data
    }

    func data() -> Data {
        return d
    }
    
    func action() -> Action {
        return a
    }
}
