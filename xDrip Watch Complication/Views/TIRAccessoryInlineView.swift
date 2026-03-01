//
//  TIRAccessoryInlineView.swift
//  xDrip Watch Complication Extension
//
//  Created by Claude on 1/3/26.
//  Copyright © 2026 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

extension TimeInRangeComplication.EntryView {
    @ViewBuilder
    var tirAccessoryInlineView: some View {
        if entry.widgetState.liveDataIsEnabled && entry.widgetState.timeInRangeValue > 0 {
            Text("\(Texts_WatchComplication.tirShort): \(entry.widgetState.timeInRangeString()) ↓\(entry.widgetState.timeBelowRangeString()) ↑\(entry.widgetState.timeAboveRangeString())")
        } else {
            Text("\(ConstantsHomeView.applicationName)")
        }
    }
}
