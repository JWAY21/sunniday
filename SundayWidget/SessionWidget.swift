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

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: UV + cloud cover (spot obviously-wrong data at a glance) + today's total
            VStack(alignment: .leading, spacing: 4) {
                Text("UV INDEX")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Text(String(format: "%.1f", entry.uvIndex))
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 4) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 10))
                    Text("\(Int(entry.cloudCover))% clouds")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.7))

                // Daily total — labelled, turns green once the 100 mcg / 4000 IU goal is reached
                VStack(alignment: .leading, spacing: 1) {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.5)
                    HStack(spacing: 4) {
                        if todayReachedGoal {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                        }
                        Text(formattedTodayTotal)
                            .font(.system(size: 15, weight: .bold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .foregroundColor(todayReachedGoal ? Color(hex: "34c759") : .white)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
                        Image(systemName: "tshirt.fill")
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
