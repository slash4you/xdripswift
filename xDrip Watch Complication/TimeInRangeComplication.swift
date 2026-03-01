//
//  TimeInRangeComplication.swift
//  xDrip Watch Complication
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import WidgetKit
import SwiftUI

struct TimeInRangeComplication: Widget {
    let kind: String = "TimeInRangeComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeInRangeComplication.Provider()) { entry in
            TimeInRangeComplication.EntryView(entry: entry)
        }
        .configurationDisplayName(Texts_WatchComplication.timeInRange)
        .description("Show the 24-hour time in range percentage")
    }
}

#Preview(as: .accessoryCircular) {
    TimeInRangeComplication()
} timeline: {
    TimeInRangeComplication.Entry.placeholder
}
