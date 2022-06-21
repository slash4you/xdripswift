//
//  WebServerManager.swift
//  xdrip
//
//  Created by Stéphane LE HIR on 10/06/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import Foundation
import os
import GCDWebServer


class WebServerManager {

    /// for logging
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryWebServerController)

    /// reference to CoreDataManager
    private var coreDataManager:CoreDataManager
    
    /// reference to BgReadingsAccessor
    private var bgReadingsAccessor:BgReadingsAccessor

    /// reference to SensorsAccessor
    private var sensorAccessor:SensorsAccessor

    private var webServer: GCDWebServer?

    public let sharedUserDefaults: UserDefaults?

    private var backgroundTask : BackgroundTask?

    /// initializer
    public init(coreDataManager:CoreDataManager) {

        self.coreDataManager = coreDataManager
        self.bgReadingsAccessor = BgReadingsAccessor(coreDataManager: coreDataManager)
        self.sensorAccessor = SensorsAccessor(coreDataManager: coreDataManager)
        self.webServer = GCDWebServer()
        
        self.backgroundTask = BackgroundTask()
        self.sharedUserDefaults = UserDefaults(suiteName: Bundle.main.appGroupSuiteName)
    }
    
    public func start() {
        if let webServer = webServer, !webServer.isRunning {
            
            webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
                trace("in webServer defaulthandler, unexpected url = %{public}@", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error, request.url.description)
                return GCDWebServerErrorResponse(statusCode: 503)
            })
            
            webServer.addHandler(forMethod: "GET", path: ConstantsWebServer.defaultServiceUrl, request: GCDWebServerRequest.self, processBlock: {request in
                var maxReadingsNumber = 1
                if let query = request.query {
                    if let countArg = query["count"] {
                        if let countInt = Int(countArg) {
                            var count = countInt
                            if count > ConstantsWebServer.maxReadingsToUpload {
                                count = ConstantsWebServer.maxReadingsToUpload
                            }
                            maxReadingsNumber = count
                        } else {
                            trace("in webServer handler, invalid count type @", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                            return GCDWebServerErrorResponse(statusCode: 500)
                        }
                    } else {
                        trace("in webServer handler, count arg not found @", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                        return GCDWebServerErrorResponse(statusCode: 500)
                    }
                } else {
                    trace("in webServer handler, invalid query type @", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                    return GCDWebServerErrorResponse(statusCode: 500)
                }
                
                var json = Array<AnyObject>()
                if let shared = self.sharedUserDefaults {
                    if let sharedData = shared.data(forKey: "latestNightScoutReadings") {
                        if let decoded = try? JSONSerialization.jsonObject(with: sharedData, options: []) {
                            if let sgvs = decoded as? Array<AnyObject> {
                                for sgv in sgvs.prefix(maxReadingsNumber) {
                                    json.append(sgv)
                                }
                            } else {
                                trace("in webServer handler, invalid bgreading type @", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                                return GCDWebServerErrorResponse(statusCode: 500)
                            }
                        } else {
                            trace("in webServer handler, invalid json data @", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                            return GCDWebServerErrorResponse(statusCode: 500)
                        }
                    } else {
                        trace("in webServer handler, invalid shared data @", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                        return GCDWebServerErrorResponse(statusCode: 500)
                    }
                } else {
                    trace("in webServer handler, invalid shared type @", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                    return GCDWebServerErrorResponse(statusCode: 500)
                }
                return GCDWebServerDataResponse(jsonObject: json)
            })

            do {
                try webServer.start(
                    options: [
                        GCDWebServerOption_Port: ConstantsWebServer.defaultServicePort,
                        GCDWebServerOption_BindToLocalhost: true,
                        GCDWebServerOption_AutomaticallySuspendInBackground: false,
                        GCDWebServerOption_ConnectedStateCoalescingInterval: 2.0
                    ]
                )
            } catch let error {
                trace("in webServer start, error = %{public}@", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error, error.localizedDescription)
            }
        }
    }
    
    public func stop() {
        if let webServer = webServer, webServer.isRunning {
            webServer.stop()
        }
    }

    /// share latest readings with http clients
    public func share() {
        
        // unwrap sharedUserDefaults
        guard let sharedUserDefaults = sharedUserDefaults else {
            trace("in webServer share, invalid shared data@", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
            return
        }

        // get last readings with calculated value
        let lastReadings = bgReadingsAccessor.getLatestBgReadings(limit: ConstantsWebServer.maxReadingsToUpload, howOld: ConstantsWebServer.maxBgReadingsDaysToUpload, forSensor: nil, ignoreRawData: false, ignoreCalculatedValue: false)

        // if there's no readings, then no further processing
        if lastReadings.count == 0 {
            return
        }

        // convert to json NightScout Share format
        var dictionary = [Dictionary<String, Any>]()
        for reading in lastReadings {
            let representation = reading.dictionaryRepresentationForNightScoutUpload()
            dictionary.append(representation)
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary) else {
            trace("in webServer share, json serialization failed@", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
            return
        }
        
        sharedUserDefaults.set(data, forKey: "latestNightScoutReadings")
    }

    public func enableSuspension() {
        if let backgroundTask = backgroundTask {
            backgroundTask.enableSuspension()
        }
    }

    public func disableSuspension() {
        if let backgroundTask = backgroundTask {
            backgroundTask.disableSuspension()
        }
    }
}
