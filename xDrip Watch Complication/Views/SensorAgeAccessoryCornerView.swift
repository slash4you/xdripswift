//
//  SensorAgeAccessoryCornerView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension SensorAgeComplication.EntryView {
    @ViewBuilder
    var sensorAgeAccessoryCornerView: some View {
        if entry.widgetState.liveDataIsEnabled && entry.widgetState.sensorAgeInMinutes > 0 {
            Text(entry.widgetState.sensorAgeString())
                .font(.system(size: 20))
                .foregroundColor(entry.widgetState.sensorAgeColor())
                .minimumScaleFactor(0.2)
                .widgetCurvesContent()
                .widgetLabel {
                    Gauge(value: entry.widgetState.sensorProgress()) {
                        Text("Not shown")
                    } currentValueLabel: {
                        Text("Not shown")
                    } minimumValueLabel: {
                        Text("0d")
                            .font(.system(size: 8))
                            .foregroundStyle(.colorPrimary)
                            .minimumScaleFactor(0.2)
                    } maximumValueLabel: {
                        Text("\(Int(entry.widgetState.sensorMaxAgeInMinutes) / 60 / 24)d")
                            .font(.system(size: 8))
                            .foregroundStyle(.colorPrimary)
                            .minimumScaleFactor(0.2)
                    }
                    .tint(Gradient(colors: [.green, .green, .yellow, .orange, .red]))
                    .gaugeStyle(LinearCapacityGaugeStyle())
                }
                .widgetBackground(backgroundView: Color.clear)
        } else {
            Text(" ")
                .font(.system(size: 20))
                .minimumScaleFactor(0.2)
                .widgetCurvesContent()
                .widgetLabel("\(ConstantsHomeView.applicationName)")
                .widgetBackground(backgroundView: Color.clear)
        }
    }
}
