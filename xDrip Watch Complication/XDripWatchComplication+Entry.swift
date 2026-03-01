//
//  XDripWatchComplication+Entry.swift
//  xDrip Watch Complication Extension
//
//  Created by Paul Plant on 28/2/24.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import WidgetKit
import SwiftUI

extension XDripWatchComplication {
    struct Entry: TimelineEntry {
        var date: Date = .now
        var widgetState: WidgetState
    }
}

// MARK: - WidgetState

extension XDripWatchComplication.Entry {
    
    /// struct to hold the currect values that the widget/complication should show
    struct WidgetState {
        var bgReadingValues: [Double]?
        var bgReadingDates: [Date]?
        var isMgDl: Bool
        var slopeOrdinal: Int
        var deltaValueInUserUnit: Double?
        var urgentLowLimitInMgDl: Double
        var lowLimitInMgDl: Double
        var highLimitInMgDl: Double
        var urgentHighLimitInMgDl: Double
        var keepAliveIsDisabled: Bool
        var liveDataIsEnabled: Bool
        var sensorAgeInMinutes: Double
        var sensorMaxAgeInMinutes: Double
        var timeInRangeValue: Double
        var timeBelowRangeValue: Double
        var timeAboveRangeValue: Double
        
        var bgUnitString: String
        var bgValueInMgDl: Double?
        var bgReadingDate: Date?
                
        init(bgReadingValues: [Double]? = nil, bgReadingDates: [Date]? = nil, isMgDl: Bool? = true, slopeOrdinal: Int? = 0, deltaValueInUserUnit: Double? = nil, urgentLowLimitInMgDl: Double? = 60, lowLimitInMgDl: Double? = 80, highLimitInMgDl: Double? = 180, urgentHighLimitInMgDl: Double? = 250, keepAliveIsDisabled: Bool? = false, remainingComplicationUserInfoTransfers: Int? = 99, liveDataIsEnabled: Bool? = false, sensorAgeInMinutes: Double? = 0, sensorMaxAgeInMinutes: Double? = 14400, timeInRangeValue: Double? = 0, timeBelowRangeValue: Double? = 0, timeAboveRangeValue: Double? = 0) {
            self.bgReadingValues = bgReadingValues
            self.bgReadingDates = bgReadingDates
            self.isMgDl = isMgDl ?? true
            self.slopeOrdinal = slopeOrdinal ?? 0
            self.deltaValueInUserUnit = deltaValueInUserUnit
            self.urgentLowLimitInMgDl = urgentLowLimitInMgDl ?? 60
            self.lowLimitInMgDl = lowLimitInMgDl ?? 80
            self.highLimitInMgDl = highLimitInMgDl ?? 180
            self.urgentHighLimitInMgDl = urgentHighLimitInMgDl ?? 250
            self.keepAliveIsDisabled = keepAliveIsDisabled ?? false
            self.liveDataIsEnabled = liveDataIsEnabled ?? false
            self.sensorAgeInMinutes = sensorAgeInMinutes ?? 0
            self.sensorMaxAgeInMinutes = sensorMaxAgeInMinutes ?? 14400
            self.timeInRangeValue = timeInRangeValue ?? 0
            self.timeBelowRangeValue = timeBelowRangeValue ?? 0
            self.timeAboveRangeValue = timeAboveRangeValue ?? 0
            
            self.bgValueInMgDl = (bgReadingValues?.count ?? 0) > 0 ? bgReadingValues?[0] : nil
            self.bgReadingDate = (bgReadingDates?.count ?? 0) > 0 ? bgReadingDates?[0] : nil
            self.bgUnitString = self.isMgDl ? Texts_Common.mgdl : Texts_Common.mmol
        }
        
        /// returns blood glucose value as a string in the user-defined measurement unit. Will check and display also high, low and error texts as required.
        /// - Returns: a String with the formatted value/unit or error text
        func bgValueStringInUserChosenUnit() -> String {
            if let bgValueInMgDl = bgValueInMgDl {
                var returnValue: String
                
                if bgValueInMgDl >= 400 {
                    returnValue = Texts_Common.HIGH
                } else if bgValueInMgDl >= 40 {
                    returnValue = bgValueInMgDl.mgDlToMmolAndToString(mgDl: isMgDl)
                } else if bgValueInMgDl > 12 {
                    returnValue = Texts_Common.LOW
                } else {
                    switch bgValueInMgDl {
                    case 0:
                        returnValue = "??0"
                    case 1:
                        returnValue = "?SN"
                    case 2:
                        returnValue = "??2"
                    case 3:
                        returnValue = "?NA"
                    case 5:
                        returnValue = "?NC"
                    case 6:
                        returnValue = "?CD"
                    case 9:
                        returnValue = "?AD"
                    case 12:
                        returnValue = "?RF"
                    default:
                        returnValue = "???"
                    }
                }
                return returnValue
            } else {
                return isMgDl ? "---" : "-.-"
            }
        }
        
        /// Blood glucose color dependant on the user defined limit values
        /// - Returns: a Color either red, yellow or green
        func bgTextColor() -> Color {
            if let bgValueInMgDl = bgValueInMgDl {
                if bgValueInMgDl >= urgentHighLimitInMgDl || bgValueInMgDl <= urgentLowLimitInMgDl {
                    return .red
                } else if bgValueInMgDl >= highLimitInMgDl || bgValueInMgDl <= lowLimitInMgDl {
                    return .yellow
                } else {
                    return .green
                }
            } else {
                // this would never usually be returned in real use but it keeps the compiler happy
                return .colorSecondary
            }
        }
        
        /// convert the optional delta change int (in mg/dL) to a formatted change value in the user chosen unit making sure all zero values are shown as a positive change to follow Nightscout convention
        /// - Returns: a string holding the formatted delta change value (i.e. +0.4 or -6)
        func deltaChangeStringInUserChosenUnit() -> String {
            if let deltaValueInUserUnit = deltaValueInUserUnit {
                let deltaSign: String = deltaValueInUserUnit > 0 ? "+" : "" 
                let deltaValueAsString = isMgDl ? deltaValueInUserUnit.mgDlToMmolAndToString(mgDl: isMgDl) : deltaValueInUserUnit.mmolToString()
                
                // quickly check "value" and prevent "-0mg/dl" or "-0.0mmol/l" being displayed
                // show unitized zero deltas as +0 or +0.0 as per Nightscout format
                return deltaValueInUserUnit == 0.0 ? (isMgDl ? "+0" : "+0.0") : (deltaSign + deltaValueAsString)
            }
            return ""
        }
        
        
        ///  returns a string holding the trend arrow
        /// - Returns: trend arrow string (i.e.  "↑")
        func trendArrow() -> String {
            switch slopeOrdinal {
            case 7:
                return "\u{2193}\u{2193}" // ↓↓
            case 6:
                return "\u{2193}" // ↓
            case 5:
                return "\u{2198}" // ↘
            case 4:
                return "\u{2192}" // →
            case 3:
                return "\u{2197}" // ↗
            case 2:
                return "\u{2191}" // ↑
            case 1:
                return "\u{2191}\u{2191}" // ↑↑
            default:
                return ""
            }
        }
        
        /// used to return values and colors used by a SwiftUI gauge view
        /// - Returns: minValue/maxValue - used to define the limits of the gauge. nilValue - used if there is currently no data present (basically puts the gauge at the 50% mark). gaugeGradient - the color ranges used
        func gaugeModel() -> (minValue: Double, maxValue: Double, nilValue: Double, gaugeColor: Color, gaugeGradient: Gradient) {
            
            var minValue: Double = lowLimitInMgDl
            var maxValue: Double = highLimitInMgDl
            var gaugeColor: Color = .green
            var colorArray = [Color]()
                    
            if let bgValueInMgDl = bgValueInMgDl {
                if bgValueInMgDl >= urgentHighLimitInMgDl {
                    maxValue = ConstantsCalibrationAlgorithms.maximumBgReadingCalculatedValue
                    gaugeColor = .red
                } else if bgValueInMgDl >= highLimitInMgDl {
                    maxValue = urgentHighLimitInMgDl
                    gaugeColor = .red
                }
                
                if bgValueInMgDl <= urgentLowLimitInMgDl {
                    minValue = ConstantsCalibrationAlgorithms.minimumBgReadingCalculatedValue
                    gaugeColor = .yellow
                } else if bgValueInMgDl <= lowLimitInMgDl {
                    minValue = urgentLowLimitInMgDl
                    gaugeColor = .yellow
                }
            }
            
            // let's round the min value down to nearest 10 and the max up to nearest 10
            // this is to start creating the gradient ranges
            let minValueRoundedDown = Double(10 * Int(minValue/10))
            let maxValueRoundedUp = Double(10 * Int(maxValue/10)) + 10
            
            // the prevent the gradient changes from being too sharp, we'll reduce the granularity if trying to show a big range
            // step through the range and append the colors as necessary
            for currentValue in stride(from: minValueRoundedDown, through: maxValueRoundedUp, by: (maxValueRoundedUp - minValueRoundedDown) > 200 ? 20 : 10) {
                if currentValue > urgentHighLimitInMgDl || currentValue <= urgentLowLimitInMgDl {
                    colorArray.append(Color.red)
                } else if currentValue > highLimitInMgDl || currentValue <= lowLimitInMgDl {
                    colorArray.append(Color.yellow)
                } else {
                    colorArray.append(Color.green)
                }
            }
            
            // calculate a nil value to show on the gauge (as it can't display nil). This should basically just peg the gauge indicator in the middle of the current range
            let nilValue =  minValue + ((maxValue - minValue) / 2)
            
            return (minValue, maxValue, nilValue, gaugeColor, Gradient(colors: colorArray))
        }
        
        /// returns the sensor age formatted as days and hours (e.g. "9d 14h")
        func sensorAgeString() -> String {
            guard sensorAgeInMinutes > 0 else { return "---" }
            let totalHours = Int(sensorAgeInMinutes) / 60
            let days = totalHours / 24
            let hours = totalHours % 24
            if days > 0 {
                return "\(days)d \(hours)h"
            } else {
                return "\(hours)h"
            }
        }
        
        /// returns the sensor time remaining formatted as days and hours (e.g. "4d 10h")
        func sensorTimeRemainingString() -> String {
            guard sensorAgeInMinutes > 0, sensorMaxAgeInMinutes > 0 else { return "---" }
            let remainingMinutes = sensorMaxAgeInMinutes - sensorAgeInMinutes
            guard remainingMinutes > 0 else { return Texts_WatchComplication.sensorExpired }
            let totalHours = Int(remainingMinutes) / 60
            let days = totalHours / 24
            let hours = totalHours % 24
            if days > 0 {
                return "\(days)d \(hours)h"
            } else {
                return "\(hours)h"
            }
        }
        
        /// returns the sensor progress as a value between 0 and 1
        func sensorProgress() -> Double {
            guard sensorMaxAgeInMinutes > 0 else { return 0 }
            return min(sensorAgeInMinutes / sensorMaxAgeInMinutes, 1.0)
        }
        
        /// returns the color for the sensor age based on remaining time
        func sensorAgeColor() -> Color {
            guard sensorAgeInMinutes > 0, sensorMaxAgeInMinutes > 0 else { return .gray }
            let remainingMinutes = sensorMaxAgeInMinutes - sensorAgeInMinutes
            if remainingMinutes < 0 {
                return ConstantsHomeView.sensorProgressExpiredSwiftUI
            } else if remainingMinutes <= ConstantsHomeView.sensorProgressViewUrgentInMinutes {
                return ConstantsHomeView.sensorProgressViewProgressColorUrgentSwiftUI
            } else if remainingMinutes <= ConstantsHomeView.sensorProgressViewWarningInMinutes {
                return ConstantsHomeView.sensorProgressViewProgressColorWarningSwiftUI
            } else {
                return ConstantsHomeView.sensorProgressNormalTextColorSwiftUI
            }
        }
        
        /// returns the time in range color based on the percentage
        func timeInRangeColor() -> Color {
            if timeInRangeValue >= 70 {
                return .green
            } else if timeInRangeValue >= 50 {
                return .yellow
            } else if timeInRangeValue > 0 {
                return .orange
            } else {
                return .gray
            }
        }
        
        /// returns time in range formatted as a percentage string (e.g. "85%")
        func timeInRangeString() -> String {
            guard timeInRangeValue > 0 else { return "---" }
            return "\(Int(timeInRangeValue))%"
        }
        
        /// returns time below range formatted as a percentage string
        func timeBelowRangeString() -> String {
            guard timeBelowRangeValue > 0 || timeInRangeValue > 0 else { return "---" }
            return "\(Int(timeBelowRangeValue))%"
        }
        
        /// returns time above range formatted as a percentage string
        func timeAboveRangeString() -> String {
            guard timeAboveRangeValue > 0 || timeInRangeValue > 0 else { return "---" }
            return "\(Int(timeAboveRangeValue))%"
        }
        
        func isSmallScreen() -> Bool {
            return (WKInterfaceDevice.current().screenBounds.size.width < ConstantsAppleWatch.pixelWidthLimitForSmallScreen) ? true : false
        }
        
        func overrideChartHeight() -> Double {
            var height = isSmallScreen() ? ConstantsGlucoseChartSwiftUI.viewHeightWatchAccessoryRectangularSmall : ConstantsGlucoseChartSwiftUI.viewHeightWatchAccessoryRectangular
            
            height += keepAliveIsDisabled ? -15 : 0
            
            return height
        }
        
        func overrideChartWidth() -> Double {
            return isSmallScreen() ? ConstantsGlucoseChartSwiftUI.viewWidthWatchAccessoryRectangularSmall : ConstantsGlucoseChartSwiftUI.viewWidthWatchAccessoryRectangular
        }
        
    }
}

// MARK: - Data

extension XDripWatchComplication.Entry {
    static var placeholder: Self {
        .init(date: .now, widgetState: WidgetState(bgReadingValues: ConstantsWatchComplication.bgReadingValuesPlaceholderData, bgReadingDates: ConstantsWatchComplication.bgReadingDatesPlaceholderData(), isMgDl: true, slopeOrdinal: 4, deltaValueInUserUnit: 0, urgentLowLimitInMgDl: 70, lowLimitInMgDl: 90, highLimitInMgDl: 140, urgentHighLimitInMgDl: 180, keepAliveIsDisabled: false, liveDataIsEnabled: true, sensorAgeInMinutes: 13500, sensorMaxAgeInMinutes: 14400, timeInRangeValue: 85, timeBelowRangeValue: 5, timeAboveRangeValue: 10))
    }
}
