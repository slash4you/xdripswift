//
//  SensorAgeAccessoryInlineView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension SensorAgeComplication.EntryView {
    @ViewBuilder
    var sensorAgeAccessoryInlineView: some View {
        if entry.widgetState.liveDataIsEnabled && entry.widgetState.sensorAgeInMinutes > 0 {
            Text("\(Texts_WatchComplication.sensorAge): \(entry.widgetState.sensorAgeString()) (\(entry.widgetState.sensorTimeRemainingString()) \(Texts_WatchComplication.remaining))")
        } else {
            Text("\(ConstantsHomeView.applicationName)")
        }
    }
}
