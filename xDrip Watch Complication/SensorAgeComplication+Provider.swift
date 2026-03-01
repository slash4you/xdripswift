//
//  SensorAgeComplication+Provider.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import SwiftUI
import WidgetKit
import Foundation

extension SensorAgeComplication {
    struct Provider: TimelineProvider {
        
        func placeholder(in context: Context) -> Entry {
            .placeholder
        }
        
        func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
            completion(.placeholder)
        }
        
        func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
            let widgetState = getWidgetStateFromSharedUserDefaults() ?? sampleWidgetState
            let entry = Entry(date: .now, widgetState: widgetState)
            completion(.init(entries: [entry], policy: .never))
        }
    }
}

// MARK: - Helpers

extension SensorAgeComplication.Provider {
    func getWidgetStateFromSharedUserDefaults() -> XDripWatchComplication.Entry.WidgetState? {
        guard let sharedUserDefaults = UserDefaults(suiteName: Bundle.main.appGroupSuiteName) else { return nil }
        
        guard let encodedLatestReadings = sharedUserDefaults.data(forKey: "complicationSharedUserDefaults.\(Bundle.main.mainAppBundleIdentifier)") else {
            return nil
        }
        
        let decoder = JSONDecoder()

        do {
            let data = try decoder.decode(ComplicationSharedUserDefaultsModel.self, from: encodedLatestReadings)
            
            let bgReadingDates: [Date] = data.bgReadingDatesAsDouble.map { date in
                Date(timeIntervalSince1970: date)
            }
            
            return XDripWatchComplication.Entry.WidgetState(bgReadingValues: data.bgReadingValues, bgReadingDates: bgReadingDates, isMgDl: data.isMgDl, slopeOrdinal: data.slopeOrdinal, deltaValueInUserUnit: data.deltaValueInUserUnit, urgentLowLimitInMgDl: data.urgentLowLimitInMgDl, lowLimitInMgDl: data.lowLimitInMgDl, highLimitInMgDl: data.highLimitInMgDl, urgentHighLimitInMgDl: data.urgentHighLimitInMgDl, keepAliveIsDisabled: data.keepAliveIsDisabled, liveDataIsEnabled: data.liveDataIsEnabled, sensorAgeInMinutes: data.sensorAgeInMinutes, sensorMaxAgeInMinutes: data.sensorMaxAgeInMinutes)
        } catch {
            print(error.localizedDescription)
        }
              
        return sampleWidgetState
    }
    
    private var sampleWidgetState: XDripWatchComplication.Entry.WidgetState {
        return XDripWatchComplication.Entry.WidgetState(bgReadingValues: ConstantsWatchComplication.bgReadingValuesPlaceholderData, bgReadingDates: ConstantsWatchComplication.bgReadingDatesPlaceholderData(), isMgDl: true, slopeOrdinal: 4, deltaValueInUserUnit: 0, urgentLowLimitInMgDl: 70, lowLimitInMgDl: 90, highLimitInMgDl: 140, urgentHighLimitInMgDl: 180, liveDataIsEnabled: true, sensorAgeInMinutes: 13500, sensorMaxAgeInMinutes: 14400)
    }
}
