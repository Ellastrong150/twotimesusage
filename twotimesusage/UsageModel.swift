import SwiftUI

// MARK: - Usage Status

enum UsageStatus {
    case doubleUsage
    case normalUsage

    static func current(at date: Date = .now) -> UsageStatus {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let isWeekend = weekday == 1 || weekday == 7
        if isWeekend { return .doubleUsage }
        return (hour >= 12 && hour < 18) ? .normalUsage : .doubleUsage
    }

    var label: String {
        switch self {
        case .doubleUsage: "2x Usage"
        case .normalUsage: "Peak Hours"
        }
    }

    var isDouble: Bool { self == .doubleUsage }
}

// MARK: - Colours

let ultrathinkColours: [Color] = [
    Color(red: 0.83, green: 0.27, blue: 0.17),
    Color(red: 0.91, green: 0.52, blue: 0.17),
    Color(red: 0.91, green: 0.77, blue: 0.17),
    Color(red: 0.36, green: 0.67, blue: 0.29),
    Color(red: 0.29, green: 0.56, blue: 0.80),
    Color(red: 0.48, green: 0.37, blue: 0.65),
]

let claudeCoral = Color(red: 0.85, green: 0.47, blue: 0.34)

let ultrathinkGradient = LinearGradient(
    colors: ultrathinkColours,
    startPoint: .leading,
    endPoint: .trailing
)

func accentGradient(for status: UsageStatus) -> LinearGradient {
    status.isDouble
        ? LinearGradient(colors: ultrathinkColours, startPoint: .leading, endPoint: .trailing)
        : LinearGradient(colors: [claudeCoral, claudeCoral], startPoint: .leading, endPoint: .trailing)
}

// MARK: - Next Change Date

func nextChangeDate(from date: Date) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let weekday = calendar.component(.weekday, from: date)
    let hour = calendar.component(.hour, from: date)
    let isWeekend = weekday == 1 || weekday == 7

    if isWeekend {
        let daysUntilMonday = weekday == 7 ? 2 : 1
        var c = calendar.dateComponents([.year, .month, .day], from: date)
        c.hour = 12; c.minute = 0; c.second = 0
        let base = calendar.date(from: c)!
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: base)!
    } else if hour >= 12 && hour < 18 {
        var c = calendar.dateComponents([.year, .month, .day], from: date)
        c.hour = 18; c.minute = 0; c.second = 0
        return calendar.date(from: c)!
    } else if hour < 12 {
        var c = calendar.dateComponents([.year, .month, .day], from: date)
        c.hour = 12; c.minute = 0; c.second = 0
        return calendar.date(from: c)!
    } else {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
        let tw = calendar.component(.weekday, from: tomorrow)
        if tw == 1 || tw == 7 {
            let d = tw == 7 ? 3 : 2
            var c = calendar.dateComponents([.year, .month, .day], from: date)
            c.hour = 12; c.minute = 0; c.second = 0
            let base = calendar.date(from: c)!
            return calendar.date(byAdding: .day, value: d, to: base)!
        } else {
            var c = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            c.hour = 12; c.minute = 0; c.second = 0
            return calendar.date(from: c)!
        }
    }
}

// MARK: - Claude Mascot (SVG Path)

struct ClaudeMascot: View {
    let size: CGFloat

    private let bodyColour = Color(red: 0.80, green: 0.55, blue: 0.40)
    private let eyeColour = Color(red: 0.15, green: 0.12, blue: 0.10)

    // The mascot is drawn on a 14x11 unit grid, scaled to fit `size` as the width.
    // Body outline as a single path (ears, head, legs).
    private var scaleFactor: CGFloat { size / 14 }

    var body: some View {
        Canvas { context, _ in
            let s = scaleFactor

            // Body outline path (clockwise from top-left of head)
            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: 1 * s, y: 0))
            bodyPath.addLine(to: CGPoint(x: 13 * s, y: 0))        // top edge
            bodyPath.addLine(to: CGPoint(x: 13 * s, y: 3 * s))    // right side down to ear
            bodyPath.addLine(to: CGPoint(x: 14 * s, y: 3 * s))    // right ear out
            bodyPath.addLine(to: CGPoint(x: 14 * s, y: 5 * s))    // right ear down
            bodyPath.addLine(to: CGPoint(x: 13 * s, y: 5 * s))    // right ear in
            bodyPath.addLine(to: CGPoint(x: 13 * s, y: 8 * s))    // right side down to legs
            // Leg 4 (cols 11-12) — right edge continues from body
            bodyPath.addLine(to: CGPoint(x: 13 * s, y: 11 * s))
            bodyPath.addLine(to: CGPoint(x: 11 * s, y: 11 * s))
            bodyPath.addLine(to: CGPoint(x: 11 * s, y: 8 * s))
            // Gap col 10
            bodyPath.addLine(to: CGPoint(x: 10 * s, y: 8 * s))
            // Leg 3 (cols 8-9)
            bodyPath.addLine(to: CGPoint(x: 10 * s, y: 11 * s))
            bodyPath.addLine(to: CGPoint(x: 8 * s, y: 11 * s))
            bodyPath.addLine(to: CGPoint(x: 8 * s, y: 8 * s))
            // Gap cols 6-7
            bodyPath.addLine(to: CGPoint(x: 6 * s, y: 8 * s))
            // Leg 2 (cols 4-5)
            bodyPath.addLine(to: CGPoint(x: 6 * s, y: 11 * s))
            bodyPath.addLine(to: CGPoint(x: 4 * s, y: 11 * s))
            bodyPath.addLine(to: CGPoint(x: 4 * s, y: 8 * s))
            // Gap col 3
            bodyPath.addLine(to: CGPoint(x: 3 * s, y: 8 * s))
            // Leg 1 (cols 1-2)
            bodyPath.addLine(to: CGPoint(x: 3 * s, y: 11 * s))
            bodyPath.addLine(to: CGPoint(x: 1 * s, y: 11 * s))
            bodyPath.addLine(to: CGPoint(x: 1 * s, y: 8 * s))
            bodyPath.addLine(to: CGPoint(x: 1 * s, y: 5 * s))     // left side up to ear
            bodyPath.addLine(to: CGPoint(x: 0, y: 5 * s))          // left ear out
            bodyPath.addLine(to: CGPoint(x: 0, y: 3 * s))          // left ear up
            bodyPath.addLine(to: CGPoint(x: 1 * s, y: 3 * s))     // left ear in
            bodyPath.closeSubpath()

            context.fill(bodyPath, with: .color(bodyColour))

            // Chevron eyes: > on left, < on right
            let eyeStroke: CGFloat = 0.7 * s
            // Left eye >
            var leftEye = Path()
            leftEye.move(to: CGPoint(x: 3.5 * s, y: 3.8 * s))
            leftEye.addLine(to: CGPoint(x: 4.5 * s, y: 4.5 * s))
            leftEye.addLine(to: CGPoint(x: 3.5 * s, y: 5.2 * s))

            // Right eye <
            var rightEye = Path()
            rightEye.move(to: CGPoint(x: 10.5 * s, y: 3.8 * s))
            rightEye.addLine(to: CGPoint(x: 9.5 * s, y: 4.5 * s))
            rightEye.addLine(to: CGPoint(x: 10.5 * s, y: 5.2 * s))

            context.stroke(leftEye, with: .color(eyeColour), style: StrokeStyle(lineWidth: eyeStroke, lineCap: .square, lineJoin: .miter))
            context.stroke(rightEye, with: .color(eyeColour), style: StrokeStyle(lineWidth: eyeStroke, lineCap: .square, lineJoin: .miter))
        }
        .frame(width: size, height: size / 14 * 11)
    }
}
