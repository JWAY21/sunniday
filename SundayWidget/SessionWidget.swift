import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared state

private let appGroupSuite = "group.jway21.sunniday.widget"

private func sharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: appGroupSuite)
}

// Mirror of the app's ClothingLevel — the widget only needs names for display;
// exposure math stays in the app, which re-reads `clothingLevel` on foreground.
enum WidgetClothing: Int, CaseIterable {
    case none = -1
    case minimal = 0
    case light = 1
    case moderate = 2
    case heavy = 3

    var shortName: String {
        switch self {
        case .none: return "Nude!"
        case .minimal: return "Minimal"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .heavy: return "Heavy"
        }
    }

    /// SF Symbol representing the coverage level.
    var icon: String {
        switch self {
        case .none:     return "figure.stand"       // bare figure
        case .minimal:  return "figure.pool.swim"   // swimwear
        case .light:    return "tshirt.fill"        // shorts & tee
        case .moderate: return "figure.walk"        // pants & shirt
        case .heavy:    return "coat"               // long sleeves & long pants
        }
    }

    var next: WidgetClothing {
        let all = WidgetClothing.allCases
        let index = all.firstIndex(of: self) ?? 2
        return all[(index + 1) % all.count]
    }
}

// MARK: - Intents

struct BeginSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Begin Sun Session"
    static var description = IntentDescription("Start tracking a sun exposure session.")

    func perform() async throws -> some IntentResult {
        guard let shared = sharedDefaults() else { return .result() }
        // No UV, no session — mirrors the in-app rule
        guard shared.double(forKey: "currentUV") > 0 else { return .result() }
        guard shared.bool(forKey: "isTracking") == false else { return .result() }

        shared.set(true, forKey: "isTracking")
        shared.set(Date(), forKey: "sessionStartDate")
        shared.set("begin", forKey: "widgetCommand")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct EndSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "End Sun Session"
    static var description = IntentDescription("End the current sun exposure session and save it.")

    func perform() async throws -> some IntentResult {
        guard let shared = sharedDefaults() else { return .result() }

        if let start = shared.object(forKey: "sessionStartDate") as? Date {
            // Estimate the session amount from the last rate the app computed
            // (IU per hour). The app reconciles this record into Health on next open.
            let ratePerHour = shared.double(forKey: "vitaminDRate")
            let elapsedHours = max(0, Date().timeIntervalSince(start)) / 3600.0
            let amount = ratePerHour * elapsedHours

            if amount > 0 {
                var pending = shared.array(forKey: "pendingWidgetSessions") as? [[String: Any]] ?? []
                pending.append(["start": start, "end": Date(), "amount": amount])
                shared.set(pending, forKey: "pendingWidgetSessions")
                // Optimistically bump today's total so the widgets reflect the session
                shared.set(shared.double(forKey: "todaysTotal") + amount, forKey: "todaysTotal")
            }
        }

        shared.set(false, forKey: "isTracking")
        shared.removeObject(forKey: "sessionStartDate")
        shared.set("end", forKey: "widgetCommand")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct CycleClothingIntent: AppIntent {
    static var title: LocalizedStringResource = "Change Clothing"
    static var description = IntentDescription("Cycle to the next clothing level.")

    func perform() async throws -> some IntentResult {
        guard let shared = sharedDefaults() else { return .result() }
        let current = WidgetClothing(rawValue: shared.integer(forKey: "clothingLevel")) ?? .light
        shared.set(current.next.rawValue, forKey: "clothingLevel")
        shared.set(true, forKey: "widgetClothingChanged")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// WMO cloud transmission (matches UVService.cloudTransmission) so the widget
/// can recompute UV instantly when the cloud override changes.
func widgetCloudTransmission(_ pct: Double) -> Double {
    let points: [(Double, Double)] = [(0, 1.00), (25, 0.90), (50, 0.72), (75, 0.45), (100, 0.17)]
    if pct <= 0 { return 1.00 }
    if pct >= 100 { return 0.17 }
    for i in 0..<points.count - 1 {
        let (x0, y0) = points[i]; let (x1, y1) = points[i + 1]
        if pct <= x1 { let t = (pct - x0) / (x1 - x0); return y0 + t * (y1 - y0) }
    }
    return 0.17
}

/// Tapping the clouds cycles the cloud-cover override: forecast → 0 → 25 → 50
/// → 75 → 100 → forecast. Recomputes UV live from the forecast baseline; the
/// app applies the same override on next foreground so everything agrees.
struct CycleCloudOverrideIntent: AppIntent {
    static var title: LocalizedStringResource = "Adjust Cloud Cover"
    static var description = IntentDescription("Fine-tune the cloud cover used for UV.")

    private static let presets: [Double] = [0, 25, 50, 75, 100]

    func perform() async throws -> some IntentResult {
        guard let shared = sharedDefaults() else { return .result() }
        let forecastUV = shared.double(forKey: "forecastUV")
        let forecastCloud = shared.double(forKey: "forecastCloudCover")

        let hasOverride = shared.object(forKey: "cloudOverride") != nil
        let current = shared.double(forKey: "cloudOverride")

        if !hasOverride {
            apply(0, shared: shared, forecastUV: forecastUV, forecastCloud: forecastCloud)
        } else if let idx = Self.presets.firstIndex(where: { abs($0 - current) < 0.5 }),
                  idx < Self.presets.count - 1 {
            apply(Self.presets[idx + 1], shared: shared, forecastUV: forecastUV, forecastCloud: forecastCloud)
        } else {
            // Wrap back to the real forecast
            shared.removeObject(forKey: "cloudOverride")
            shared.set(forecastCloud, forKey: "currentCloudCover")
            shared.set(forecastUV, forKey: "currentUV")
            shared.set("clear", forKey: "cloudCommand")
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }

    private func apply(_ pct: Double, shared: UserDefaults, forecastUV: Double, forecastCloud: Double) {
        let clearSky = forecastUV / max(widgetCloudTransmission(forecastCloud), 0.0001)
        shared.set(pct, forKey: "cloudOverride")
        shared.set(pct, forKey: "currentCloudCover")
        shared.set(clearSky * widgetCloudTransmission(pct), forKey: "currentUV")
        shared.set(String(Int(pct)), forKey: "cloudCommand")
    }
}

// MARK: - Timeline

struct SessionEntry: TimelineEntry {
    let date: Date
    let uvIndex: Double
    let cloudCover: Double
    let isTracking: Bool
    let sessionStart: Date?
    let ratePerHour: Double
    let usesMCG: Bool
    let clothing: WidgetClothing
    let todayTotalIU: Double
    let todayBaseIU: Double
}

struct SessionProvider: TimelineProvider {
    private func currentEntry(at date: Date = Date()) -> SessionEntry {
        let shared = sharedDefaults()
        return SessionEntry(
            date: date,
            uvIndex: shared?.double(forKey: "currentUV") ?? 0,
            cloudCover: shared?.double(forKey: "currentCloudCover") ?? 0,
            isTracking: shared?.bool(forKey: "isTracking") ?? false,
            sessionStart: shared?.object(forKey: "sessionStartDate") as? Date,
            ratePerHour: shared?.double(forKey: "vitaminDRate") ?? 0,
            usesMCG: shared?.bool(forKey: "usesMCG") ?? false,
            clothing: WidgetClothing(rawValue: shared?.integer(forKey: "clothingLevel") ?? 1) ?? .light,
            todayTotalIU: shared?.double(forKey: "todaysTotal") ?? 0,
            todayBaseIU: shared?.double(forKey: "todaysBase") ?? 0
        )
    }

    func placeholder(in context: Context) -> SessionEntry {
        SessionEntry(date: Date(), uvIndex: 6.2, cloudCover: 20, isTracking: false,
                     sessionStart: nil, ratePerHour: 15000, usesMCG: false, clothing: .light,
                     todayTotalIU: 3200, todayBaseIU: 3200)
    }

    func getSnapshot(in context: Context, completion: @escaping (SessionEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SessionEntry>) -> Void) {
        let base = currentEntry()
        var entries: [SessionEntry] = [base]

        let policy: TimelineReloadPolicy
        if base.isTracking {
            // The elapsed timer ticks natively; add per-minute entries so the
            // session IU/mcg figure stays fresh between reloads.
            for minute in 1...15 {
                if let date = Calendar.current.date(byAdding: .minute, value: minute, to: base.date) {
                    entries.append(currentEntry(at: date))
                }
            }
            policy = .atEnd
        } else {
            policy = .after(Calendar.current.date(byAdding: .minute, value: 15, to: base.date)!)
        }

        completion(Timeline(entries: entries, policy: policy))
    }
}

// MARK: - View

struct SessionWidgetView: View {
    let entry: SessionEntry

    private var sessionAmountIU: Double {
        guard let start = entry.sessionStart else { return 0 }
        let elapsedHours = max(0, entry.date.timeIntervalSince(start)) / 3600.0
        return entry.ratePerHour * elapsedHours
    }

    private var formattedSessionAmount: String { format(iu: sessionAmountIU) }

    // Daily target: 100 mcg (= 4000 IU). The day's total turns green once hit.
    private static let dailyGoalIU: Double = 4000

    // Live daily total: while tracking, the base (everything logged today
    // except this session) plus the live session estimate, so it climbs in
    // real time. When idle, the app's maintained today total.
    private var todayTotalLiveIU: Double {
        entry.isTracking ? entry.todayBaseIU + sessionAmountIU : entry.todayTotalIU
    }

    private var todayReachedGoal: Bool { todayTotalLiveIU >= Self.dailyGoalIU }

    private var formattedTodayTotal: String { format(iu: todayTotalLiveIU) }

    private func format(iu: Double) -> String {
        if entry.usesMCG {
            let mcg = iu / 40.0
            return mcg < 10 ? String(format: "%.1f mcg", mcg) : "\(Int(mcg)) mcg"
        }
        if iu < 1000 { return "\(Int(iu)) IU" }
        if iu < 100_000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return "\(formatter.string(from: NSNumber(value: iu)) ?? "\(Int(iu))") IU"
        }
        return String(format: "%.0fK IU", iu / 1000)
    }

    // A stacked stat: label on top, value below (used for CLOUDS and TODAY).
    private func stackedStat(label: String, value: String, showTick: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
                .tracking(0.4)
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if showTick {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "3ad16a"))
                }
            }
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: big centred UV hero over two stacked stats (clouds · today)
            VStack(alignment: .center, spacing: 8) {
                VStack(spacing: 0) {
                    Text("UV INDEX")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(0.6)
                    Text(String(format: "%.1f", entry.uvIndex))
                        .font(.system(size: 85, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }

                HStack(alignment: .top, spacing: 18) {
                    // CLOUDS — tap to fine-tune the cloud cover / UV
                    Button(intent: CycleCloudOverrideIntent()) {
                        stackedStat(label: "CLOUDS", value: "\(Int(entry.cloudCover))%")
                    }
                    .buttonStyle(.plain)

                    stackedStat(label: "TODAY",
                                value: formattedTodayTotal,
                                showTick: todayReachedGoal)
                }
            }
            .frame(maxWidth: .infinity)

            // Middle: clothing selector (idle) or live counter (tracking)
            if entry.isTracking, let start = entry.sessionStart {
                VStack(spacing: 4) {
                    Text("SESSION")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text(timerInterval: start...start.addingTimeInterval(12 * 3600),
                         countsDown: false)
                        .font(.system(size: 26, weight: .bold).monospacedDigit())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                    Text(formattedSessionAmount)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
            } else {
                Button(intent: CycleClothingIntent()) {
                    VStack(spacing: 4) {
                        Text("CLOTHING")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: entry.clothing.icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                        Text(entry.clothing.shortName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }

            // Right: Begin / End
            if entry.isTracking {
                Button(intent: EndSessionIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                        Text("End")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
            } else if entry.uvIndex > 0 {
                Button(intent: BeginSessionIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: "sun.max.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                            .shadow(color: Color(hex: "f5c842").opacity(0.9), radius: 6)
                            .shadow(color: Color(hex: "f5c842").opacity(0.6), radius: 12)
                        Text("Begin")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.7))
                    Text("No UV")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(colors: sessionGradientColors(),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        }
    }

    // Shared sky gradient (peach → soft blue-violet → sunset); warm gold when a
    // session is active so Begin/End visibly change the colour.
    private func sessionGradientColors() -> [Color] {
        skyGradientColors(isTracking: entry.isTracking)
    }
}

// MARK: - Widget

struct SunSessionWidget: Widget {
    let kind: String = "SunSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SessionProvider()) { entry in
            SessionWidgetView(entry: entry)
        }
        .configurationDisplayName("Sun Session")
        .description("Begin and end sun sessions with live UV, clouds and session vitamin D.")
        .supportedFamilies([.systemMedium])
    }
}
