//
//  SensorAgeAccessoryCircularView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension SensorAgeComplication.EntryView {
    @ViewBuilder
    var sensorAgeAccessoryCircularView: some View {
        if entry.widgetState.liveDataIsEnabled && entry.widgetState.sensorAgeInMinutes > 0 {
            Gauge(value: entry.widgetState.sensorProgress()) {
                Text("Not shown")
            } currentValueLabel: {
                VStack(spacing: -2) {
                    Text(sensorAgeDaysString())
                        .font(.system(size: 14)).bold()
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                    Text(sensorAgeHoursString())
                        .font(.system(size: 10))
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                }
            } minimumValueLabel: {
                Text("0")
                    .font(.system(size: 8))
                    .foregroundStyle(.colorPrimary)
            } maximumValueLabel: {
                Text(sensorMaxDaysString())
                    .font(.system(size: 8))
                    .foregroundStyle(.colorPrimary)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [.green, .green, .yellow, .orange, .red]))
            .widgetBackground(backgroundView: Color.clear)
        } else {
            Image("ComplicationIcon")
                .resizable()
                .widgetBackground(backgroundView: Color.clear)
        }
    }
    
    private func sensorAgeDaysString() -> String {
        let totalHours = Int(entry.widgetState.sensorAgeInMinutes) / 60
        let days = totalHours / 24
        return "\(days)d"
    }
    
    private func sensorAgeHoursString() -> String {
        let totalHours = Int(entry.widgetState.sensorAgeInMinutes) / 60
        let hours = totalHours % 24
        return "\(hours)h"
    }
    
    private func sensorMaxDaysString() -> String {
        let days = Int(entry.widgetState.sensorMaxAgeInMinutes) / 60 / 24
        return "\(days)d"
    }
}
