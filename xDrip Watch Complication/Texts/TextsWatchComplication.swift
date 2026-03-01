//
//  TextsWatchComplication.swift
//  xDrip Watch Complication Extension
//
//  Created by Paul Plant on 26/4/24.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import Foundation

/// all Nightscout related texts
class Texts_WatchComplication {
    static private let filename = "WatchComplication"
    
    static let keepAliveDisabled: String = {
        return NSLocalizedString("keepAliveDisabled", tableName: filename, bundle: Bundle.main, value: "Keep-alive disabled", comment: "watch complication - keep alive disabled")
    }()
    
    static let liveDataDisabled: String = {
        return NSLocalizedString("liveDataDisabled", tableName: filename, bundle: Bundle.main, value: "Live data disabled", comment: "watch complication - live data disabled")
    }()
    
    static let goTo: String = {
        return NSLocalizedString("goTo", tableName: filename, bundle: Bundle.main, value: "Go to", comment: "watch complication - text for go to")
    }()
    
    static let appleWatch: String = {
        return NSLocalizedString("appleWatch", tableName: filename, bundle: Bundle.main, value: "Apple Watch", comment: "watch complication - text for apple watch")
    }()
    
    static let settings: String = {
        return NSLocalizedString("settings", tableName: filename, bundle: Bundle.main, value: "Settings", comment: "Watch complication - text for apple watch settings")
    }()
    
    static let toEnable: String = {
        return NSLocalizedString("toEnable", tableName: filename, bundle: Bundle.main, value: "to enable", comment: "Watch complication - text for to enable")
    }()
    
    static let sensorAge: String = {
        return NSLocalizedString("sensorAge", tableName: filename, bundle: Bundle.main, value: "Sensor Age", comment: "Watch complication - sensor age title")
    }()
    
    static let sensorExpired: String = {
        return NSLocalizedString("sensorExpired", tableName: filename, bundle: Bundle.main, value: "Expired", comment: "Watch complication - sensor expired text")
    }()
    
    static let remaining: String = {
        return NSLocalizedString("remaining", tableName: filename, bundle: Bundle.main, value: "left", comment: "Watch complication - remaining time label")
    }()
    
    static let noSensor: String = {
        return NSLocalizedString("noSensor", tableName: filename, bundle: Bundle.main, value: "No Sensor", comment: "Watch complication - no active sensor text")
    }()
    
    static let timeInRange: String = {
        return NSLocalizedString("timeInRange", tableName: filename, bundle: Bundle.main, value: "Time In Range", comment: "Watch complication - time in range title")
    }()
    
    static let tirShort: String = {
        return NSLocalizedString("tirShort", tableName: filename, bundle: Bundle.main, value: "TIR", comment: "Watch complication - time in range short label")
    }()
    
    static let low: String = {
        return NSLocalizedString("low", tableName: filename, bundle: Bundle.main, value: "Low", comment: "Watch complication - low label")
    }()
    
    static let high: String = {
        return NSLocalizedString("high", tableName: filename, bundle: Bundle.main, value: "High", comment: "Watch complication - high label")
    }()
    
    static let noData: String = {
        return NSLocalizedString("noData", tableName: filename, bundle: Bundle.main, value: "No Data", comment: "Watch complication - no data text")
    }()
}
