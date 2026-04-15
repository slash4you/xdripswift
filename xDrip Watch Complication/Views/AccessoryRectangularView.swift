//
//  AccessoryRectangularView.swift
//  xDrip Watch Complication Extension
//
//  Created by Paul Plant on 4/3/24.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension XDripWatchComplication.EntryView {
    @ViewBuilder
    
    var accessoryRectangularView: some View {
        ZStack {
            if entry.widgetState.liveDataIsEnabled {
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        HStack(alignment: .center, spacing: 4) {
                            Text("\(entry.widgetState.bgValueStringInUserChosenUnit())\(entry.widgetState.trendArrow()) ")
                                .font(.system(size: entry.widgetState.isSmallScreen() ? 20 : 24)).bold()
                                .foregroundStyle(entry.widgetState.bgTextColor())
                            
                            Text(entry.widgetState.deltaChangeStringInUserChosenUnit())
                                .font(.system(size: entry.widgetState.isSmallScreen() ? 20 : 24)).fontWeight(.semibold)
                                .foregroundStyle(.colorPrimary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text("\(entry.widgetState.bgReadingDate?.formatted(date: .omitted, time: .shortened) ?? "--:--")")
                            .font(.system(size: entry.widgetState.isSmallScreen() ? 15 : 17))
                            .foregroundStyle(.colorPrimary)
                            .minimumScaleFactor(0.2)
                    }
                    .padding(0)
                    
                    GlucoseChartView(glucoseChartType: .watchAccessoryRectangular, bgReadingValues: entry.widgetState.bgReadingValues, bgReadingDates: entry.widgetState.bgReadingDates, isMgDl: entry.widgetState.isMgDl, urgentLowLimitInMgDl: entry.widgetState.urgentLowLimitInMgDl, lowLimitInMgDl: entry.widgetState.lowLimitInMgDl, highLimitInMgDl: entry.widgetState.highLimitInMgDl, urgentHighLimitInMgDl: entry.widgetState.urgentHighLimitInMgDl, liveActivityType: nil, hoursToShowScalingHours: nil, glucoseCircleDiameterScalingHours: nil, overrideChartHeight: entry.widgetState.overrideChartHeight(), overrideChartWidth: entry.widgetState.overrideChartWidth(), highContrast: nil)
                    
                    if entry.widgetState.keepAliveIsDisabled {
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: entry.widgetState.isSmallScreen() ? 12 : 14))
                            
                            Text(Texts_WatchComplication.keepAliveDisabled)
                                .font(.system(size: entry.widgetState.isSmallScreen() ? 12 : 14))
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(.teal)
                        .padding(0)
                    }
                }
            } else {
                VStack(alignment: .center, spacing: 2) {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: entry.widgetState.isSmallScreen() ? 16 : 18)).bold()
                        
                        Text(Texts_WatchComplication.liveDataDisabled)
                            .font(.system(size: entry.widgetState.isSmallScreen() ? 16 : 18)).bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.2)
                    }
                    .foregroundStyle(.teal)
                    .padding(0)
                    
                    accessoryRectangularDisabledText
                }
            }
        }
        .widgetBackground(backgroundView: Color.clear)
    }

    private var accessoryRectangularDisabledText: Text {
        let fontSize: CGFloat = entry.widgetState.isSmallScreen() ? 10 : 14
        let primaryFont = Font.system(size: fontSize)
        let boldFont = Font.system(size: fontSize).bold()

        let goTo = Text(Texts_WatchComplication.goTo)
            .font(primaryFont)
            .foregroundStyle(.colorPrimary)
        let appName = Text(ConstantsHomeView.applicationName)
            .font(boldFont)
            .foregroundStyle(.white)
        let arrow1 = Text(" -> ")
            .font(primaryFont)
            .foregroundStyle(.colorPrimary)
        let settings = Text(Texts_WatchComplication.settings)
            .font(boldFont)
            .foregroundStyle(.white)
        let arrow2 = Text(" -> ")
            .font(primaryFont)
            .foregroundStyle(.colorPrimary)
        let appleWatch = Text(Texts_WatchComplication.appleWatch + " ")
            .font(boldFont)
            .foregroundStyle(.white)
        let toEnable = Text(Texts_WatchComplication.toEnable)
            .font(primaryFont)
            .foregroundStyle(.colorPrimary)

        return goTo + appName + arrow1 + settings + arrow2 + appleWatch + toEnable
    }
}
