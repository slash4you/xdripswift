//
//  xDrip4iOS_WidgetKit.swift
//  xDrip4iOS WidgetKit
//
//  Created by Stéphane LE HIR on 29/10/2022.
//  Copyright © 2022 Johan Degraeve. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    
    public typealias Entry = SimpleEntry

    private var xDripClient: XDripClient = XDripClient()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), glucose: 0.0, trend: "\u{2192}", delta: 0.0, since: Date())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), glucose: 0.0, trend: "\u{2192}", delta: 0.0, since: Date())
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        //let nextDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        
        xDripClient.fetchLast(2, callback:  { (error, glucoseArray) in

            if error != nil {
                let entries = [
                    SimpleEntry(date: currentDate, glucose: 0.0, trend: "\u{2192}", delta: 0.0, since: Date()),
                ]
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
                return
            }

            guard let glucoseArray = glucoseArray, glucoseArray.count > 0 else {
                let entries = [
                    SimpleEntry(date: currentDate, glucose: 0.0, trend: "\u{2192}", delta: 0.0, since: Date()),
                ]
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
                return
            }

            // assign last reading
            let lastReading = glucoseArray[0]
            // assign last but one reading
            let lastButOneReading = glucoseArray.count > 1 ? glucoseArray[1] : nil

            var valueMgDL : Double = 0.0
            var trendAsString : String = "\u{2192}"
            // if latestReading is older than 11 minutes, then it should be strikethrough
            if (lastReading.timestamp >= Date(timeIntervalSinceNow: -60 * 11)) {
                valueMgDL = Double(lastReading.glucose)
                // if lastButOneReading is available and is less than maxSlopeInMinutes earlier than lastReading, then show slopeArrow
                if let lastButOneReading = lastButOneReading {
                    if (lastReading.timestamp.timeIntervalSince(lastButOneReading.timestamp) <= Double(ConstantsBGGraphBuilder.maxSlopeInMinutes * 60)) {
                        // don't show delta if there are not enough values or the values are more than 20 mintes apart
                        trendAsString = slopeArrow(slopeOrdinal: lastReading.trend)
                    }
                }
            }

            // get minutes ago and create text for minutes ago label
            //let minutesAgo : Int = -Int(lastReading.timestamp.timeIntervalSinceNow) / 60
            
            // get delta from last measure
            let deltaValueMgDL : Double = calculateDelta(bgReading: lastReading, previousBgReading: lastButOneReading)
            
            let entries = [
                SimpleEntry(date: currentDate, glucose: valueMgDL, trend: trendAsString, delta: deltaValueMgDL, since: lastReading.timestamp)
            ]
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)

        })


    }
    
    /// creates string with bg value in correct unit or "HIGH" or "LOW", or other like ???
    private func unitizedString(calculatedValue: Double, unitIsMgDl:Bool) -> String {
        var returnValue:String
        if (calculatedValue >= 400) {
            returnValue = "HI"
        } else if (calculatedValue >= 40) {
            returnValue = calculatedValue.mgdlToMmolAndToString(mgdl: unitIsMgDl)
        } else if (calculatedValue > 12) {
            returnValue = "LO"
        } else {
            switch(calculatedValue) {
            case 0:
                returnValue = "??0"
                break
            case 1:
                returnValue = "?SN"
                break
            case 2:
                returnValue = "??2"
                break
            case 3:
                returnValue = "?NA"
                break
            case 5:
                returnValue = "?NC"
                break
            case 6:
                returnValue = "?CD"
                break
            case 9:
                returnValue = "?AD"
                break
            case 12:
                returnValue = "?RF"
                break
            default:
                returnValue = "???"
                break
            }
        }
        return returnValue
    }
    
    private func slopeArrow(slopeOrdinal: UInt8) -> String {

        switch slopeOrdinal {
        
        case 7:
            return "\u{2193}\u{2193}"
            
        case 6:
            return "\u{2193}"
            
        case 5:
            return "\u{2198}"
            
        case 4:
            return "\u{2192}"
            
        case 3:
            return "\u{2197}"
            
        case 2:
            return "\u{2191}"
            
        case 1:
            return "\u{2191}\u{2191}"
            
        default:
            return ""
            
        }
       
    }
    
    
    private func calculateDelta(bgReading:Glucose, previousBgReading:Glucose?) -> Double {
        guard let previousBgReading = previousBgReading else {
            return 0.0
        }
        
        if bgReading.timestamp.timeIntervalSince(previousBgReading.timestamp) > Double(ConstantsBGGraphBuilder.maxSlopeInMinutes * 60) {
            // don't show delta if there are not enough values or the values are more than 20 mintes apart
            return 0.0
        }
        
        // delta value recalculated aligned with time difference between previous and this reading
        let value = currentSlope(thisBgReading: bgReading, previousBgReading: previousBgReading) * bgReading.timestamp.timeIntervalSince(previousBgReading.timestamp) * 1000;
        
        if(abs(value) > 100){
            // a delta > 100 will not happen with real BG values -> problematic sensor data
            return 0.0
        }

        return Double(value)
    }
    
    /// creates string with difference from previous reading and also unit
    private func unitizedDeltaString(bgReading:Glucose, previousBgReading:Glucose?, mgdl:Bool) -> String {
        
        guard let previousBgReading = previousBgReading else {
            return "???"
        }
        
        if bgReading.timestamp.timeIntervalSince(previousBgReading.timestamp) > Double(ConstantsBGGraphBuilder.maxSlopeInMinutes * 60) {
            // don't show delta if there are not enough values or the values are more than 20 mintes apart
            return "???";
        }
        
        // delta value recalculated aligned with time difference between previous and this reading
        let value = currentSlope(thisBgReading: bgReading, previousBgReading: previousBgReading) * bgReading.timestamp.timeIntervalSince(previousBgReading.timestamp) * 1000;
        
        if(abs(value) > 100){
            // a delta > 100 will not happen with real BG values -> problematic sensor data
            return "ERR";
        }
        
        let valueAsString = value.mgdlToMmolAndToString(mgdl: mgdl)
        
        var deltaSign:String = ""
        if (value > 0) { deltaSign = "+"; }
        
        // quickly check "value" and prevent "-0mg/dl" or "-0.0mmol/l" being displayed
        if (mgdl) {
            if (value > -1) && (value < 1) {
                return "0" + " mg/dL";
            } else {
                return deltaSign + valueAsString + " mg/dL";
            }
        } else {
            if (value > -0.1) && (value < 0.1) {
                return "0.0" + " mmol/L" ;
            } else {
                return deltaSign + valueAsString + " mmol/L";
            }
        }
    }
    
    private func currentSlope(thisBgReading:Glucose, previousBgReading:Glucose?) -> Double {
        
        if let previousBgReading = previousBgReading {
            let (slope,_) = calculateSlope(thisBgReading: thisBgReading, previousBgReading: previousBgReading);
            return slope
        } else {
            return 0.0
        }
        
    }
    
    private func calculateSlope(thisBgReading:Glucose, previousBgReading:Glucose) -> (Double, Bool) {
        
        if thisBgReading.timestamp == previousBgReading.timestamp
            ||
            thisBgReading.timestamp.toMillisecondsAsDouble() - previousBgReading.timestamp.toMillisecondsAsDouble() > Double(ConstantsBGGraphBuilder.maxSlopeInMinutes * 60 * 1000) {
            return (0,true)
        }
        
        return ( ( Double(previousBgReading.glucose) - Double(thisBgReading.glucose) ) / (previousBgReading.timestamp.toMillisecondsAsDouble() - thisBgReading.timestamp.toMillisecondsAsDouble()), false)
        
    }
    
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let glucose: Double
    let trend: String
    let delta: Double
    let since: Date
}

struct LabeledGauge: View {
    let current : Double
    let since : Date
    let trend : String

    var body: some View {
        Gauge(value: current, in: 50.0...180.0) {
            Text("")
        } currentValueLabel: {
            Text("\(current, specifier: "%.0f")")
                .font(.headline)
                .foregroundColor(.primary)
                .privacySensitive()
        } minimumValueLabel: {
            Text("\(-since.timeIntervalSinceNow/60.0, specifier: "%.0f")m")
                .foregroundColor(.primary)
                .privacySensitive()
        } maximumValueLabel: {
            Text("\(trend)")
                .foregroundColor(.primary)
                .privacySensitive()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.mint)
        .privacySensitive()
    }
}

struct xDrip4iOS_WidgetKitEntryView : View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var family
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular:
            LabeledGauge(current: entry.glucose, since: entry.since, trend: entry.trend)
                .privacySensitive()
        case .accessoryRectangular:
            HStack {
                LabeledGauge(current: entry.glucose, since: entry.since, trend: entry.trend)
                VStack(spacing: -10) {
                    Text("\(entry.trend)")
                        .font(.title)
                    Text("\(entry.delta, specifier: "%.0f") mg/dL")
                        .font(.headline)
                }.offset(y:-10)
            }
            .privacySensitive()
        case .accessoryInline:
            Text("\(entry.glucose, specifier: "%.0f") \(entry.trend)  \(entry.delta, specifier: "%.0f")mg/dL \(-entry.since.timeIntervalSinceNow/60.0, specifier: "%.0f")m")
                .privacySensitive()
        default:
            ZStack {
                ContainerRelativeShape()
                    .inset(by: 0)
                    .fill(Color(.gray).opacity(0.22))
                VStack {
                    LabeledGauge(current: entry.glucose, since: entry.since, trend: entry.trend)
                    HStack {
                        Text("\(entry.delta, specifier: "%.0f")mg/dL")
                            .font(.headline)
                            .foregroundColor(.mint)
                        Text("\(entry.trend)")
                            .font(.title)
                            .foregroundColor(.mint)
                    }
                    .privacySensitive()
                }
            }
        }
    }
}

@main
struct xDrip4iOS_WidgetKit: Widget {
    let kind: String = "xDrip4iOS+WidgetKit"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            xDrip4iOS_WidgetKitEntryView(entry: entry)
        }
        .configurationDisplayName("xDrip4iOS Widget")
        .description("Setup for xDrip4iOS app widgets.")
        .supportedFamilies([.accessoryCircular,.accessoryRectangular, .accessoryInline, .systemSmall])
    }
}

struct xDrip4iOS_WidgetKit_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            xDrip4iOS_WidgetKitEntryView(entry: SimpleEntry(date: Date(), glucose: 0.0, trend: "\u{2192}", delta: 0.0, since: Date()))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")
            xDrip4iOS_WidgetKitEntryView(entry: SimpleEntry(date: Date(), glucose: 0.0, trend: "\u{2192}", delta: 0.0, since: Date()))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular")
            xDrip4iOS_WidgetKitEntryView(entry: SimpleEntry(date: Date(), glucose: 0.0, trend: "\u{2192}", delta: 0.0, since: Date()))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
            xDrip4iOS_WidgetKitEntryView(entry: SimpleEntry(date: Date(), glucose: 0.0, trend: "\u{2192}", delta: 0.0, since: Date()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")
        }
    }
}
