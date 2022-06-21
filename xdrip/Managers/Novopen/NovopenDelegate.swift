//
//  NovopenDelegate.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 03/09/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

protocol NovopenDelegateProtocol: AnyObject {
 
    func receivedInsulinData(serialNumber: String, date: Date, dose: Double)
    
}
