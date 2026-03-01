//
//  SensorAgeComplication.swift
//  xDrip Watch Complication
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import WidgetKit
import SwiftUI

struct SensorAgeComplication: Widget {
    let kind: String = "SensorAgeComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SensorAgeComplication.Provider()) { entry in
            SensorAgeComplication.EntryView(entry: entry)
        }
        .configurationDisplayName(Texts_WatchComplication.sensorAge)
        .description("Show the current sensor age and remaining time")
    }
}

#Preview(as: .accessoryCircular) {
    SensorAgeComplication()
} timeline: {
    SensorAgeComplication.Entry.placeholder
}
