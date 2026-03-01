//
//  TimeInRangeComplication+EntryView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import SwiftUI
import Foundation

extension TimeInRangeComplication {
    struct EntryView: View {
        @Environment(\.widgetFamily) private var widgetFamily
        
        var entry: Entry
        
        var body: some View {
            switch widgetFamily {
            case .accessoryRectangular:
                tirAccessoryRectangularView
            case .accessoryCircular:
                tirAccessoryCircularView
            case .accessoryCorner:
                tirAccessoryCornerView
            case .accessoryInline:
                tirAccessoryInlineView
            default:
                Image("ComplicationIcon")
            }
        }
    }
}
