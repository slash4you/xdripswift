//
//  TIRAccessoryCornerView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension TimeInRangeComplication.EntryView {
    @ViewBuilder
    var tirAccessoryCornerView: some View {
        if entry.widgetState.liveDataIsEnabled && entry.widgetState.timeInRangeValue > 0 {
            Text(entry.widgetState.timeInRangeString())
                .font(.system(size: 20))
                .foregroundColor(entry.widgetState.timeInRangeColor())
                .minimumScaleFactor(0.2)
                .widgetCurvesContent()
                .widgetLabel {
                    Gauge(value: entry.widgetState.timeInRangeValue / 100) {
                        Text("Not shown")
                    } currentValueLabel: {
                        Text("Not shown")
                    } minimumValueLabel: {
                        Text("0%")
                            .font(.system(size: 8))
                            .foregroundStyle(.colorPrimary)
                            .minimumScaleFactor(0.2)
                    } maximumValueLabel: {
                        Text("100%")
                            .font(.system(size: 8))
                            .foregroundStyle(.colorPrimary)
                            .minimumScaleFactor(0.2)
                    }
                    .tint(Gradient(colors: [.red, .orange, .yellow, .green]))
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
