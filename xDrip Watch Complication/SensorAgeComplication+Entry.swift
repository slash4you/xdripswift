//
//  SensorAgeComplication+Entry.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import WidgetKit
import SwiftUI

extension SensorAgeComplication {
    struct Entry: TimelineEntry {
        var date: Date = .now
        var widgetState: XDripWatchComplication.Entry.WidgetState
    }
}

// MARK: - Data

extension SensorAgeComplication.Entry {
    static var placeholder: Self {
        .init(date: .now, widgetState: XDripWatchComplication.Entry.WidgetState(bgReadingValues: ConstantsWatchComplication.bgReadingValuesPlaceholderData, bgReadingDates: ConstantsWatchComplication.bgReadingDatesPlaceholderData(), isMgDl: true, slopeOrdinal: 4, deltaValueInUserUnit: 0, urgentLowLimitInMgDl: 70, lowLimitInMgDl: 90, highLimitInMgDl: 140, urgentHighLimitInMgDl: 180, keepAliveIsDisabled: false, liveDataIsEnabled: true, sensorAgeInMinutes: 13500, sensorMaxAgeInMinutes: 14400))
    }
}
