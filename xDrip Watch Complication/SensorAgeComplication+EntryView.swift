//
//  SensorAgeComplication+EntryView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import SwiftUI
import Foundation

extension SensorAgeComplication {
    struct EntryView: View {
        @Environment(\.widgetFamily) private var widgetFamily
        
        var entry: Entry
        
        var body: some View {
            switch widgetFamily {
            case .accessoryRectangular:
                sensorAgeAccessoryRectangularView
            case .accessoryCircular:
                sensorAgeAccessoryCircularView
            case .accessoryCorner:
                sensorAgeAccessoryCornerView
            case .accessoryInline:
                sensorAgeAccessoryInlineView
            default:
                Image("ComplicationIcon")
            }
        }
    }
}
