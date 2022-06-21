//
//  WebServerDelegate.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 12/10/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation

protocol WebServerDelegateProtocol: AnyObject {
 
    func receivedHealthData(heart: Int)

    func receivedHealthData(steps: Int)

}
