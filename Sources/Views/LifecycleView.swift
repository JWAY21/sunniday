import SwiftUI
import Charts

/// Easter egg: tapping the SUNniDAY wordmark opens the full life cycle of
/// vitamin D, at two depths — a plain-language walkthrough, and a deep dive
/// with the enzymes, kinetics, charts, tables, glossary and papers.
///
/// Styled to match InfoView ("How It Works"): a segmented Basics/Science
/// picker over a stack of InfoCards.
struct LifecycleView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("lifecycleShowsScience") private var showsScience = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "6d7fc9"), Color(hex: "a9a3e0"), Color(hex: "f2b79c")],
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
                            LifecycleScience()
                        } else {
                            LifecycleBasics()
                        }

                        Text("Written for curiosity, not clinical use. Vitamin D supplements are genuinely valuable — especially in winter, at high latitude, for darker skin, and for anyone mostly indoors. Talk to a doctor about your own levels.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .padding(.horizontal, 8)
                    }
                    .padding(20)
                }
                .glossaryTaps()
            }
            .navigationTitle("The Life of Vitamin D")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "6d7fc9"), for: .navigationBar)
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

// MARK: - Shared pieces

private struct LifeText: View {
    let text: String
    var size: CGFloat = 14
    init(_ text: String, size: CGFloat = 14) { self.text = text; self.size = size }
    var body: some View {
        Text(text)
            .font(.system(size: size))
            .foregroundColor(.white.opacity(0.92))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Label/value row for the science tables.
private struct LifeSpecRow: View {
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
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 10)
            Text(value)
                .font(.system(size: 12.5, weight: .semibold).monospacedDigit())
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct MoleculeChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.18))
            .cornerRadius(6)
    }
}

private struct Aside: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: "sparkles")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "f5c842"))
            GlossaryText(text, size: 12.5, opacity: 0.88)
        }
        .padding(11)
        .background(Color.white.opacity(0.13))
        .cornerRadius(10)
    }
}

/// One stage of the pathway, rendered as an InfoCard (matching How It Works).
private struct StageCard: View {
    let icon: String
    let title: String
    var molecule: String? = nil
    let text: String
    var aside: String? = nil

    init(icon: String, title: String, molecule: String? = nil, body: String, aside: String? = nil) {
        self.icon = icon
        self.title = title
        self.molecule = molecule
        self.text = body
        self.aside = aside
    }

    var body: some View {
        InfoCard(icon: icon, title: title) {
            if let molecule { MoleculeChip(text: molecule) }
            GlossaryText(text)
            if let aside { Aside(aside) }
        }
    }
}

/// A contrast card (why sun ≠ a pill).
private struct ContrastCard: View {
    let icon: String
    let title: String
    let text: String

    init(icon: String, title: String, body: String) {
        self.icon = icon
        self.title = title
        self.text = body
    }

    var body: some View {
        InfoCard(icon: icon, title: title) {
            LifeText(text)
        }
    }
}

// MARK: - The Basics

private struct LifecycleBasics: View {
    var body: some View {
        VStack(spacing: 16) {
            InfoCard(icon: "sparkle.magnifyingglass", title: "A molecule's journey") {
                LifeText("Vitamin D isn't a vitamin at all — it's a hormone, and one of the few your body can't finish building without help from the sky. Here's the whole trip, in plain language.")
            }

            ForEach(BasicStep.all) { step in
                StageCard(icon: step.icon, title: step.title, body: step.body, aside: step.aside)
            }

            InfoCard(icon: "pills.fill", title: "So why not just take a pill?") {
                LifeText("Supplements work — they reliably raise your levels, and matter for anyone who can't get sun. But swallowing vitamin D joins this story near the end, and skipping the first half turns out to matter.")
            }

            ForEach(BasicContrast.all) { c in
                ContrastCard(icon: c.icon, title: c.title, body: c.body)
            }

            InfoCard(icon: "quote.closing", title: "The short version") {
                LifeText("Sunlight and vitamin D aren't the same thing. A capsule carries part of the parcel, not all of it.")
            }
        }
    }
}

private struct BasicStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    var aside: String? = nil

    static let all: [BasicStep] = [
        BasicStep(icon: "arrow.branch",
                  title: "It's built from a near-miss cholesterol",
                  body: "You'll often hear that sunlight turns cholesterol into vitamin D. It's actually made from the molecule your body uses one step before cholesterol — a not-quite-finished version your skin keeps a supply of.",
                  aside: "Which means cholesterol from food can't be turned into vitamin D. The step only runs one way."),
        BasicStep(icon: "square.stack.3d.up.fill",
                  title: "Your skin keeps a supply ready",
                  body: "Your skin's outer layers have no blood supply of their own, so they make their own building materials. A standing pool of that precursor sits in the living layers just beneath the surface — a light-sensitive stockpile, kept in the one organ that meets the sun."),
        BasicStep(icon: "sun.max.fill",
                  title: "Sunlight does the one thing you can't",
                  body: "A particular slice of UVB light carries exactly the right energy to snap one bond in that molecule's ring, springing it open. That open ring is the whole point — it lets the molecule fold into a shape your body can read.",
                  aside: "No enzyme in your body can do this step. The energy has to arrive as light. It's the only reason sunshine matters here at all."),
        BasicStep(icon: "thermometer.medium",
                  title: "Your own body heat finishes it",
                  body: "What sunlight makes isn't quite vitamin D yet. Over the following hours your body warmth quietly rearranges it into the real thing — no light needed.",
                  aside: "So you keep making vitamin D after you've come inside. The sun starts it; your warmth finishes it over the next day or two."),
        BasicStep(icon: "shield.lefthalf.filled",
                  title: "When you've had enough, it just stops",
                  body: "Keep sitting in the sun and the process quietly plateaus. Extra sunlight starts making other molecules instead of more vitamin D.\n\nThis is why sunshine can't give you vitamin D poisoning. The chemistry itself refuses — you can still burn, but you can't overdose.",
                  aside: "And those other molecules aren't waste. Scientists assumed for decades they did nothing; it turns out they have jobs of their own, protecting skin from damage."),
        BasicStep(icon: "cross.case.fill",
                  title: "Your liver stores it, your kidney switches it on",
                  body: "It travels to the liver, which converts it into the storage form that sits in your blood for weeks — that's the number a blood test reports.\n\nWhen your body actually needs it, the kidney flips it into the active form, which only lasts hours and is kept on a very tight leash.",
                  aside: "So \"your vitamin D level\" is really your reserve tank, not the working hormone. It's why a single sunny weekend barely moves it, but a habit over months does."),
        BasicStep(icon: "dna",
                  title: "It talks to your genes",
                  body: "The active form slips into your cells and settles onto your DNA, turning genes up and down — calcium and bone, immune responses, how cells grow and specialise.\n\nThat's why it behaves like a hormone rather than a nutrient. It isn't fuel; it's instructions."),
        BasicStep(icon: "arrow.uturn.down",
                  title: "Then it tidies up after itself",
                  body: "Finally, the active form switches on the very enzyme that destroys it, and gets broken down and cleared. The signal stays short and self-correcting — the body never lets it shout for long.")
    ]
}

private struct BasicContrast: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String

    static let all: [BasicContrast] = [
        BasicContrast(icon: "shield.lefthalf.filled",
                      title: "One has a brake, the other doesn't",
                      body: "Sun stops itself. Capsules don't — which is why you can take too much vitamin D but you can't sunbathe your way to toxicity."),
        BasicContrast(icon: "chart.line.flattrend.xyaxis",
                      title: "A trickle beats a flood",
                      body: "Skin releases vitamin D slowly over days. A capsule arrives all at once, and some gets stashed in body fat on the way past. Same molecule, very different delivery."),
        BasicContrast(icon: "wand.and.stars",
                      title: "Sunlight makes more than one thing",
                      body: "Those extra molecules made when you've had enough sun come only from light, and they have their own protective roles. A vitamin D capsule contains exactly one of the things sunshine makes."),
        BasicContrast(icon: "heart.fill",
                      title: "And light does jobs vitamin D doesn't",
                      body: "Sunlight also releases a compound stored in your skin that relaxes blood vessels and lowers blood pressure — an effect shown to work independently of vitamin D entirely. Add sleep timing and mood, and \"go outside\" is doing several things at once."),
        BasicContrast(icon: "questionmark.circle.fill",
                      title: "The uncomfortable evidence",
                      body: "People with low vitamin D get more heart disease, diabetes and cancer. Yet big trials handing out supplements mostly failed to prevent any of it.\n\nThe leading explanation: low vitamin D may often be a sign of poor health and little time outdoors rather than the cause of it. If so, topping up the reading was never going to deliver what the sunshine was doing.")
    ]
}

// MARK: - The Science

private struct LifecycleScience: View {
    var body: some View {
        VStack(spacing: 16) {
            InfoCard(icon: "atom", title: "Secosteroid biosynthesis") {
                GlossaryText("In plain terms: how your body makes vitamin D, switches it on, and puts it to work.\n\nVitamin D is a [secosteroid](glossary://secosteroid) — a steroid hormone with one ring cut open. What follows is its whole journey: from the raw carbon in your food, through the flash of UVB that creates it in your skin, to the two organs that activate it and the genes it finally controls.\n\nUnderlined words open a plain-language definition — tap any you don't know. There's a full glossary at the bottom too.")
            }

            ForEach(SciStage.all) { stage in
                StageCard(icon: stage.icon, title: stage.title,
                          molecule: stage.molecule, body: stage.body, aside: stage.aside)
            }

            photoequilibriumCard
            isomerisationCard
            halfLifeCard
            metaboliteTable
            enzymeTable

            InfoCard(icon: "arrow.left.arrow.right", title: "Why oral D3 is not equivalent") {
                LifeText("Swallowed D3 enters late in the pathway, bypassing everything before it. The differences are not merely academic.")
            }
            ForEach(SciContrast.all) { c in
                ContrastCard(icon: c.icon, title: c.title, body: c.body)
            }

            glossaryCard
            referencesCard
        }
    }

    // MARK: Photoequilibrium chart

    private struct PhotoPoint: Identifiable {
        let id = UUID()
        let dose: Double
        let species: String
        let percent: Double
    }

    private var photoData: [PhotoPoint] {
        var out: [PhotoPoint] = []
        var m: Double = 0
        while m <= 2.0 + 1e-9 {
            // Previtamin D3 rises to its ~15% ceiling, then eases back as it is
            // drawn off into the photoproducts. Lumisterol3 and tachysterol3 stay
            // near zero until the ceiling is approached (~0.55 MED), then climb —
            // lumisterol3 becoming the dominant product.
            let pre: Double = 17.5 * (1.0 - exp(-5.0 * m)) * exp(-0.20 * m)
            let onset: Double = max(0.0, m - 0.55)
            let lumi: Double = 38.0 * (1.0 - exp(-1.6 * onset))
            let tachy: Double = 14.0 * (1.0 - exp(-1.9 * onset))
            out.append(PhotoPoint(dose: m, species: "previtamin D3", percent: pre))
            out.append(PhotoPoint(dose: m, species: "tachysterol3", percent: tachy))
            out.append(PhotoPoint(dose: m, species: "lumisterol3", percent: lumi))
            m += 0.05
        }
        return out
    }

    private var photoColors: KeyValuePairs<String, Color> {
        [
            "previtamin D3": Color(hex: "f5c842"),   // gold — the one that becomes vitamin D
            "lumisterol3": Color(hex: "e0619b"),     // rose
            "tachysterol3": Color(hex: "56c4d6")     // cyan
        ]
    }

    private var photoequilibriumCard: some View {
        InfoCard(icon: "chart.xyaxis.line", title: "Photoequilibrium") {
            VStack(alignment: .leading, spacing: 10) {
                LifeText("Previtamin D3 rises to a ceiling of roughly 10–15% of available 7-DHC. Only once it nears that ceiling does continued UVB start diverting into lumisterol3 and tachysterol3 — and as they build, previtamin D3 eases back down. Lumisterol3 becomes the dominant product.")

                Chart(photoData) { p in
                    LineMark(x: .value("Dose", p.dose),
                             y: .value("% of 7-DHC", p.percent))
                        .foregroundStyle(by: .value("Species", p.species))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                    RuleMark(y: .value("Ceiling", 15))
                        .foregroundStyle(.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("~15% ceiling")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                }
                .chartForegroundStyleScale(photoColors)
                .chartLegend(position: .bottom, spacing: 8)
                .chartXScale(domain: 0...2)
                .chartXAxisLabel("Sun exposure (MED) →", alignment: .center)
                .chartYAxisLabel("% of initial 7-DHC")
                .chartXAxis {
                    AxisMarks(values: [0.0, 0.5, 1.0, 1.5, 2.0]) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.15))
                        AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                    }
                }
                .chartYAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .frame(height: 200)

                LifeText("Schematic, drawn to the behaviour in Holick 1981 — exact proportions vary with wavelength, temperature and skin type. The ceiling on previtamin D3 is the point: it is why sunlight cannot cause vitamin D toxicity.", size: 12)
            }
        }
    }

    // MARK: Isomerisation chart

    private struct IsoPoint: Identifiable {
        let id = UUID()
        let hours: Double
        let medium: String
        let converted: Double
    }

    private var isoData: [IsoPoint] {
        var out: [IsoPoint] = []
        let ln2: Double = 0.6931471805599453
        var h: Double = 0
        while h <= 72 {
            let skin: Double = 100.0 * (1.0 - exp(-ln2 * h / 8.0))
            let soln: Double = 100.0 * (1.0 - exp(-ln2 * h / 80.0))
            out.append(IsoPoint(hours: h, medium: "in skin (membrane)", converted: skin))
            out.append(IsoPoint(hours: h, medium: "in solution", converted: soln))
            h += 1
        }
        return out
    }

    private var isomerisationCard: some View {
        InfoCard(icon: "thermometer.medium", title: "Thermal isomerisation") {
            VStack(alignment: .leading, spacing: 10) {
                LifeText("Previtamin D3 → vitamin D3 is driven by body temperature, not light. Because it happens inside the cell membrane, which holds the molecule in the reactive shape, it runs about ten times faster than in free solution.")

                Chart(isoData) { p in
                    LineMark(x: .value("Hours", p.hours),
                             y: .value("% converted", p.converted))
                        .foregroundStyle(by: .value("Medium", p.medium))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                .chartForegroundStyleScale([
                    "in skin (membrane)": Color(hex: "f5c842"),
                    "in solution": Color.white.opacity(0.75)
                ])
                .chartLegend(position: .bottom, spacing: 8)
                .chartXAxisLabel("Hours after exposure", alignment: .center)
                .chartYAxisLabel("% converted to D3")
                .chartXAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .chartYAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .frame(height: 180)

                LifeText("Illustrative rates. The consequence is real: cutaneous vitamin D3 keeps appearing for a day or more after you leave the sun.", size: 12)
            }
        }
    }

    // MARK: Half-life chart

    private struct DecayPoint: Identifiable {
        let id = UUID()
        let hours: Double
        let species: String
        let remaining: Double
    }

    private var decayData: [DecayPoint] {
        var out: [DecayPoint] = []
        let species: [(String, Double)] = [
            ("calcitriol (active)", 12.0),
            ("vitamin D3", 24.0),
            ("25(OH)D (store)", 480.0)
        ]
        for (name, halfLife) in species {
            var t: Double = 1
            while t <= 1200 {
                let rem: Double = 100.0 * pow(0.5, t / halfLife)
                out.append(DecayPoint(hours: t, species: name, remaining: rem))
                t *= 1.14
            }
        }
        return out
    }

    private func hourLabel(_ h: Double) -> String {
        switch h {
        case ..<1.5: return "1h"
        case ..<7:   return "6h"
        case ..<36:  return "1d"
        case ..<200: return "1wk"
        default:     return "6wk"
        }
    }

    private var halfLifeCard: some View {
        InfoCard(icon: "hourglass", title: "How long each form lasts") {
            VStack(alignment: .leading, spacing: 10) {
                LifeText("The three circulating forms clear at wildly different rates. Each curve shows how much of a single dose remains over time — note the time axis is logarithmic, so each big step is roughly ten times longer than the last.")

                Chart(decayData) { p in
                    LineMark(x: .value("Time", p.hours),
                             y: .value("% left", p.remaining))
                        .foregroundStyle(by: .value("Form", p.species))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    RuleMark(y: .value("Half", 50))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("one half-life")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.75))
                        }
                }
                .chartForegroundStyleScale([
                    "calcitriol (active)": Color(hex: "56c4d6"),
                    "vitamin D3": Color(hex: "f5c842"),
                    "25(OH)D (store)": Color(hex: "e0619b")
                ])
                .chartLegend(position: .bottom, spacing: 8)
                .chartXScale(type: .log)
                .chartXAxis {
                    AxisMarks(values: [1.0, 6.0, 24.0, 168.0, 1008.0]) { v in
                        AxisGridLine().foregroundStyle(.white.opacity(0.15))
                        AxisValueLabel {
                            if let h = v.as(Double.self) {
                                Text(hourLabel(h))
                            }
                        }
                        .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .chartYAxisLabel("% of dose remaining")
                .chartYAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .frame(height: 190)

                LifeText("The active hormone (calcitriol) is gone within a day, so the body retunes it hour to hour. The storage form (25(OH)D) has a ~3-week half-life, which is why a blood test reflects months of habit — and why the history screen's trend line weights past days by that same decay.", size: 12)
            }
        }
    }

    // MARK: Tables

    private var metaboliteTable: some View {
        InfoCard(icon: "tablecells", title: "The metabolites") {
            VStack(alignment: .leading, spacing: 8) {
                LifeSpecRow(label: "Vitamin D3", value: "~24 h",
                            note: "Cholecalciferol · from skin or diet · the transported form")
                Divider().overlay(Color.white.opacity(0.2))
                LifeSpecRow(label: "25(OH)D", value: "2–3 weeks",
                            note: "Calcifediol · liver · storage form, and what a blood test measures")
                Divider().overlay(Color.white.opacity(0.2))
                LifeSpecRow(label: "1,25(OH)₂D", value: "4–15 h",
                            note: "Calcitriol · kidney and local tissues · the active hormone")
                Divider().overlay(Color.white.opacity(0.2))
                LifeSpecRow(label: "24,25(OH)₂D", value: "—",
                            note: "Inactivation route → calcitroic acid → biliary excretion")
                Divider().overlay(Color.white.opacity(0.2))
                LifeSpecRow(label: "20S(OH)L3 · 25(OH)T3", value: "—",
                            note: "CYP11A1 photoproduct metabolites · skin · detected in epidermis and serum")

                LifeText("The half-life spread is why the storage form responds to habits over months while the active hormone can be retuned within a day.", size: 12)
                    .padding(.top, 2)
            }
        }
    }

    private var enzymeTable: some View {
        InfoCard(icon: "gearshape.2.fill", title: "The enzymes") {
            VStack(alignment: .leading, spacing: 8) {
                LifeSpecRow(label: "DHCR7", value: "skin, ubiquitous",
                            note: "7-DHC → cholesterol. The branch point; degraded when cholesterol is abundant, leaving more 7-DHC for vitamin D.")
                Divider().overlay(Color.white.opacity(0.2))
                LifeSpecRow(label: "CYP11A1", value: "skin",
                            note: "Hydroxylates lumisterol3 and tachysterol3 into bioactive metabolites. Also the first step of all steroidogenesis.")
                Divider().overlay(Color.white.opacity(0.2))
                LifeSpecRow(label: "CYP2R1", value: "liver",
                            note: "D3 → 25(OH)D. The principal 25-hydroxylase; largely substrate-driven.")
                Divider().overlay(Color.white.opacity(0.2))
                LifeSpecRow(label: "CYP27B1", value: "kidney, immune cells",
                            note: "25(OH)D → 1,25(OH)₂D. Tightly regulated by PTH, calcium, phosphate and FGF23.")
                Divider().overlay(Color.white.opacity(0.2))
                LifeSpecRow(label: "CYP24A1", value: "kidney",
                            note: "Inactivation. Induced by calcitriol itself — a negative feedback loop.")
            }
        }
    }

    // MARK: Glossary

    private var glossaryCard: some View {
        InfoCard(icon: "character.book.closed.fill", title: "Glossary") {
            VStack(alignment: .leading, spacing: 8) {
                LifeText("Tap a term to expand. Highlighted words elsewhere open these too.", size: 12)
                    .foregroundColor(.white.opacity(0.7))
                ForEach(Array(Glossary.all.enumerated()), id: \.element.id) { i, e in
                    GlossaryRow(term: e.term, definition: e.definition)
                    if i < Glossary.all.count - 1 {
                        Divider().overlay(Color.white.opacity(0.15))
                    }
                }
            }
        }
    }

    // MARK: References

    private var referencesCard: some View {
        InfoCard(icon: "book.fill", title: "Sources") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(SciReference.all) { ref in
                    if let url = URL(string: ref.url) {
                        Link(destination: url) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 4) {
                                    Text(ref.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .underline()
                                        .multilineTextAlignment(.leading)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                Text(ref.note)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.75))
                                    .lineSpacing(2)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
}

/// An expandable glossary term.
private struct GlossaryRow: View {
    let term: String
    let definition: String
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { open.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Text(term)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Image(systemName: open ? "minus.circle" : "plus.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "f5c842"))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if open {
                Text(definition)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Science content data

private struct SciStage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let molecule: String?
    let body: String
    var aside: String? = nil

    static let all: [SciStage] = [
        SciStage(icon: "atom",
                 title: "Carbon arrives as acetyl-CoA",
                 molecule: "acetyl-CoA → sterol",
                 body: "Every carbon atom in vitamin D starts on your plate. Sugars, fats and proteins from food are broken down inside your cells into [acetyl-CoA](glossary://acetyl-coa) — a tiny two-carbon unit that is metabolism's universal building block. Trace those carbons back one more step and they were carbon dioxide in the air, pulled into plants by photosynthesis before you ate them.\n\nInside the cell, about eighteen acetyl-CoA units are welded together, step by step, into one 27-carbon [sterol](glossary://sterol) — along the [mevalonate pathway](glossary://mevalonate), via squalene and lanosterol.",
                 aside: "The rate-limiting enzyme of this pathway, HMG-CoA reductase, is the target of statin drugs."),
        SciStage(icon: "arrow.branch",
                 title: "Vitamin D branches before cholesterol",
                 molecule: "7-DHC → cholesterol (DHCR7)",
                 body: "The pathway terminates when [DHCR7](glossary://dhcr7) converts [7-dehydrocholesterol](glossary://7-dhc) into cholesterol. Vitamin D forks off one step earlier, from 7-DHC itself — so it is made from cholesterol's immediate precursor, not from cholesterol.\n\nThe reaction runs one way only, so [dietary cholesterol](glossary://dietary-cholesterol) can't be turned back into 7-DHC.",
                 aside: "The branch even self-regulates. Remember DHCR7 is the enzyme that spends 7-DHC by turning it into cholesterol. So when a cell already has plenty of cholesterol, it destroys some of its DHCR7 — and with fewer of those enzymes at work, less 7-DHC gets used up, leaving more sitting in the skin for sunlight."),
        SciStage(icon: "square.stack.3d.up.fill",
                 title: "The cutaneous 7-DHC pool",
                 molecule: "7-dehydrocholesterol",
                 body: "Here's the piece that trips people up. All of the above happens inside cells — and your outer skin (the epidermis) has no blood vessels running through it at all. So how does it get raw materials? By diffusion: small nutrients seep upward from the blood-rich layer just below (the dermis) into the skin cells above.\n\nFrom those nutrients, the skin cells build their own [sterols](glossary://sterol) on the spot — including the 7-DHC pool — rather than importing finished cholesterol from the blood. So the stockpile sunlight works on is manufactured locally, right where the light lands. It's most concentrated in the living layers just below the surface, and it thins with age — a large part of why older skin makes less vitamin D."),
        SciStage(icon: "sun.max.fill",
                 title: "UVB opens the B-ring",
                 molecule: "previtamin D3",
                 body: "Photons at 295–300 nm carry the precise energy to break one bond in the 7-DHC ring system, opening it to form the [secosteroid](glossary://secosteroid) [previtamin D3](glossary://previtamin-d3).\n\nNo enzyme performs this step. It is pure photochemistry, and it is the only reason sunlight is required.",
                 aside: "This [action spectrum](glossary://action-spectrum) sits at shorter wavelengths than the one for sunburn — which is why burning is a poor proxy for vitamin D, and why this app weights dose by how high the sun sits."),
        SciStage(icon: "arrow.triangle.branch",
                 title: "The ceiling: photoequilibrium",
                 molecule: "lumisterol3 · tachysterol3",
                 body: "Under continued sunlight, previtamin D3 stops piling up. It reaches a balance — a [photoequilibrium](glossary://photoequilibrium) — where every new molecule made is matched by one converted away into [lumisterol3 and tachysterol3](glossary://photoproducts).\n\nThat balance sits at only about 10–15% conversion. In other words: of all the 7-DHC in your skin, no more than roughly one molecule in seven is ever previtamin D3 at any one moment — the rest stays as 7-DHC or is parked in the overflow products. This hard ceiling is exactly why sunlight can't give you a toxic dose of vitamin D, only a sunburn. And it's reversible: as previtamin D3 is drawn off (next step), the overflow can flow back."),
        SciStage(icon: "thermometer.medium",
                 title: "Body heat finishes the job",
                 molecule: "vitamin D3 (cholecalciferol)",
                 body: "The previtamin D3 that isn't diverted slowly turns into [vitamin D3](glossary://cholecalciferol) proper — an [isomerisation](glossary://isomerisation) powered by your body heat, not light.\n\nPrevitamin D3 is a floppy molecule, constantly twisting between shapes, and only one of those shapes can flip into vitamin D3. Packed into the crowded, orderly interior of a cell membrane, it's held in that productive shape much more of the time — so the conversion runs about ten times faster than it would loose in a fluid. Because it's heat-driven and unhurried, your skin keeps releasing fresh vitamin D3 for a day or more after you've come inside."),
        SciStage(icon: "wand.and.stars",
                 title: "The photoproducts are not inert",
                 molecule: "hydroxy-lumisterol · hydroxy-tachysterol",
                 body: "Long assumed to be dead ends, lumisterol3 and tachysterol3 are converted by the enzyme [CYP11A1](glossary://cyp) into families of active metabolites, detected in human skin and blood, with antioxidant, DNA-protective and anti-inflammatory activity.",
                 aside: "These arise only from photochemistry. No oral preparation delivers them."),
        SciStage(icon: "drop.fill",
                 title: "Transport to the liver",
                 molecule: "D3 · binding protein",
                 body: "Vitamin D3 leaves the skin bound to [vitamin D binding protein](glossary://dbp) and travels to the liver. Because it seeps out gradually, sunlight delivers a slow, sustained release over days rather than a spike."),
        SciStage(icon: "cross.case.fill",
                 title: "Hepatic 25-hydroxylation",
                 molecule: "25(OH)D — calcifediol",
                 body: "In the liver, CYP2R1 adds a [hydroxyl group](glossary://hydroxylation) to make [25-hydroxyvitamin D](glossary://25ohd) — the storage and transport form, with a [half-life](glossary://half-life) of two to three weeks, and the molecule a blood test measures.\n\nThis step is largely substrate-driven, so intake and sun exposure translate fairly directly into the level in your blood."),
        SciStage(icon: "bolt.fill",
                 title: "Renal activation",
                 molecule: "1,25(OH)₂D — calcitriol",
                 body: "The kidney, via CYP27B1, adds a second hydroxyl to make [calcitriol](glossary://calcitriol), the genuinely active hormone. Unlike the liver step, this one is tightly governed — raised by [parathyroid hormone, restrained by FGF23](glossary://pth-fgf23) and by calcitriol itself.",
                 aside: "Immune cells, skin and other tissues run this step locally too, making calcitriol for their own use rather than for the bloodstream."),
        SciStage(icon: "dna",
                 title: "Gene regulation",
                 molecule: "VDR · RXR",
                 body: "Calcitriol binds the [vitamin D receptor, which pairs with the retinoid X receptor](glossary://vdr) and settles onto specific stretches of DNA, turning genes up or down — across calcium absorption, bone remodelling, immunity and cell growth.\n\nIt is a signal, not a fuel: it issues instructions rather than being consumed."),
        SciStage(icon: "arrow.uturn.down",
                 title: "Self-limiting breakdown",
                 molecule: "CYP24A1 → calcitroic acid",
                 body: "Calcitriol switches on CYP24A1, the enzyme that dismantles it, breaking both the active and storage forms down to calcitroic acid for excretion.\n\nThe hormone triggers its own removal, keeping the signal brief and self-correcting.")
    ]
}

private struct SciContrast: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String

    static let all: [SciContrast] = [
        SciContrast(icon: "shield.lefthalf.filled",
                    title: "A ceiling vs no limit",
                    body: "The photostationary state caps how much the skin can make, however long you stay out. Oral intake has no such limit — which is why too much vitamin D is possible from capsules but not from sun."),
        SciContrast(icon: "chart.line.flattrend.xyaxis",
                    title: "Different delivery",
                    body: "Skin releases vitamin D bound to its carrier protein over days. An oral dose is absorbed as a bolus, with a substantial share diverted into fat. Intermittent high-dose regimens diverge further still from any natural pattern."),
        SciContrast(icon: "wand.and.stars",
                    title: "Co-produced metabolites",
                    body: "Light also generates the lumisterol and tachysterol metabolites, with their own biological activity. A capsule delivers one molecule of the several sunlight makes."),
        SciContrast(icon: "heart.fill",
                    title: "Effects beyond vitamin D",
                    body: "UVA — which makes no vitamin D — releases nitric oxide stored in the skin, lowering blood pressure in controlled trials, independently of vitamin D status."),
        SciContrast(icon: "questionmark.circle.fill",
                    title: "The evidence gap",
                    body: "Studies link high vitamin D to lower rates of heart disease, diabetes, cancer and early death — yet randomised supplement trials mostly fail to reproduce those benefits.\n\nThe favoured reading is that low vitamin D substantially reflects ill health and little sun rather than causing the outcomes, in which case topping up the reading was never going to reproduce the sunshine.")
    ]
}

private struct SciReference: Identifiable {
    let id = UUID()
    let title: String
    let note: String
    let url: String

    static let all: [SciReference] = [
        SciReference(title: "Prabhu AV et al., J Biol Chem — cholesterol-mediated degradation of DHCR7",
                     note: "DHCR7 makes cholesterol from 7-DHC; cholesterol accelerates its breakdown, raising 7-DHC and vitamin D synthesis. The branch point.",
                     url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4861412/"),
        SciReference(title: "Zerenturk EJ et al. — DHCR7: a vital enzyme switch",
                     note: "Review of DHCR7 governing the cholesterol / vitamin D split.",
                     url: "https://www.sciencedirect.com/science/article/abs/pii/S0163782716300340"),
        SciReference(title: "Origin of 7-dehydrocholesterol (provitamin D) in the skin",
                     note: "Cutaneous origin of the 7-DHC pool.",
                     url: "https://www.jidonline.org/article/S0022-202X(15)34937-X/fulltext"),
        SciReference(title: "MacLaughlin JA, Anderson RR, Holick MF (1982), Science 216:1001–3",
                     note: "Action spectrum for previtamin D3 photosynthesis; optimum 295–300 nm.",
                     url: "https://www.science.org/doi/10.1126/science.6281884"),
        SciReference(title: "Tian XQ & Holick MF — membrane-enhanced thermal isomerisation",
                     note: "Liposomal model: previtamin D3 → D3 runs ~10× faster in membranes than in solution.",
                     url: "https://www.sciencedirect.com/science/article/pii/S002192581987895X"),
        SciReference(title: "Holick MF et al. (1981), Science 211:590–3",
                     note: "Photoequilibrium: previtamin D3 plateaus at ~10–15% conversion, partitioning into lumisterol3 and tachysterol3.",
                     url: "https://www.science.org/doi/10.1126/science.6256855"),
        SciReference(title: "Slominski AT et al. — CYP11A1-derived vitamin D and lumisterol metabolites",
                     note: "Photoproducts converted to active metabolites acting on VDR, AhR, LXR and PPARγ; found in human skin and serum.",
                     url: "https://www.sciencedirect.com/science/article/pii/S0022202X24003865"),
        SciReference(title: "Liu D, Weller RB et al. (2014), J Invest Dermatol",
                     note: "UVA lowers blood pressure independently of vitamin D, via cutaneous nitric oxide stores.",
                     url: "https://pubmed.ncbi.nlm.nih.gov/24445737/"),
        SciReference(title: "Autier P et al. (2014), Lancet Diabetes Endocrinol 2:76–89",
                     note: "The observational–interventional gap; argues low 25(OH)D substantially indexes ill health.",
                     url: "https://www.thelancet.com/journals/landia/article/PIIS2213-8587(13)70165-7/abstract"),
        SciReference(title: "Young AR et al. (2021), PNAS 118(40)",
                     note: "In vivo action spectrum revision; sunburn-weighted dose poorly predicts synthesis. Underpins this app's elevation weighting.",
                     url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8501902/")
    ]
}
