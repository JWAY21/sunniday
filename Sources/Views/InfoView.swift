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
    @State private var showSources = false

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

                        Text("SUNniDAY gives estimates, not measurements. It is not medical advice. Talk to a doctor before changing sun habits or supplements.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .padding(.horizontal, 8)
                    }
                    .padding(20)
                }
                .glossaryTaps()
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "7f92d6"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                // Labelled, and present on both tabs. The citations themselves
                // sit at the foot of the Science tab, which is not the tab that
                // opens, so they were effectively unfindable (App Review 1.4.1).
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSources = true
                    } label: {
                        // Explicit stack rather than Label: the navigation bar
                        // collapses a Label to icon-only regardless of
                        // labelStyle, and an unlabelled icon is exactly the
                        // discoverability problem this is meant to solve.
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 13))
                            Text("Sources")
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSources) { SourcesView() }
        }
    }
}

// MARK: - Shared building blocks

extension View {
    /// Caps Dynamic Type growth inside a chart.
    ///
    /// Swift Charts sizes its axis tick labels from Dynamic Type, even though
    /// the rest of this app uses fixed point sizes and does not scale at all.
    /// At the accessibility sizes those labels grew until they overlapped each
    /// other and spilled across the plot area, so the charts became unreadable
    /// rather than merely large. Capping keeps some scaling for people who need
    /// it while keeping the axes legible, and matches the fixed sizing used
    /// everywhere else in the app.
    func chartLabelsLegible() -> some View {
        dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

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
                GlossaryText("Vitamin D isn't really a vitamin. It's a [hormone](glossary://hormone) your body builds itself. Deep in your skin sits a cholesterol-like molecule called [7-dehydrocholesterol](glossary://7-dhc). When a narrow band of ultraviolet light ([UVB](glossary://uvb), around 295\u{2013}300 nanometres) hits it, the molecule snaps into a new shape called [previtamin D3](glossary://previtamin-d3), which your body then converts into the vitamin D that ends up in your blood as [25(OH)D](glossary://25ohd), the form a blood test measures.\n\nFood and supplements are helpful but sunlight is the route we evolved with.")
            }

            InfoCard(icon: "shield.lefthalf.filled", title: "You can't overdose from sunlight") {
                GlossaryText("Here's the elegant part. As [UVB](glossary://uvb) keeps hitting your skin, [previtamin D3](glossary://previtamin-d3) builds up, but only to a point. At roughly 10\u{2013}15% conversion of your [7-DHC](glossary://7-dhc) it hits a balance, and any extra sunlight starts diverting previtamin D3 into two other molecules, [lumisterol](glossary://photoproducts) and [tachysterol](glossary://photoproducts), instead. They make no vitamin D, and they can convert back as previtamin D3 is used up.\n\nSo your skin self-limits. Staying out twice as long doesn't give you twice the vitamin D. It plateaus. This is exactly why you can't poison yourself with sunshine, only burn.\n\nSUNniDAY models that plateau. Watch a long session: the numbers climb quickly at first, then flatten. Sessions through the day feed the same ceiling rather than each starting fresh, and it resets at midnight, a simple stand-in for the day or so your skin's 7-DHC stores take to recover.")
            }

            InfoCard(icon: "timer", title: "Why we count fractions of a sunburn (MED), not minutes") {
                GlossaryText("\"20 minutes of sun\" means nothing on its own. Twenty minutes at midday in summer is a world away from twenty minutes at 8am in winter.\n\nThe app tracks how much of a sunburn you've earned. One full unit, an [MED, or minimal erythemal dose](glossary://med), is the amount that would leave your skin just faintly pink the next day. You set your skin type and what you're wearing; the app pulls the UV for where you are automatically, and you can correct the cloud cover by tapping it.\n\nMost of the good vitamin D arrives well before you reach that point, which is why the burn limit is the number worth watching.")
            }

            InfoCard(icon: "sun.haze.fill", title: "Why midday beats morning") {
                GlossaryText("When the sun sits low, its light has to travel through far more atmosphere to reach you, and the ozone up there is very good at absorbing exactly the short-wavelength UVB that makes vitamin D. The [longer wavelengths that redden and age your skin](glossary://uva) get through more easily. So early morning and late afternoon sun can still burn you while producing relatively little vitamin D.\n\nA rough field test is your shadow. If it's longer than you are tall, the sun has dropped below 45\u{00B0} and vitamin D production is falling away fast. The same geometry is why \"vitamin D winter\" is real: at higher latitudes the midwinter sun never climbs high enough to make much at all.\n\nThe app follows the sun's true angle through the day and scales your vitamin D down as it drops, to almost nothing near the horizon. Vitamin D winter isn't a rule we typed in, it falls out of the geometry.\n\nNone of which makes early light worthless, it just isn't doing much for vitamin D. Morning daylight is the strongest signal your body clock gets, landing on specialised cells in the retina that set your sleep timing, alertness and hormone rhythm for the rest of the day. You'll also see claims that the [red and infrared](glossary://infrared) in low sun helps your mitochondria: the mechanism is real in the laboratory, but the human evidence is still thin. Vitamin D is one reason to get outside. It isn't the only one.")
            }

            InfoCard(icon: "person.2.fill", title: "Skin tone changes the clock, not the ceiling") {
                GlossaryText("[Melanin](glossary://melanin) is natural sun protection. It absorbs UV before it reaches the vitamin-D machinery, so darker skin needs considerably longer in the sun for the same level of vitamin D synthesis.\n\nFor the same amount of sunburn-equivalent exposure (MED), people of different skin tones produce broadly similar amounts. Melanin changes how long it takes to get there, not how much you can ultimately make. Because the app already measures your dose in sunburn units, your skin type is built in.")
            }

            InfoCard(icon: "questionmark.circle.fill", title: "What we're assuming") {
                VStack(alignment: .leading, spacing: 7) {
                    InfoText("This is a model, not a measurement. Nothing is reading your actual blood levels. In particular:")
                    Bullet("UV comes from a weather forecast for your area, not a sensor on you. Shade, trees and buildings aren't known.")
                    Bullet("We assume the listed clothing genuinely exposes that share of your skin.")
                    Bullet("Sunscreen is assumed to be applied properly. Almost nobody applies enough, so real protection is usually lower than the label.")
                    Bullet("Glass blocks UVB while letting UVA through. Sun through a window makes essentially no vitamin D, but the UVA still reaches you and still ages and damages skin.")
                    Bullet("Water, sand and snow bounce extra UV onto you. Not modelled.")
                    Bullet("People vary. Genetics, weight and age all shift how much you actually make.")
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
                GlossaryText("Dose is expressed as a fraction of an [MED](glossary://med), the same unit the photobiology literature uses, and synthesis saturates rather than accumulating linearly:")

                Text("D(m) = D_max \u{00D7} (1 \u{2212} e^(\u{2212}k\u{00B7}m))")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.16))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 5) {
                    SpecRow(label: "D(m)", value: "IU",
                            note: "What you get: whole-body vitamin D at dose m, before body-surface and physiological modifiers")
                    SpecRow(label: "D_max", value: "\(Int(dmax).formatted()) IU",
                            note: "The ceiling. However long you stay out, one day cannot exceed this")
                    SpecRow(label: "m", value: "MED fraction",
                            note: "Dose so far today, in sunburn units, weighted for how vitamin-D-effective that UV was")
                    SpecRow(label: "k", value: String(format: "%.2f", k),
                            note: "How fast you approach the ceiling. Higher means you saturate sooner")
                    SpecRow(label: "e", value: "2.718…",
                            note: "Base of natural logarithms, which is what makes the curve bend rather than climb straight")
                }

                InfoText("Read plainly: start at zero, climb steeply, then flatten toward D_max as m grows. UV index never appears as its own multiplier. It only sets how fast dose accrues, so the sole non-linearity is the physiological plateau.")

                InfoText("Each increment is weighted by solar elevation and sunscreen as it is banked, then the total is scaled by exposed body surface, age and adaptation.")

                GlossaryText("The plateau belongs to the day, not the session. [Photoequilibrium](glossary://photoequilibrium) is a property of your skin, and it doesn't reset because you came inside for lunch, so every session in a day shares one curve. A second session starts where the first left off and earns the flatter part, giving real diminishing returns.")

                InfoText("The real recovery has no clean finish line. Previtamin D3 keeps converting to vitamin D3 for a day or more after you come inside; the lumisterol and tachysterol sitting in the overflow drift back as previtamin D3 is drawn off; and your skin manufactures fresh 7-DHC continuously the whole time. These overlap, and no published figure pins down when the pool is truly restored.")

                InfoText("Three separate 1 MED sessions therefore yield the same as one continuous 3 MED session: about 23,400 IU, not 45,100. Splitting your sun into chunks can't beat the ceiling. The app resets the day's dose at midnight, which is a simplification chosen for clarity rather than a claim about your skin.")
            }
        }
    }

    private var saturationData: [(m: Double, iu: Double)] {
        stride(from: 0.0, through: 3.0, by: 0.02).map {
            ($0, vitaminDCalculator.synthesisCurveIU(atDose: $0))
        }
    }

    private var saturationCard: some View {
        InfoCard(icon: "chart.line.uptrend.xyaxis", title: "Saturation curve") {
            VStack(alignment: .leading, spacing: 10) {
                GlossaryText("Whole-body synthesis against dose. It flattens because previtamin D3 reaches [photoequilibrium](glossary://photoequilibrium), and further UV diverts it to lumisterol3 and tachysterol3 rather than making more vitamin D.")

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
                .chartLabelsLegible()

                InfoText("The gold point is 1 MED. Note that doubling the dose from there adds far less than the first MED did.")
            }
        }
    }

    // MARK: Calibration

    private var calibrationCard: some View {
        InfoCard(icon: "scalemass.fill", title: "Calibration & anchors") {
            VStack(alignment: .leading, spacing: 8) {
                GlossaryText("[Holick](glossary://holick)'s figures derive from fluorescent-lamp studies, and solar UV is roughly 1.32\u{00D7} more previtamin-D-effective per unit [erythemal](glossary://erythema) dose. We scale by a deliberately conservative 1.25, giving D_max = 20,000 \u{00D7} 1.25.")

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

                InfoText("The curve has only two free numbers, D_max and k, yet it lands on three independent figures at once. Holick's rule puts a quarter of an MED over a quarter of the body at about 1,000 IU. The wider literature puts one whole-body MED at 10,000 to 25,000. And the photochemistry caps any single day near the plateau. A two-parameter curve with the wrong shape would normally match one of those and miss the others, so hitting all three is the real reason to trust it.")
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
                GlossaryText("[MED](glossary://med) is erythemally weighted, but the vitamin D [action spectrum](glossary://action-spectrum) sits further into the UVB. At low sun angles, the longer atmospheric path strips the short UVB that drives synthesis while leaving the wavelengths that drive [erythema](glossary://erythema), so an MED earned at 8am yields far less vitamin D than one earned at noon.")

                Text("quality = min(1, (sin θ ÷ sin 50°)^1.5)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.16))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 5) {
                    SpecRow(label: "quality", value: "0 to 1",
                            note: "The multiplier applied to each dose increment as it is banked")
                    SpecRow(label: "\u{03B8}", value: "sun angle",
                            note: "How high the sun sits above the horizon at that moment")
                    SpecRow(label: "sin 50\u{00B0}", value: "reference",
                            note: "At 50\u{00B0} or higher the sun earns full credit")
                    SpecRow(label: "^1.5", value: "falloff",
                            note: "How sharply yield drops as the sun gets lower. The uncertain one")
                    SpecRow(label: "min(1, \u{2026})", value: "cap",
                            note: "Stops very high sun from scoring above full credit")
                }

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
                .chartLabelsLegible()

                InfoText("The 1.5 exponent is an engineering approximation of the action-spectrum ratio, not a measured constant. It is the least certain number in the model.")
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
                    InfoText("The same curve applied to today's sun at your location. Solar noon is taken as the midpoint of sunrise and sunset rather than read off the clock. That one step quietly handles three things at once: daylight saving, the fact that you sit east or west of your timezone's centre, and the sun's own seasonal drift, which runs up to about a quarter of an hour either way.")

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
                    .chartLabelsLegible()

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
                InfoText("History shows daily synthesis as bars. The line over the top is a best-guess of the reserve those days have banked, shown in the same unit as the bars but on its own scale on the right, because a reserve is much larger than a single day.")

                GlossaryText("Vitamin D's storage form, [25(OH)D](glossary://25ohd), has a [half-life](glossary://half-life) of about 2–3 weeks, so what you make doesn't vanish overnight. It accumulates and clears slowly. That's the standard [one-compartment model](glossary://one-compartment): each day adds intake, and the store loses a fixed fraction:")

                Text("store → store × 0.966 + today's intake")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.16))
                    .cornerRadius(8)

                InfoText("So a good run of days lifts the line; a lazy week lets it fall. It also saturates, because the real blood response curves rather than climbing straight. The fuller the reserve, the less each extra day adds: in supplement trials, going from 1,000 to 4,000 IU a day lifts blood levels by only about half as much per unit, and it flattens further from there. Fuller stores also clear faster. So doubling your sun doesn't double your reserve.")

                VStack(alignment: .leading, spacing: 5) {
                    SpecRow(label: "Assumed 25(OH)D half-life", value: "20 days",
                            note: "Round value in the reported 2–3 week range; not personalised")
                }

                Bullet("This is a best guess, not a blood level. The app estimates cutaneous synthesis, which is not calibrated to serum 25(OH)D. Only a blood test gives that. The absolute figure is indicative; read the direction it's heading, not the exact number.")

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
                    InfoText("Scaled by UV: at UV 5 these are five times faster. No separate pigment multiplier is applied, see limitations.")
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
                    InfoText("Modelled as full capacity to age 20, then declining 1.5% a year to a floor of 25% at age 70. Applied only when age is available from Health.\n\nThis one is contested, see limitations.")
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
                Bullet("The 1.5 elevation exponent approximates the erythemal to previtamin-D action-spectrum ratio. The action spectrum itself was still under formal revision as of 2023.")
                Bullet("Per-MED synthesis is treated as independent of skin pigmentation. MED already encodes phototype, so applying a pigment multiplier as well would double-count melanin. This follows Holick 1981, but it is a modelling choice.")
                Bullet("D_max = (20,000 IU \u{00D7} 1.25) sits mid-range in a literature spread of 10,000\u{2013}25,000 that traces largely to one group's lamp-based work, and the underlying rule has a documented methodological critique.")
                Bullet("Body surface is treated as a linear scalar and assumes the stated clothing genuinely exposes that fraction.")
                Bullet("Sunscreen assumes laboratory-standard application (2 mg/cm\u{00B2}). Typical real-world application is far thinner, so actual protection is usually lower, meaning true synthesis is likely higher than shown.")
                Bullet("Glass transmits UVA but blocks UVB. Sun through a window produces almost no vitamin D.")
                Bullet("Reflective surfaces such as snow, water, sand and concrete add UV that is not modelled.")
                Bullet("Altitude is passed to the forecast but no additional multiplier is applied, to avoid double-counting.")
                Bullet("Individual variation in 7-DHC density, adiposity, genetics and baseline status is not represented. The adaptation factor is a heuristic, not a validated physiological term.")
                Bullet("The age decline is contested. It follows MacLaughlin & Holick (1985), which found a more-than-twofold drop with age. But a 2024 study measuring skin 7-DHC directly found no significant difference between healthy older and younger adults, and a similar vitamin D response to UV, suggesting older adults' typically lower status may owe more to behaviour (less skin exposed, less time outdoors) than to a fixed biological ceiling. Treat the age factor as one plausible model, not settled fact.")
                Bullet("The burn limit ignores sunscreen, so it is deliberately conservative if you are wearing any.")
                Bullet("The saturation ceiling is shared across a day and resets at local midnight. Real recovery is gradual rather than instant, so that boundary is arbitrary: sun late one evening and again early the next morning counts as two fresh starts even though your skin has had only a few hours, and several heavy days in a row carry no residue forward.")
                Bullet("The history trend line is a relative modelled reserve, not a blood level. Synthesised mcg isn't calibrated to serum nmol/L. It assumes a fixed 20-day half-life for everyone and a generic saturation, whereas a real body has fat stores, protein binding, faster clearance at high levels and feedback that it doesn't capture.")
            }
        }
    }

    // MARK: References

    private var referencesCard: some View {
        // Rendered from AppReferences so this card and the Sources sheet cannot
        // drift apart. The same list appears under a labelled Sources button.
        InfoCard(icon: "book.fill", title: "References") {
            VStack(alignment: .leading, spacing: 11) {
                ForEach(AppReferences.model) { ReferenceLink(reference: $0) }
                ForEach(AppReferences.data) { ReferenceLink(reference: $0) }

                Divider().overlay(Color.white.opacity(0.25))

                InfoText("SUNniDAY is based on Sun Day by Jack Dorsey, released into the public domain (Unlicense). The synthesis model has since been substantially reworked.")
                ForEach(AppReferences.attribution) { ReferenceLink(reference: $0) }
            }
        }
    }
}

