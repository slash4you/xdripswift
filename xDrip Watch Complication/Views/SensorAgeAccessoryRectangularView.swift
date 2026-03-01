//
//  SensorAgeAccessoryRectangularView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension SensorAgeComplication.EntryView {
    @ViewBuilder
    var sensorAgeAccessoryRectangularView: some View {
        if entry.widgetState.liveDataIsEnabled && entry.widgetState.sensorAgeInMinutes > 0 {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center) {
                    Image(systemName: "sensor.tag.radiowaves.forward")
                        .font(.system(size: entry.widgetState.isSmallScreen() ? 12 : 14))
                        .foregroundStyle(.colorPrimary)
                    
                    Text(Texts_WatchComplication.sensorAge)
                        .font(.system(size: entry.widgetState.isSmallScreen() ? 12 : 14))
                        .foregroundStyle(.colorPrimary)
                    
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(entry.widgetState.sensorAgeString())
                        .font(.system(size: entry.widgetState.isSmallScreen() ? 20 : 24)).bold()
                        .foregroundStyle(entry.widgetState.sensorAgeColor())
                    
                    Spacer()
                    
                    Text(entry.widgetState.sensorTimeRemainingString() + " " + Texts_WatchComplication.remaining)
                        .font(.system(size: entry.widgetState.isSmallScreen() ? 12 : 14))
                        .foregroundStyle(.colorPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.2)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(entry.widgetState.sensorAgeColor())
                            .frame(width: geometry.size.width * entry.widgetState.sensorProgress(), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .widgetBackground(backgroundView: Color.clear)
        } else {
            VStack(alignment: .center, spacing: 2) {
                Image(systemName: "sensor.tag.radiowaves.forward")
                    .font(.system(size: entry.widgetState.isSmallScreen() ? 16 : 18)).bold()
                    .foregroundStyle(.teal)
                
                Text(Texts_WatchComplication.noSensor)
                    .font(.system(size: entry.widgetState.isSmallScreen() ? 14 : 16)).bold()
                    .foregroundStyle(.colorPrimary)
            }
            .widgetBackground(backgroundView: Color.clear)
        }
    }
}
