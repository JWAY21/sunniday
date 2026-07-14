import Foundation

/// Applies actions the user took on the interactive widget while the app wasn't running.
///
/// The widget's AppIntents run in the extension process, so they can't drive
/// VitaminDCalculator directly. Instead they write commands into the shared
/// app-group defaults and the app reconciles them whenever it becomes active:
/// - `widgetClothingChanged` + `clothingLevel`: clothing cycled on the widget
/// - `pendingWidgetSessions`: sessions begun AND ended on the widget (or ended
///   there after being started in the app) — saved to Health as-is
/// - `widgetCommand` == "begin" + `sessionStartDate`: a session started on the
///   widget that is still running — adopted into live in-app accounting
enum WidgetSessionBridge {
    private static let suiteName = "group.jway21.sunniday.widget"

    static func reconcile(calculator: VitaminDCalculator,
                          healthManager: HealthManager,
                          uvService: UVService) {
        guard let shared = UserDefaults(suiteName: suiteName) else { return }

        // 1. Clothing cycled on the widget
        if shared.bool(forKey: "widgetClothingChanged") {
            if let level = ClothingLevel(rawValue: shared.integer(forKey: "clothingLevel")) {
                calculator.clothingLevel = level
            }
            shared.set(false, forKey: "widgetClothingChanged")
        }

        // 2. Sessions ended from the widget — the widget's estimate is authoritative
        if let pending = shared.array(forKey: "pendingWidgetSessions") as? [[String: Any]] {
            for record in pending {
                guard let amount = record["amount"] as? Double,
                      let start = record["start"] as? Date,
                      amount > 0 else { continue }

                // If the app still has its own copy of this session running, drop it
                // so it isn't saved twice.
                if calculator.isInSun,
                   let appStart = calculator.sessionStartTime,
                   abs(appStart.timeIntervalSince(start)) < 120 {
                    calculator.discardActiveSession()
                }

                healthManager.saveVitaminD(amount: amount, date: start) { _ in
                    calculator.addManualEntry(amount: amount)
                    calculator.refreshTodayTotals(forceWidget: true)
                }
            }
            shared.removeObject(forKey: "pendingWidgetSessions")
        }

        // 3. A session begun on the widget that is still running
        if shared.string(forKey: "widgetCommand") == "begin",
           let start = shared.object(forKey: "sessionStartDate") as? Date,
           Calendar.current.isDateInToday(start),
           !calculator.isInSun {
            calculator.adoptWidgetSession(startDate: start, uvIndex: uvService.currentUV)
        }
        shared.removeObject(forKey: "widgetCommand")
    }
}
