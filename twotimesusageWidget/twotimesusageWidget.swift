import WidgetKit
import SwiftUI

// MARK: - Usage Status Logic

enum UsageStatus {
    case doubleUsage
    case normalUsage

    /// Peak hours are weekdays 12:00–18:00 UTC (= 5–11am PT / 12–6pm GMT).
    /// Outside peak hours and all weekends = 2x usage.
    static func current(at date: Date = .now) -> UsageStatus {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)

        let isWeekend = weekday == 1 || weekday == 7
        if isWeekend { return .doubleUsage }

        let isPeakHour = hour >= 12 && hour < 18
        return isPeakHour ? .normalUsage : .doubleUsage
    }

    var label: String {
        switch self {
        case .doubleUsage: "2x Usage"
        case .normalUsage: "Normal Usage"
        }
    }

    var subtitle: String {
        switch self {
        case .doubleUsage: "Double usage active"
        case .normalUsage: "Peak hours"
        }
    }

    var colour: Color {
        switch self {
        case .doubleUsage: Color(red: 0.18, green: 0.74, blue: 0.42)
        case .normalUsage: Color(red: 0.85, green: 0.47, blue: 0.34)
        }
    }
}

// MARK: - Timeline

struct UsageEntry: TimelineEntry {
    let date: Date
    let status: UsageStatus
}

struct UsageTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: .now, status: .current())
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(UsageEntry(date: .now, status: .current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        var entries: [UsageEntry] = []
        let now = Date()

        // Generate entries for the next 24 hours at each UTC boundary hour that matters
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        // Start with current entry
        entries.append(UsageEntry(date: now, status: .current(at: now)))

        // Add entries at each transition point (12:00 UTC and 18:00 UTC) and midnight for weekday changes
        let transitionHours = [0, 12, 18]
        let currentComponents = calendar.dateComponents([.year, .month, .day, .hour], from: now)

        for dayOffset in 0...1 {
            for hour in transitionHours {
                var components = currentComponents
                components.hour = hour
                components.minute = 0
                components.second = 0
                if let candidate = calendar.date(from: components) {
                    let adjusted = calendar.date(byAdding: .day, value: dayOffset, to: candidate)!
                    if adjusted > now {
                        entries.append(UsageEntry(date: adjusted, status: .current(at: adjusted)))
                    }
                }
            }
        }

        entries.sort { $0.date < $1.date }

        let timeline = Timeline(entries: entries, policy: .after(
            calendar.date(byAdding: .hour, value: 24, to: now)!
        ))
        completion(timeline)
    }
}

// MARK: - Pixel Art Claude Mascot

struct ClaudeMascot: View {
    let pixelSize: CGFloat

    private let bodyColour = Color(red: 0.80, green: 0.55, blue: 0.40)
    private let darkColour = Color(red: 0.20, green: 0.15, blue: 0.12)

    var body: some View {
        Canvas { context, size in
            let p = pixelSize
            let centreX = size.width / 2

            func pixel(_ col: Int, _ row: Int, _ colour: Color) {
                let x = centreX + CGFloat(col) * p
                let y = CGFloat(row) * p
                context.fill(Path(CGRect(x: x, y: y, width: p, height: p)), with: .color(colour))
            }

            // Sparkle dots above head (row 0-1)
            pixel(-1, 0, .white.opacity(0.5))
            pixel(1, 0, .white.opacity(0.3))
            pixel(0, 1, .white.opacity(0.4))
            pixel(2, 1, .white.opacity(0.5))
            pixel(-2, 1, .white.opacity(0.3))

            // Head top (row 2)
            for c in -2...1 { pixel(c, 2, bodyColour) }

            // Head + ears (row 3)
            pixel(-4, 3, bodyColour) // left ear
            pixel(-3, 3, bodyColour)
            for c in -2...1 { pixel(c, 3, bodyColour) }
            pixel(2, 3, bodyColour)
            pixel(3, 3, bodyColour)  // right ear

            // Head with eyes (row 4)
            pixel(-3, 4, bodyColour) // left ear
            for c in -2...1 { pixel(c, 4, bodyColour) }
            pixel(2, 4, bodyColour)  // right ear
            // Eyes
            pixel(-1, 4, darkColour)
            pixel(0, 4, darkColour)

            // Body (row 5)
            for c in -2...1 { pixel(c, 5, bodyColour) }

            // Body with nose (row 6)
            for c in -2...1 { pixel(c, 6, bodyColour) }
            pixel(-1, 6, bodyColour.opacity(0.7))
            pixel(0, 6, bodyColour.opacity(0.7))

            // Legs (row 7)
            pixel(-2, 7, bodyColour)
            pixel(-1, 7, bodyColour)
            pixel(0, 7, bodyColour)
            pixel(1, 7, bodyColour)

            // Feet (row 8)
            pixel(-2, 8, bodyColour)
            pixel(1, 8, bodyColour)
        }
        .frame(width: pixelSize * 8, height: pixelSize * 9)
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: UsageEntry

    var body: some View {
        ZStack {
            Rectangle().fill(entry.status.colour.gradient)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Claude")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.85))

                Spacer()

                HStack {
                    Spacer()
                    ClaudeMascot(pixelSize: 5)
                        .opacity(0.6)
                    Spacer()
                }

                Spacer()

                Text(entry.status.label)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(entry.status.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(14)
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: UsageEntry

    private var nextChangeDescription: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let now = entry.date
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let isWeekend = weekday == 1 || weekday == 7

        if isWeekend {
            // Find next Monday 12:00 UTC
            let daysUntilMonday: Int
            if weekday == 7 { daysUntilMonday = 2 }
            else { daysUntilMonday = 1 }
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 12
            components.minute = 0
            if let mondayNoon = calendar.date(from: components) {
                let target = calendar.date(byAdding: .day, value: daysUntilMonday, to: mondayNoon)!
                return formatTimeUntil(from: now, to: target)
            }
        } else if hour >= 12 && hour < 18 {
            // Peak: changes at 18:00 UTC
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 18
            components.minute = 0
            if let target = calendar.date(from: components) {
                return formatTimeUntil(from: now, to: target)
            }
        } else {
            // Off-peak weekday
            if hour < 12 {
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = 12
                components.minute = 0
                if let target = calendar.date(from: components) {
                    return formatTimeUntil(from: now, to: target)
                }
            } else {
                // After 18:00, next change is tomorrow 12:00 or weekend
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
                let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
                if tomorrowWeekday == 1 || tomorrowWeekday == 7 {
                    // Tomorrow is weekend, 2x continues — find Monday 12:00
                    let daysUntilMonday = tomorrowWeekday == 7 ? 3 : 2
                    var components = calendar.dateComponents([.year, .month, .day], from: now)
                    components.hour = 12
                    components.minute = 0
                    if let base = calendar.date(from: components) {
                        let target = calendar.date(byAdding: .day, value: daysUntilMonday, to: base)!
                        return formatTimeUntil(from: now, to: target)
                    }
                } else {
                    var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                    components.hour = 12
                    components.minute = 0
                    if let target = calendar.date(from: components) {
                        return formatTimeUntil(from: now, to: target)
                    }
                }
            }
        }
        return ""
    }

    private func formatTimeUntil(from: Date, to: Date) -> String {
        let interval = to.timeIntervalSince(from)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        ZStack {
            Rectangle().fill(entry.status.colour.gradient)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Claude")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    Text(entry.status.label)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(entry.status.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                VStack(spacing: 8) {
                    ClaudeMascot(pixelSize: 5)
                        .opacity(0.6)

                    Spacer()

                    Text("Changes in")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(nextChangeDescription)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(14)
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: UsageEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct TwoTimesUsageWidget: Widget {
    let kind = "twotimesusageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UsageTimelineProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Claude Usage")
        .description("Shows whether Claude is currently offering 2x usage.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Widget Bundle

@main
struct TwoTimesUsageWidgetBundle: WidgetBundle {
    var body: some Widget {
        TwoTimesUsageWidget()
    }
}

// MARK: - Previews

#Preview("Small - 2x", as: .systemSmall) {
    TwoTimesUsageWidget()
} timeline: {
    UsageEntry(date: .now, status: .doubleUsage)
}

#Preview("Small - Normal", as: .systemSmall) {
    TwoTimesUsageWidget()
} timeline: {
    UsageEntry(date: .now, status: .normalUsage)
}

#Preview("Medium - 2x", as: .systemMedium) {
    TwoTimesUsageWidget()
} timeline: {
    UsageEntry(date: .now, status: .doubleUsage)
}
