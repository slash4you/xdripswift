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

    private var backgroundTask : BackgroundTask?

    public weak var delegate: WebServerDelegateProtocol?

    /// initializer
    public init(coreDataManager: CoreDataManager, healthDelegate: WebServerDelegateProtocol) {

        self.coreDataManager = coreDataManager
        self.bgReadingsAccessor = BgReadingsAccessor(coreDataManager: coreDataManager)
        self.sensorAccessor = SensorsAccessor(coreDataManager: coreDataManager)
        self.webServer = GCDWebServer()
        self.delegate = healthDelegate
        
        self.backgroundTask = BackgroundTask()
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
                            trace("in webServer handler, invalid count type", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                            return GCDWebServerErrorResponse(statusCode: 500)
                        }
                    } else {
                        trace("in webServer handler, count arg not found", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                        return GCDWebServerErrorResponse(statusCode: 500)
                    }
                    if let heartArg = query["heart"] {
                        if let heartInt = Int(heartArg) {
                            self.delegate!.receivedHealthData(heart: heartInt)
                        }
                    }
                    if let stepsArg = query["steps"] {
                        if let stepsInt = Int(stepsArg) {
                            self.delegate!.receivedHealthData(steps: stepsInt)
                        }
                    }
                } else {
                    trace("in webServer handler, invalid query type", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                    return GCDWebServerErrorResponse(statusCode: 500)
                }

                // JSON serialization
                var json = [AnyObject]()
                if let dictionary = UserDefaults.standard.nightscoutReadings {
                    if let jsonAsData = try? JSONSerialization.data(withJSONObject: dictionary) {
                        if let jsonAsObject = try? JSONSerialization.jsonObject(with: jsonAsData, options: []) {
                            if let sgvs = jsonAsObject as? [AnyObject] {
                                // get only the last maxReadingsNumber readings
                                for sgv in sgvs.prefix(maxReadingsNumber) {
                                    json.append(sgv)
                                }
                            } else {
                                trace("in webServer handler, invalid json object type", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                                return GCDWebServerErrorResponse(statusCode: 500)
                            }
                        } else {
                            trace("in webServer handler, json object serialization failed", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                            return GCDWebServerErrorResponse(statusCode: 500)
                        }
                    } else {
                        trace("in webServer handler, json data serialization failed", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                        return GCDWebServerErrorResponse(statusCode: 500)
                    }
                } else {
                    trace("in webServer handler, invalid shared type", log: self.log, category: ConstantsLog.categoryWebServerController, type: .error)
                    return GCDWebServerErrorResponse(statusCode: 500)
                }

                // Successfull response with serialized json data
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
    public func share() -> Void {
        
        // get last readings with calculated value
        let lastReadings = bgReadingsAccessor.getLatestBgReadings(limit: ConstantsWebServer.maxReadingsToUpload, howOld: ConstantsWebServer.maxBgReadingsDaysToUpload, forSensor: nil, ignoreRawData: false, ignoreCalculatedValue: false)

        // if there's no readings, then no further processing
        if lastReadings.count == 0 {
            return
        }

        // convert to NightScout representation
        var dictionary = [Dictionary<String, Any>]()
        for reading in lastReadings {
            let representation = reading.dictionaryRepresentationForNightScoutUpload()
            dictionary.append(representation)
        }
                
        // share data
        UserDefaults.standard.nightscoutReadings = dictionary
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
