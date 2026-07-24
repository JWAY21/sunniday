import SwiftUI
import Charts

// MARK: – HistoryView
//
// Bar chart of daily vitamin D synthesis with a half-life-weighted moving
// average line. The MA uses the pharmacokinetic half-life of circulating
// 25-hydroxyvitamin D (calcidiol) — approximately 20 days — so each past
// day's contribution decays as  weight = 0.966^offset  (where 0.966 ≈
// 2^(-1/20)). This mirrors how the body actually accumulates and loses the
// vitamin: if the line trends up you are consistently banking sun exposure;
// if it trends down you are falling behind. The MA is seeded with up to
// 3 × half-life (≈ 60 days) of extra history so the displayed window starts
// with an accurate value rather than a cold-start of zero.

struct HistoryView: View {
    @EnvironmentObject var healthManager: HealthManager
    @AppStorage("usesMCG") private var usesMCG: Bool = false
    @Environment(\.dismiss) var dismiss

    // MARK: Period
    enum Period: String, CaseIterable {
        case week = "W", month = "M", threeMonth = "3M"

        /// How many daily bars to display
        var displayDays: Int {
            switch self {
            case .week:       return 7
            case .month:      return 30
            case .threeMonth: return 90
            }
        }

        var avgLabel: String {
            switch self {
            case .week:       return "AVG / DAY  ·  7 DAYS"
            case .month:      return "AVG / DAY  ·  30 DAYS"
            case .threeMonth: return "AVG / DAY  ·  3 MONTHS"
            }
        }

        /// Desired number of x-axis labels
        var axisLabelCount: Int {
            switch self {
            case .week:       return 7
            case .month:      return 5
            case .threeMonth: return 4
            }
        }
    }

    // MARK: Data models
    struct Bar: Identifiable {
        let id = UUID()
        let date: Date
        let iu: Double
    }

    struct MAPoint: Identifiable {
        let id = UUID()
        let date: Date
        let iu: Double   // modelled store, in IU (converted to mcg for display)
    }

    // MARK: State
    @State private var period: Period = .week
    @State private var bars: [Bar] = []
    @State private var maPoints: [MAPoint] = []
    @State private var isLoading = true

    // MARK: Helpers
    private var unitLabel: String { usesMCG ? "mcg" : "IU" }
    private func convert(_ iu: Double) -> Double { usesMCG ? iu / 40.0 : iu }

    // The bars' y-axis top (daily synthesis, with headroom).
    private var chartYMax: Double {
        max((bars.map { convert($0.iu) }.max() ?? 1) * 1.15, 1)
    }
    // The reserve line's own top (accumulated store runs much larger than a
    // single day, so it gets its own right-hand scale, in the same unit).
    private var trendMax: Double {
        max((maPoints.map { convert($0.iu) }.max() ?? 1) * 1.2, 1)
    }
    // Draw the store against the bars' domain but scaled to its own range, so
    // its movement is visible rather than flattened by the tall daily bars.
    private func trendPlotY(_ storeIU: Double) -> Double {
        min(max(convert(storeIU), 0), trendMax) / trendMax * chartYMax
    }

    private var average: Double {
        guard !bars.isEmpty else { return 0 }
        return convert(bars.reduce(0.0) { $0 + $1.iu } / Double(bars.count))
    }

    // MARK: Body
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "7f92d6"), Color(hex: "a9a3e0")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Period picker
                        Picker("Period", selection: $period) {
                            ForEach(Period.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Average display
                        VStack(spacing: 4) {
                            Text(period.avgLabel)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1.2)
                            Text(formatValue(average))
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                            Text(unitLabel)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        // Chart
                        if isLoading {
                            ProgressView().tint(.white).frame(height: 240)
                        } else {
                            VStack(spacing: 8) {
                                Chart {
                                    // Daily bars
                                    ForEach(bars) { bar in
                                        BarMark(
                                            x: .value("Date", bar.date, unit: .day),
                                            y: .value(unitLabel, convert(bar.iu))
                                        )
                                        .foregroundStyle(.white.opacity(0.75))
                                        .cornerRadius(2)
                                    }

                                    // Modelled reserve trend — plotted on its own
                                    // relative scale (see trendPlotY), so its
                                    // movement is visible against the tall bars.
                                    ForEach(maPoints) { pt in
                                        LineMark(
                                            x: .value("Date", pt.date, unit: .day),
                                            y: .value("Reserve", trendPlotY(pt.iu))
                                        )
                                        .foregroundStyle(Color.yellow.opacity(0.9))
                                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
                                .chartYScale(domain: 0...chartYMax)
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: period.axisLabelCount)) { _ in
                                        AxisValueLabel(format: xFormat, centered: true)
                                            .foregroundStyle(Color.white.opacity(0.7))
                                            .font(.system(size: 11))
                                    }
                                }
                                .chartYAxis {
                                    // Left: daily synthesis (mcg / IU) for the bars
                                    AxisMarks(position: .leading) { value in
                                        AxisValueLabel {
                                            if let v = value.as(Double.self) {
                                                Text(formatValue(v))
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Color.white.opacity(0.6))
                                            }
                                        }
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.12))
                                    }
                                    // Right: modelled reserve, in the selected unit
                                    AxisMarks(position: .trailing,
                                              values: [0.25, 0.5, 0.75, 1.0].map { $0 * chartYMax }) { value in
                                        AxisValueLabel {
                                            if let pos = value.as(Double.self), chartYMax > 0 {
                                                Text(formatValue((pos / chartYMax) * trendMax))
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(Color.yellow.opacity(0.55))
                                            }
                                        }
                                    }
                                }
                                .chartPlotStyle { plot in
                                    plot.background(Color.black.opacity(0.15))
                                        .cornerRadius(12)
                                }
                                .frame(height: 240)
                                .padding(.horizontal, 20)

                                // Legend
                                HStack(spacing: 18) {
                                    HStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(.white.opacity(0.75))
                                            .frame(width: 14, height: 10)
                                        Text("Daily synthesis")
                                    }
                                    HStack(spacing: 6) {
                                        Capsule()
                                            .fill(Color.yellow.opacity(0.9))
                                            .frame(width: 18, height: 2.5)
                                        Text("Modelled reserve (right)")
                                    }
                                }
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.65))
                            }
                        }

                        // Trend explanation (tap "modelled reserve" for the detail)
                        if !isLoading {
                            GlossaryText("The line is a best-guess of your body's [modelled reserve](glossary://modelled-trend) — what your recent sun has banked, allowing for the slow way vitamin D clears (right axis, \(usesMCG ? "mcg" : "IU")). Rising means you're building it up; falling means you're not keeping pace. It's an estimate, not a measurement — only a blood test shows your real level.", size: 11, opacity: 0.5)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Vitamin D History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
        }
        .glossaryTaps()
        .onAppear { loadData() }
        .onChange(of: period) { loadData() }
    }

    // MARK: X-axis format
    private var xFormat: Date.FormatStyle {
        switch period {
        case .week:       return .dateTime.weekday(.abbreviated)
        case .month:      return .dateTime.month(.abbreviated).day()
        case .threeMonth: return .dateTime.month(.abbreviated)
        }
    }

    // MARK: Data loading
    private func loadData() {
        isLoading = true

        // Fetch enough extra history to warm up the MA before the display window.
        // 3 × half-life ≈ 60 days of seed data means the MA starts accurate.
        let halfLifeDays = 20
        let seedDays = halfLifeDays * 3
        let fetchDays = period.displayDays + seedDays

        healthManager.getVitaminDHistory(days: fetchDays) { dailyTotals in
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Build a complete ordered array for every fetched day (oldest → newest)
            let allBars: [Bar] = (0..<fetchDays).compactMap { offset -> Bar? in
                let daysAgo = fetchDays - 1 - offset
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
                return Bar(date: date, iu: dailyTotals[date] ?? 0)
            }

            // Displayed bars = the most-recent `displayDays` slice
            self.bars = Array(allBars.suffix(period.displayDays))

            // Compute MA across ALL fetched days, then take the same suffix
            let allMA = Self.bodyStoreEstimate(allBars: allBars, halfLifeDays: Double(halfLifeDays))
            self.maPoints = Array(allMA.suffix(period.displayDays))

            self.isLoading = false
        }
    }

    // MARK: Modelled body-store trend (saturating one-compartment reservoir)
    //
    // The daily bars are synthesis; this line models the RESERVE they build.
    // Vitamin D's storage form, 25(OH)D, has a ~2–3 week half-life, so intake
    // accumulates and clears exponentially — the standard one-compartment
    // pharmacokinetic model:  store += intake;  store *= decay each day.
    //
    // A saturating term reflects the documented curvilinear response: each extra
    // dose raises the store less as it fills (per-µg response roughly halves
    // from 1000→4000 IU/d; the serum curve plateaus). Without it a linear
    // reservoir would over-state gains at high stores.
    //
    // Output is the modelled store in the SAME unit as the bars (IU, converted
    // to mcg for display) — a best-guess reserve, NOT a blood level. Estimated
    // cutaneous synthesis isn't calibrated to serum 25(OH)D, so only the trend's
    // shape and direction are meaningful; the absolute figure is indicative.
    //
    // Earlier versions plotted a normalized weighted average, which measures
    // your typical recent daily rate — it sits flat under steady intake and so
    // could not show stores "building", contradicting its own caption.
    static func bodyStoreEstimate(allBars: [Bar], halfLifeDays: Double,
                                  dailyGoalIU: Double = 4000) -> [MAPoint] {
        let decay = pow(0.5, 1.0 / halfLifeDays)
        let fullScale = 2.0 * dailyGoalIU / (1.0 - decay)   // saturation ceiling, in IU

        var points: [MAPoint] = []
        points.reserveCapacity(allBars.count)
        var store = 0.0
        for bar in allBars {
            let damp = 1.0 - min(0.85, store / fullScale)   // diminishing returns as it fills
            store = store * decay + bar.iu * damp
            points.append(MAPoint(date: bar.date, iu: store))   // store in IU, like the bars
        }
        return points
    }

    // MARK: Formatting
    private func formatValue(_ value: Double) -> String {
        if value == 0  { return "0" }
        if value < 1000 { return "\(Int(value.rounded()))" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}
