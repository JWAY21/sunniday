import SwiftUI
import Charts

/// "How it works" — two depths of explanation for the synthesis model.
///
/// Basics: a plain-language read on how skin makes vitamin D and why the app
/// counts sunburn rather than minutes.
/// Science: the actual equation, its calibration, charts of both curves the
/// model uses, a full parameter table, limitations, and references.
struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vitaminDCalculator: VitaminDCalculator
    @EnvironmentObject var uvService: UVService

    @AppStorage("infoShowsScience") private var showsScience = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "7f92d6"), Color(hex: "a9a3e0")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Depth", selection: $showsScience) {
                            Text("The Basics").tag(false)
                            Text("The Science").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 2)

                        if showsScience {
                            ScienceContent()
                        } else {
                            BasicsContent()
                        }

                        Text("SUNniDAY gives estimates, not measurements. It is not medical advice — talk to a doctor before changing sun habits or supplements.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .padding(.horizontal, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "7f92d6"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Shared building blocks

struct InfoCard<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.16))
        .cornerRadius(16)
    }
}

private struct InfoText: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.92))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct Bullet: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").font(.system(size: 14, weight: .bold))
            Text(text).font(.system(size: 13)).lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(.white.opacity(0.9))
    }
}

/// A labelled value row (parameter tables).
private struct SpecRow: View {
    let label: String
    let value: String
    var note: String? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                if let note {
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            Spacer(minLength: 10)
            Text(value)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundColor(.white)
        }
    }
}

// MARK: - The Basics

private struct BasicsContent: View {
    var body: some View {
        VStack(spacing: 16) {
            InfoCard(icon: "sun.max.fill", title: "Your skin makes it, not your gut") {
                InfoText("Vitamin D isn't really a vitamin — it's a hormone your body builds itself. Deep in your skin sits a cholesterol-like molecule called 7-dehydrocholesterol. When a narrow band of ultraviolet light (UVB, around 295–300 nanometres) hits it, the molecule snaps into a new shape called previtamin D3, which your body then converts into the vitamin D that ends up in your blood.\n\nThat's why food and supplements are a workaround: sunlight is the route we evolved with.")
            }

            InfoCard(icon: "shield.lefthalf.filled", title: "You can't overdose from sunlight") {
                InfoText("Here's the elegant part. As UVB keeps hitting your skin, previtamin D3 builds up — but only to a point. At roughly 10–15% conversion it hits a balance, and any extra sunlight starts diverting it into two other molecules — lumisterol and tachysterol — instead. They make no vitamin D, and they can convert back as previtamin D3 is used up.\n\nSo your skin self-limits. Staying out twice as long doesn't give you twice the vitamin D — it plateaus. This is exactly why you can't poison yourself with sunshine, only burn.\n\nSUNniDAY models that plateau. Watch a long session: the numbers climb quickly at first, then flatten.")
            }

            InfoCard(icon: "timer", title: "Why we count sunburn, not minutes") {
                InfoText("\"20 minutes of sun\" means nothing on its own. Twenty minutes at midday in summer is a world away from twenty minutes at 8am in winter.\n\nSo instead of the clock, the app tracks how much of a sunburn you've earned. One full unit — an MED, or minimal erythemal dose — is the amount that would leave your skin just faintly pink the next day. It automatically accounts for how strong the sun is and how easily you burn.\n\nMost of the good vitamin D arrives well before you reach that point, which is why the burn limit is the number worth watching.")
            }

            InfoCard(icon: "sun.haze.fill", title: "Why midday beats morning") {
                InfoText("When the sun is low, its light travels through far more atmosphere to reach you. The ozone up there is very good at absorbing exactly the short-wavelength UVB that makes vitamin D — while the longer wavelengths that redden and age your skin get through more easily.\n\nThe upshot: early morning and late afternoon sun can still burn you, but produce relatively little vitamin D. A rough field test is your shadow — if it's longer than you are tall, the sun is below 45° and vitamin D production is dropping away fast.\n\nThis is also why \"vitamin D winter\" is a real thing: at higher latitudes the midwinter sun never climbs high enough.")
            }

            InfoCard(icon: "person.2.fill", title: "Skin tone changes the clock, not the ceiling") {
                InfoText("Melanin is natural sun protection — it absorbs UV before it reaches the vitamin-D machinery. So darker skin needs considerably longer in the sun for the same result.\n\nBut here's the subtlety: for the same amount of sunburn-equivalent exposure, people of different skin tones produce broadly similar amounts. Melanin changes how long it takes to get there, not how much you can ultimately make. Because the app already measures your dose in sunburn units, your skin type is built in.")
            }

            InfoCard(icon: "questionmark.circle.fill", title: "What we're assuming") {
                VStack(alignment: .leading, spacing: 7) {
                    InfoText("This is a model, not a measurement. Nothing is reading your actual blood levels. In particular:")
                    Bullet("UV comes from a weather forecast for your area — not a sensor on you. Shade, trees and buildings aren't known.")
                    Bullet("We assume the listed clothing genuinely exposes that share of your skin.")
                    Bullet("Sunscreen is assumed to be applied properly. Almost nobody applies enough, so real protection is usually lower than the label.")
                    Bullet("Glass blocks UVB. Sun through a window makes essentially no vitamin D, and the app can't tell.")
                    Bullet("Water, sand and snow bounce extra UV onto you. Not modelled.")
                    Bullet("People vary — genetics, weight and age all shift how much you actually make.")
                    InfoText("Treat the numbers as a well-informed ballpark. Switch to \"The Science\" tab for the equation, the evidence and the full list of limitations.")
                }
            }
        }
    }
}

// MARK: - The Science

private struct ScienceContent: View {
    @EnvironmentObject var vitaminDCalculator: VitaminDCalculator
    @EnvironmentObject var uvService: UVService

    private var dmax: Double { vitaminDCalculator.modelConstants.dmax }
    private var k: Double { vitaminDCalculator.modelConstants.k }

    var body: some View {
        VStack(spacing: 16) {
            modelCard
            saturationCard
            calibrationCard
            elevationCard
            todayCard
            historyCard
            parametersCard
            limitationsCard
            referencesCard
        }
    }

    // MARK: Model

    private var modelCard: some View {
        InfoCard(icon: "function", title: "The model") {
            VStack(alignment: .leading, spacing: 10) {
                InfoText("Dose is expressed as a fraction of an MED — the same unit the photobiology literature uses — and synthesis saturates rather than accumulating linearly:")

                Text("D(m) = D_max × (1 − e^(−k·m))")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.16))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 5) {
                    SpecRow(label: "D_max", value: "\(Int(dmax).formatted()) IU",
                            note: "Whole-body asymptote")
                    SpecRow(label: "k", value: String(format: "%.2f", k),
                            note: "Saturation rate")
                    SpecRow(label: "m", value: "MED fraction",
                            note: "Vitamin-D-weighted dose accumulated")
                }

                InfoText("UV index never appears as its own multiplier. It only sets how fast dose accrues, so the sole non-linearity is the physiological plateau.")

                InfoText("Each increment is weighted by solar elevation and sunscreen as it is banked, then the total is scaled by exposed body surface, age and adaptation.")
            }
        }
    }

    // MARK: Saturation curve

    private var saturationData: [(m: Double, iu: Double)] {
        stride(from: 0.0, through: 3.0, by: 0.02).map {
            ($0, vitaminDCalculator.synthesisCurveIU(atDose: $0))
        }
    }

    private var saturationCard: some View {
        InfoCard(icon: "chart.line.uptrend.xyaxis", title: "Saturation curve") {
            VStack(alignment: .leading, spacing: 10) {
                InfoText("Whole-body synthesis against dose. It flattens because previtamin D3 reaches photoequilibrium — further UV diverts it to lumisterol3 and tachysterol3 rather than more vitamin D.")

                Chart {
                    ForEach(saturationData, id: \.m) { p in
                        LineMark(x: .value("MED", p.m), y: .value("IU", p.iu))
                            .foregroundStyle(.white)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    RuleMark(y: .value("Asymptote", dmax))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .bottom, alignment: .trailing) {
                            Text("D_max")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    PointMark(x: .value("MED", 1.0),
                              y: .value("IU", vitaminDCalculator.synthesisCurveIU(atDose: 1.0)))
                        .foregroundStyle(Color(hex: "f5c842"))
                        .symbolSize(70)
                }
                .chartXAxisLabel("MED fraction", alignment: .center)
                .chartYAxisLabel("IU (whole body)")
                .chartXAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .chartYAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .frame(height: 170)

                InfoText("The gold point is 1 MED. Note that doubling the dose from there adds far less than the first MED did.")
            }
        }
    }

    // MARK: Calibration

    private var calibrationCard: some View {
        InfoCard(icon: "scalemass.fill", title: "Calibration & anchors") {
            VStack(alignment: .leading, spacing: 8) {
                InfoText("Holick's figures derive from fluorescent-lamp studies, and solar UV is roughly 1.32× more previtamin-D-effective per unit erythemal dose. We scale by a deliberately conservative 1.25, giving D_max = 20,000 × 1.25.")

                Divider().overlay(Color.white.opacity(0.25))

                SpecRow(label: "¼ MED over ¼ body",
                        value: "\(Int((vitaminDCalculator.synthesisCurveIU(atDose: 0.25) * 0.25).rounded()).formatted()) IU",
                        note: "Holick's rule: ~1,000 (lamp) / ~1,250 (solar)")
                SpecRow(label: "1 MED, whole body",
                        value: "\(Int(vitaminDCalculator.synthesisCurveIU(atDose: 1.0).rounded()).formatted()) IU",
                        note: "Literature: 10,000–25,000")
                SpecRow(label: "Prolonged exposure",
                        value: "\(Int(dmax).formatted()) IU",
                        note: "Plateau, ~10–15% 7-DHC conversion")

                Divider().overlay(Color.white.opacity(0.25))

                InfoText("That one two-parameter curve reproduces Holick's rule, his per-MED figure and the photoequilibrium plateau simultaneously — which is the main reason to believe the shape.")
            }
        }
    }

    // MARK: Elevation

    private var elevationData: [(elev: Double, q: Double)] {
        stride(from: 0.0, through: 90.0, by: 1.0).map {
            ($0, vitaminDCalculator.vitaminDQualityFactor(forElevationDegrees: $0))
        }
    }

    private var elevationCard: some View {
        InfoCard(icon: "angle", title: "Solar elevation weighting") {
            VStack(alignment: .leading, spacing: 10) {
                InfoText("MED is erythemally weighted, but the vitamin D action spectrum sits further into the UVB. At low sun the longer atmospheric path strips the short UVB that drives synthesis while leaving the wavelengths that drive erythema — so an MED earned at 8am yields far less vitamin D than one earned at noon.")

                Text("quality = min(1, (sin θ ÷ sin 50°)^1.5)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.16))
                    .cornerRadius(8)

                Chart {
                    ForEach(elevationData, id: \.elev) { p in
                        AreaMark(x: .value("Elevation", p.elev), y: .value("Quality", p.q))
                            .foregroundStyle(.linearGradient(
                                colors: [Color(hex: "f5c842").opacity(0.55), .clear],
                                startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Elevation", p.elev), y: .value("Quality", p.q))
                            .foregroundStyle(.white)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    RuleMark(x: .value("Shadow rule", 45))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("45° · shadow = height")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.8))
                        }
                }
                .chartXAxisLabel("Sun elevation (°)", alignment: .center)
                .chartYAxisLabel("Vit D per MED")
                .chartYScale(domain: 0...1)
                .chartXAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .chartYAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .frame(height: 160)

                InfoText("The 1.5 exponent is an engineering approximation of the action-spectrum ratio, not a measured constant — it is the least certain number in the model.")
            }
        }
    }

    // MARK: Today

    private struct HourPoint: Identifiable {
        let id = UUID()
        let date: Date
        let elevation: Double
        let quality: Double
    }

    private var todayPoints: [HourPoint] {
        guard let sunrise = uvService.todaySunrise, let sunset = uvService.todaySunset,
              sunset > sunrise else { return [] }
        let start = sunrise.addingTimeInterval(-1800)
        let end = sunset.addingTimeInterval(1800)
        let step = end.timeIntervalSince(start) / 60.0
        return stride(from: 0.0, through: 60.0, by: 1.0).compactMap { i in
            let d = start.addingTimeInterval(step * i)
            guard let e = vitaminDCalculator.solarElevationDegrees(at: d) else { return nil }
            return HourPoint(date: d, elevation: e,
                             quality: vitaminDCalculator.vitaminDQualityFactor(forElevationDegrees: e))
        }
    }

    private var solarNoon: Date? {
        guard let sr = uvService.todaySunrise, let ss = uvService.todaySunset else { return nil }
        return Date(timeIntervalSince1970: (sr.timeIntervalSince1970 + ss.timeIntervalSince1970) / 2)
    }

    @ViewBuilder private var todayCard: some View {
        if !todayPoints.isEmpty {
            InfoCard(icon: "clock.fill", title: "Today, where you are") {
                VStack(alignment: .leading, spacing: 10) {
                    InfoText("The same curve applied to today's sun at your location. Solar noon is taken as the midpoint of sunrise and sunset, which corrects for daylight saving, your longitude within the timezone, and the equation of time in one step.")

                    Chart {
                        ForEach(todayPoints) { p in
                            AreaMark(x: .value("Time", p.date), y: .value("Quality", p.quality))
                                .foregroundStyle(.linearGradient(
                                    colors: [Color(hex: "f5c842").opacity(0.55), .clear],
                                    startPoint: .top, endPoint: .bottom))
                            LineMark(x: .value("Time", p.date), y: .value("Quality", p.quality))
                                .foregroundStyle(.white)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        if let noon = solarNoon {
                            RuleMark(x: .value("Solar noon", noon))
                                .foregroundStyle(.white.opacity(0.45))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                        RuleMark(x: .value("Now", Date()))
                            .foregroundStyle(Color(hex: "f5c842"))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .annotation(position: .top, alignment: .center) {
                                Text("now")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(hex: "f5c842"))
                            }
                    }
                    .chartYAxisLabel("Vit D per MED")
                .chartYScale(domain: 0...1)
                    .chartXAxis { AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.15))
                        AxisValueLabel(format: .dateTime.hour())
                            .foregroundStyle(.white.opacity(0.8))
                    } }
                    .chartYAxis { AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.15))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                    } }
                    .frame(height: 160)

                    if let noon = solarNoon {
                        VStack(alignment: .leading, spacing: 5) {
                            SpecRow(label: "Solar noon",
                                    value: noon.formatted(date: .omitted, time: .shortened))
                            if let peak = todayPoints.max(by: { $0.elevation < $1.elevation }) {
                                SpecRow(label: "Peak sun elevation",
                                        value: String(format: "%.1f°", peak.elevation))
                            }
                            SpecRow(label: "Right now",
                                    value: String(format: "%.0f%%",
                                                  vitaminDCalculator.currentUVQualityFactor * 100),
                                    note: "of peak vitamin D per MED")
                        }
                    }
                }
            }
        }
    }

    // MARK: Parameters

    // MARK: History trend line

    private var historyCard: some View {
        InfoCard(icon: "chart.bar.xaxis", title: "The history trend line") {
            VStack(alignment: .leading, spacing: 10) {
                InfoText("History shows daily synthesis as bars, with a trend line over the top. That line is not a plain average — it's weighted by how your body actually holds vitamin D.")

                InfoText("Circulating 25(OH)D — the storage form a blood test measures — has a half-life of roughly three weeks, so a day of sun keeps contributing to your reserve for weeks afterward, fading as it goes. The trend line reproduces that: each past day is discounted by its age.")

                Text("weight = 0.966 ^ (days ago)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.16))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 5) {
                    SpecRow(label: "Assumed 25(OH)D half-life", value: "20 days",
                            note: "Decay factor 0.966/day = 2^(−1/20)")
                    SpecRow(label: "Seed history", value: "~60 days",
                            note: "3 half-lives, so the visible window starts accurate")
                }

                InfoText("So the line rising means you're outpacing that decay — banking stores faster than your body loses them. Falling means the opposite. It's an estimate of a trend, not your actual blood level, which only a test can give.")

                Text("The 20-day figure is a round value within the reported 2–3 week range; individuals vary, and it is not personalised.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var parametersCard: some View {
        InfoCard(icon: "slider.horizontal.3", title: "Parameters") {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    Text("Body surface exposed")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                    VStack(spacing: 4) {
                        ForEach(ClothingLevel.allCases, id: \.rawValue) { c in
                            SpecRow(label: c.description,
                                    value: "\(Int(c.exposureFactor * 100))%")
                        }
                    }
                }

                Divider().overlay(Color.white.opacity(0.25))

                Group {
                    Text("Minutes to 1 MED at UV 1")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                    VStack(spacing: 4) {
                        ForEach(SkinType.allCases, id: \.rawValue) { s in
                            SpecRow(label: "Type \(s.rawValue) · \(s.description)",
                                    value: "\(Int(VitaminDCalculator.medMinutesAtUV1[s.rawValue] ?? 0)) min")
                        }
                    }
                    InfoText("Scaled by UV: at UV 5 these are five times faster. No separate pigment multiplier is applied — see limitations.")
                }

                Divider().overlay(Color.white.opacity(0.25))

                Group {
                    Text("Sunscreen UV transmission")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                    VStack(spacing: 4) {
                        ForEach(SunscreenLevel.allCases, id: \.rawValue) { s in
                            SpecRow(label: s.description,
                                    value: "\(Int(s.uvTransmissionFactor * 100))%")
                        }
                    }
                }

                Divider().overlay(Color.white.opacity(0.25))

                Group {
                    Text("Age")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                    InfoText("Cutaneous 7-dehydrocholesterol declines with age: full capacity to 20, then about 1% per year, floored at 25% from age 70. Applied only when age is available from Health.")
                }
            }
        }
    }

    // MARK: Limitations

    private var limitationsCard: some View {
        InfoCard(icon: "exclamationmark.triangle.fill", title: "Assumptions & limitations") {
            VStack(alignment: .leading, spacing: 7) {
                Bullet("Every figure is modelled, never measured. No sensor observes your skin and nothing here reflects serum 25(OH)D.")
                Bullet("UV is a gridded forecast (Open-Meteo) for your coordinates, not a local reading. Shade, cloud breaks, buildings and tree cover are invisible to it.")
                Bullet("Manually overriding cloud cover replaces the forecast with your judgement, and scales the estimate accordingly.")
                Bullet("The 1.5 elevation exponent approximates the erythemal→previtamin-D action-spectrum ratio. The action spectrum itself was still under formal revision as of 2023.")
                Bullet("Per-MED synthesis is treated as independent of skin pigmentation. MED already encodes phototype, so applying a pigment multiplier as well would double-count melanin. This follows Holick 1981, but it is a modelling choice.")
                Bullet("D_max = 25,000 IU sits mid-range in a literature spread of 10,000–25,000 that traces largely to one group's lamp-based work, and the underlying rule has a documented methodological critique.")
                Bullet("Body surface is treated as a linear scalar and assumes the stated clothing genuinely exposes that fraction.")
                Bullet("Sunscreen assumes laboratory-standard application (2 mg/cm²). Typical real-world application is far thinner, so actual protection is usually lower — meaning true synthesis is likely higher than shown.")
                Bullet("Glass transmits UVA but blocks UVB. Sun through a window produces almost no vitamin D and the app cannot detect it.")
                Bullet("Reflective surfaces — snow, water, sand, concrete — add UV that is not modelled.")
                Bullet("Altitude is passed to the forecast but no additional multiplier is applied, to avoid double-counting.")
                Bullet("Individual variation in 7-DHC density, adiposity, genetics and baseline status is not represented. The adaptation factor is a heuristic, not a validated physiological term.")
                Bullet("The burn limit ignores sunscreen, so it is deliberately conservative if you are wearing any.")
                Bullet("The history trend line assumes a fixed 20-day 25(OH)D half-life for everyone; true half-life varies by person and is not personalised. It estimates a trend, not a blood level.")
            }
        }
    }

    // MARK: References

    private var referencesCard: some View {
        InfoCard(icon: "book.fill", title: "References") {
            VStack(alignment: .leading, spacing: 11) {
                RefLink(title: "Holick MF et al. (1981)",
                        detail: "Regulation of cutaneous previtamin D3 photosynthesis in man: skin pigment is not an essential regulator. Science 211:590–3. — photoequilibrium plateau; basis for saturation and for omitting a pigment multiplier.",
                        url: "https://www.science.org/doi/10.1126/science.6256855")
                RefLink(title: "MacLaughlin JA, Anderson RR, Holick MF (1982)",
                        detail: "Spectral character of sunlight modulates photosynthesis of previtamin D3 and its photoisomers in human skin. Science 216:1001–3. — action spectrum; optimum 295–300 nm.",
                        url: "https://www.science.org/doi/10.1126/science.6281884")
                RefLink(title: "Young AR et al. (2021)",
                        detail: "A revised action spectrum for vitamin D synthesis by suberythemal UV radiation exposure in humans in vivo. PNAS 118(40). — in vivo, n=75; finds erythemally-weighted dose is a poor predictor of synthesis; proposes a 5 nm shift. Basis for elevation weighting.",
                        url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8501902/")
                RefLink(title: "Holick's rule and vitamin D from sunlight",
                        detail: "Notes the rule derives from a fluorescent-lamp spectrum; solar UV is ~1.32× more previtamin-D-effective per erythemal unit. Basis for the 1.25 calibration.",
                        url: "https://www.sciencedirect.com/science/article/abs/pii/S0960076010001925")
                RefLink(title: "Pope SJ et al. (2008)",
                        detail: "Action spectrum conversion factors that change erythemally weighted to previtamin D3-weighted UV doses. Photochem Photobiol 84(5).",
                        url: "https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1751-1097.2008.00373.x")
                RefLink(title: "Webb AR et al. (2023)",
                        detail: "Previtamin D action spectrum: challenging CIE towards a standard. — the spectrum remains formally unsettled.",
                        url: "https://journals.sagepub.com/doi/full/10.1177/14771535221122937")
                RefLink(title: "Open-Meteo",
                        detail: "UV index, clear-sky UV, cloud cover and sun times. No API key, no tracking.",
                        url: "https://open-meteo.com")

                Divider().overlay(Color.white.opacity(0.25))

                InfoText("SUNniDAY is based on Sun Day by Jack Dorsey, released into the public domain (Unlicense). The synthesis model has since been substantially reworked.")
                RefLink(title: "github.com/jackjackbits/sunday",
                        detail: "Original project.",
                        url: "https://github.com/jackjackbits/sunday")
                RefLink(title: "github.com/JWAY21/sunniday",
                        detail: "This fork — full source.",
                        url: "https://github.com/JWAY21/sunniday")
            }
        }
    }
}

private struct RefLink: View {
    let title: String
    let detail: String
    let url: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let u = URL(string: url) {
                Link(destination: u) {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .underline()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            } else {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(detail)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
