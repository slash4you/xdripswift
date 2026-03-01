//
//  TIRAccessoryRectangularView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension TimeInRangeComplication.EntryView {
    @ViewBuilder
    var tirAccessoryRectangularView: some View {
        if entry.widgetState.liveDataIsEnabled && entry.widgetState.timeInRangeValue > 0 {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: entry.widgetState.isSmallScreen() ? 12 : 14))
                        .foregroundStyle(.colorPrimary)
                    
                    Text(Texts_WatchComplication.tirShort + " 24h")
                        .font(.system(size: entry.widgetState.isSmallScreen() ? 12 : 14))
                        .foregroundStyle(.colorPrimary)
                    
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(entry.widgetState.timeInRangeString())
                        .font(.system(size: entry.widgetState.isSmallScreen() ? 20 : 24)).bold()
                        .foregroundStyle(entry.widgetState.timeInRangeColor())
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Label(entry.widgetState.timeBelowRangeString(), systemImage: "arrow.down")
                            .font(.system(size: entry.widgetState.isSmallScreen() ? 10 : 12))
                            .foregroundStyle(.colorPrimary)
                        
                        Label(entry.widgetState.timeAboveRangeString(), systemImage: "arrow.up")
                            .font(.system(size: entry.widgetState.isSmallScreen() ? 10 : 12))
                            .foregroundStyle(.colorPrimary)
                    }
                    .minimumScaleFactor(0.2)
                    .lineLimit(1)
                }
                
                // Stacked bar showing low/in-range/high distribution
                GeometryReader { geometry in
                    HStack(spacing: 1) {
                        if entry.widgetState.timeBelowRangeValue > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.red)
                                .frame(width: max(geometry.size.width * entry.widgetState.timeBelowRangeValue / 100, 2), height: 4)
                        }
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(entry.widgetState.timeInRangeColor())
                            .frame(width: max(geometry.size.width * entry.widgetState.timeInRangeValue / 100, 2), height: 4)
                        
                        if entry.widgetState.timeAboveRangeValue > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.orange)
                                .frame(width: max(geometry.size.width * entry.widgetState.timeAboveRangeValue / 100, 2), height: 4)
                        }
                    }
                }
                .frame(height: 4)
            }
            .widgetBackground(backgroundView: Color.clear)
        } else {
            VStack(alignment: .center, spacing: 2) {
                Image(systemName: "chart.pie")
                    .font(.system(size: entry.widgetState.isSmallScreen() ? 16 : 18)).bold()
                    .foregroundStyle(.teal)
                
                Text(Texts_WatchComplication.noData)
                    .font(.system(size: entry.widgetState.isSmallScreen() ? 14 : 16)).bold()
                    .foregroundStyle(.colorPrimary)
            }
            .widgetBackground(backgroundView: Color.clear)
        }
    }
}
