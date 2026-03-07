//
//  TIRAccessoryCircularView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension TimeInRangeComplication.EntryView {
    @ViewBuilder
    var tirAccessoryCircularView: some View {
        if entry.widgetState.liveDataIsEnabled && entry.widgetState.timeInRangeValue > 0 {
            Gauge(value: entry.widgetState.timeInRangeValue / 100) {
                Text("Not shown")
            } currentValueLabel: {
                VStack(spacing: -6) {
                    Text("%")
                        .font(.system(size: 10))
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                    Text("\(Int(entry.widgetState.timeInRangeValue))")
                        .font(.system(size: 18)).bold()
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                }
            } minimumValueLabel: {
                Text("0")
                    .font(.system(size: 8))
                    .foregroundStyle(.colorPrimary)
            } maximumValueLabel: {
                Text("100")
                    .font(.system(size: 8))
                    .foregroundStyle(.colorPrimary)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [.red, .orange, .yellow, .green]))
            .widgetBackground(backgroundView: Color.clear)
        } else {
            Image("ComplicationIcon")
                .resizable()
                .widgetBackground(backgroundView: Color.clear)
        }
    }
}
