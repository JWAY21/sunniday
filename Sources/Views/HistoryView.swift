import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var healthManager: HealthManager
    @AppStorage("usesMCG") private var usesMCG: Bool = false
    @Environment(\.dismiss) var dismiss

    enum Period: String, CaseIterable {
        case day = "D", week = "W", month = "M"

        var lookbackDays: Int {
            switch self {
            case .day:   return 7
            case .week:  return 28
            case .month: return 90
            }
        }

        var avgLabel: String {
            switch self {
            case .day:   return "AVG / DAY (7 DAYS)"
            case .week:  return "AVG / WEEK (4 WEEKS)"
            case .month: return "AVG / MONTH (3 MONTHS)"
            }
        }
    }

    struct Bar: Identifiable {
        let id = UUID()
        let date: Date
        let iu: Double
    }

    @State private var period: Period = .day
    @State private var bars: [Bar] = []
    @State private var isLoading = true

    private var unitLabel: String { usesMCG ? "mcg" : "IU" }
    private func convert(_ iu: Double) -> Double { usesMCG ? iu / 40.0 : iu }

    private var average: Double {
        guard !bars.isEmpty else { return 0 }
        return convert(bars.reduce(0.0) { $0 + $1.iu } / Double(bars.count))
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "4a90e2"), Color(hex: "7bb7e5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Picker("Period", selection: $period) {
                        ForEach(Period.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    VStack(spacing: 4) {
                        Text(period.avgLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1.5)
                        Text(formatValue(average))
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        Text(unitLabel)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    if isLoading {
                        ProgressView().tint(.white).frame(height: 220)
                    } else {
                        Chart(bars) { bar in
                            BarMark(
                                x: .value("Date", bar.date, unit: xUnit),
                                y: .value(unitLabel, convert(bar.iu))
                            )
                            .foregroundStyle(.white.opacity(0.85))
                            .cornerRadius(3)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) {
                                AxisValueLabel(format: xFormat, centered: true)
                                    .foregroundStyle(Color.white.opacity(0.7))
                                    .font(.system(size: 11))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(formatValue(v))
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.white.opacity(0.6))
                                    }
                                }
                                AxisGridLine()
                                    .foregroundStyle(Color.white.opacity(0.15))
                            }
                        }
                        .chartPlotStyle { plot in
                            plot.background(Color.black.opacity(0.15)).cornerRadius(12)
                        }
                        .frame(height: 220)
                        .padding(.horizontal, 20)
                    }

                    Spacer()
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
        .onAppear { loadData() }
        .onChange(of: period) { loadData() }
    }

    private var xUnit: Calendar.Component {
        switch period {
        case .day:   return .day
        case .week:  return .weekOfYear
        case .month: return .month
        }
    }

    private var xFormat: Date.FormatStyle {
        switch period {
        case .day:   return .dateTime.weekday(.abbreviated)
        case .week:  return .dateTime.month(.abbreviated).day()
        case .month: return .dateTime.month(.abbreviated)
        }
    }

    private func loadData() {
        isLoading = true
        healthManager.getVitaminDHistory(days: period.lookbackDays) { dailyTotals in
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            switch period {
            case .day:
                self.bars = (0..<7).compactMap { offset -> Bar? in
                    guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
                    return Bar(date: date, iu: dailyTotals[date] ?? 0)
                }.reversed()

            case .week:
                let weekStarts: [Date] = (0..<4).compactMap { offset -> Date? in
                    guard let anchor = calendar.date(byAdding: .weekOfYear, value: -offset, to: today) else { return nil }
                    return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor))
                }.reversed()

                self.bars = weekStarts.map { weekStart in
                    let weekTotal = dailyTotals.reduce(0.0) { sum, entry in
                        let entryWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.key))
                        return entryWeek == weekStart ? sum + entry.value : sum
                    }
                    return Bar(date: weekStart, iu: weekTotal)
                }

            case .month:
                let monthStarts: [Date] = (0..<3).compactMap { offset -> Date? in
                    guard let anchor = calendar.date(byAdding: .month, value: -offset, to: today) else { return nil }
                    return calendar.date(from: calendar.dateComponents([.year, .month], from: anchor))
                }.reversed()

                self.bars = monthStarts.map { monthStart in
                    let monthTotal = dailyTotals.reduce(0.0) { sum, entry in
                        let entryMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.key))
                        return entryMonth == monthStart ? sum + entry.value : sum
                    }
                    return Bar(date: monthStart, iu: monthTotal)
                }
            }

            self.isLoading = false
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value < 1  { return String(format: "%.1f", value) }
        if value < 1000 { return "\(Int(value))" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}
