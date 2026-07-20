import SwiftUI
import Charts

/// Easter egg: tapping the SUNniDAY wordmark opens the full life cycle of
/// vitamin D, at two depths — a plain-language walkthrough, and a deep dive
/// with the enzymes, charts, tables and papers.
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
                    VStack(alignment: .leading, spacing: 0) {
                        Picker("Depth", selection: $showsScience) {
                            Text("The Basics").tag(false)
                            Text("The Science").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 20)

                        if showsScience {
                            LifecycleScience()
                        } else {
                            LifecycleBasics()
                        }

                        Text("Written for curiosity, not clinical use. Vitamin D supplements are genuinely valuable — especially in winter, at high latitude, for darker skin, and for anyone mostly indoors. Talk to a doctor about your own levels.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                            .padding(.horizontal, 8)
                    }
                    .padding(20)
                }
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

private struct LifeHeading: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(.white)
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

/// A numbered step with a connector line down the left.
private struct StepRow<Content: View>: View {
    let number: Int
    let icon: String
    let title: String
    let isLast: Bool
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 34, height: 34)
                    Text("\(number)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "f5c842"))
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
            .padding(.bottom, isLast ? 0 : 26)
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
            Text(text)
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.88))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .background(Color.white.opacity(0.13))
        .cornerRadius(10)
    }
}

// MARK: - The Basics

private struct LifecycleBasics: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("A molecule's journey")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                LifeText("Vitamin D isn't a vitamin at all — it's a hormone, and one of the few your body can't finish building without help from the sky. Here's the whole trip, in plain language.", size: 15)
            }
            .padding(.bottom, 24)

            ForEach(Array(BasicStep.all.enumerated()), id: \.element.id) { i, step in
                StepRow(number: i + 1,
                        icon: step.icon,
                        title: step.title,
                        isLast: i == BasicStep.all.count - 1) {
                    LifeText(step.body)
                    if let aside = step.aside { Aside(aside) }
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                LifeHeading("So why not just take a pill?")
                    .padding(.top, 16)

                LifeText("Supplements work — they reliably raise your levels, and they matter for anyone who can't get sun. But swallowing vitamin D joins this story near the end, and skipping the first half turns out to matter.")

                ForEach(BasicContrast.all) { c in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Image(systemName: c.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(c.title)
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        LifeText(c.body, size: 13.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.16))
                    .cornerRadius(14)
                }

                LifeText("The short version: sunlight and vitamin D aren't the same thing. A capsule carries part of the parcel, not all of it.")
                    .padding(.top, 2)
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
                  body: "You'll often hear that sunlight turns cholesterol into vitamin D. It's actually made from the molecule your body uses one step *before* cholesterol — a not-quite-finished version your skin keeps a supply of.",
                  aside: "Which means cholesterol from food can't be turned into vitamin D. The step only runs one way."),
        BasicStep(icon: "square.stack.3d.up.fill",
                  title: "Your skin keeps a supply ready",
                  body: "Your skin has no blood supply of its own in its outer layers, so it makes its own building materials. It holds a standing pool of that precursor in the living layers just beneath the surface — a light-sensitive stockpile, kept in the one organ that meets the sun."),
        BasicStep(icon: "sun.max.fill",
                  title: "Sunlight does the one thing you can't",
                  body: "A particular slice of UVB light carries exactly the right energy to snap one bond in that molecule's ring, springing it open. That open ring is the whole point — it lets the molecule fold into a shape your body can read.",
                  aside: "No enzyme in your body can do this step. The energy has to arrive as light. This is the only reason sunshine matters here at all."),
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
                      body: "Those extra molecules from step 5 come only from light, and they have their own protective roles. A vitamin D capsule contains exactly one of the things sunshine makes."),
        BasicContrast(icon: "heart.fill",
                      title: "And light does jobs vitamin D doesn't",
                      body: "Sunlight also releases a compound stored in your skin that relaxes blood vessels and lowers blood pressure — an effect shown to work independently of vitamin D entirely. Add sleep timing and mood, and \"go outside\" is doing several things at once."),
        BasicContrast(icon: "questionmark.circle.fill",
                      title: "The uncomfortable evidence",
                      body: "People with low vitamin D get more heart disease, diabetes and cancer. Yet big trials handing out supplements mostly failed to prevent any of it.\n\nThe leading explanation: low vitamin D may often be a *sign* of poor health and little time outdoors rather than the cause of it. If so, topping up the reading was never going to deliver what the sunshine was doing.")
    ]
}

// MARK: - The Science

private struct LifecycleScience: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            stages
            charts
            tables
            secondOrderSection
            referencesSection
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Secosteroid biosynthesis")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            LifeText("The full route, with the enzymes, kinetics and regulation — from the sterol pathway branch point through to CYP24A1-mediated clearance.", size: 15)
        }
        .padding(.bottom, 24)
    }

    private var stages: some View {
        ForEach(Array(SciStage.all.enumerated()), id: \.element.id) { i, stage in
            StepRow(number: i + 1,
                    icon: stage.icon,
                    title: stage.title,
                    isLast: i == SciStage.all.count - 1) {
                if let m = stage.molecule { MoleculeChip(text: m) }
                LifeText(stage.body)
                if let aside = stage.aside { Aside(aside) }
            }
        }
    }

    private var charts: some View {
        VStack(alignment: .leading, spacing: 0) {
            photoequilibriumCard
            isomerisationCard
        }
    }

    private var tables: some View {
        VStack(alignment: .leading, spacing: 0) {
            metaboliteTable
            enzymeTable
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
        var d: Double = 0
        while d <= 10 {
            let pre: Double = 12.0 * (1.0 - exp(-0.8 * d)) * exp(-0.05 * d)
            let lumi: Double = 55.0 * (1.0 - exp(-0.25 * d))
            let tachy: Double = 12.0 * (1.0 - exp(-0.5 * d)) * exp(-0.03 * d)
            out.append(PhotoPoint(dose: d, species: "previtamin D3", percent: pre))
            out.append(PhotoPoint(dose: d, species: "lumisterol3", percent: lumi))
            out.append(PhotoPoint(dose: d, species: "tachysterol3", percent: tachy))
            d += 0.2
        }
        return out
    }

    private var photoequilibriumCard: some View {
        InfoCard(icon: "chart.xyaxis.line", title: "Photoequilibrium") {
            VStack(alignment: .leading, spacing: 10) {
                LifeText("Previtamin D3 does not accumulate indefinitely. It reaches a photostationary state at roughly 10–15% of available 7-DHC, after which continued UVB partitions into lumisterol3 and tachysterol3 instead.")

                Chart(photoData) { p in
                    LineMark(x: .value("Dose", p.dose),
                             y: .value("% of 7-DHC", p.percent))
                        .foregroundStyle(by: .value("Species", p.species))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    RuleMark(y: .value("Ceiling", 15))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("previtamin D3 ceiling ≈ 10–15%")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                }
                .chartForegroundStyleScale([
                    "previtamin D3": Color(hex: "f5c842"),
                    "lumisterol3": Color.white,
                    "tachysterol3": Color(hex: "9ad6f5")
                ])
                .chartLegend(position: .bottom, spacing: 8)
                .chartXAxisLabel("Cumulative UVB dose →", alignment: .center)
                .chartYAxisLabel("% of initial 7-DHC")
                .chartXAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                } }
                .chartYAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.8))
                } }
                .frame(height: 190)

                LifeText("Schematic, drawn to the behaviour described in Holick 1981 — exact proportions vary with wavelength, temperature and skin type. The ceiling is the point: it is the reason sunlight cannot produce vitamin D toxicity.", size: 12)
            }
        }
        .padding(.top, 8)
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
                LifeText("Previtamin D3 → vitamin D3 is driven by body temperature, not light, via a [1,7]-hydrogen shift. Crucially it happens inside the phospholipid bilayer, which stabilises the reactive conformer and accelerates the reaction roughly tenfold over free solution.")

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

                LifeText("Illustrative rates. The consequence is real though: cutaneous vitamin D3 keeps appearing for a day or more after you leave the sun.", size: 12)
            }
        }
        .padding(.top, 16)
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
        .padding(.top, 16)
    }

    private var enzymeTable: some View {
        InfoCard(icon: "gearshape.2.fill", title: "The enzymes") {
            VStack(alignment: .leading, spacing: 8) {
                LifeSpecRow(label: "DHCR7", value: "skin, ubiquitous",
                            note: "7-DHC → cholesterol. The branch point. Degraded when cholesterol is abundant, leaving more 7-DHC for vitamin D.")
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
        .padding(.top, 16)
    }

    // MARK: Second order

    private var secondOrderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LifeHeading("Why oral D3 is not equivalent")
                .padding(.top, 26)

            LifeText("Swallowed D3 enters at stage 7, bypassing everything before it. The differences are not merely academic.")

            ForEach(SciContrast.all) { c in
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Image(systemName: c.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(c.title)
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    LifeText(c.body, size: 13.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.white.opacity(0.16))
                .cornerRadius(14)
            }

            LifeText("None of which argues against supplementation — it raises 25(OH)D reliably and matters for anyone who cannot get sun. But \"sunlight\" and \"vitamin D\" are not interchangeable terms.")
                .padding(.top, 2)
        }
    }

    // MARK: References

    private var referencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LifeHeading("Sources")
                .padding(.top, 26)

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

// MARK: - Science content

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
                 molecule: "acetyl-CoA (×18 per sterol)",
                 body: "Carbohydrate, fat and protein all converge on the same two-carbon unit. It's generated in mitochondria and exported to the cytosol via the citrate shuttle, where ATP-citrate lyase regenerates it for biosynthesis.\n\nEighteen of them are condensed into one C27 sterol: 3 acetyl-CoA → HMG-CoA → mevalonate, six mevalonate → squalene (C30) → lanosterol, then trimmed.",
                 aside: "HMG-CoA reductase is the rate-limiting step — and the statin target. In theory statins should suppress 7-DHC and therefore vitamin D. In practice that has never been convincingly demonstrated, and some trials report 25(OH)D rising. Still unexplained."),
        SciStage(icon: "arrow.branch",
                 title: "Vitamin D branches before cholesterol",
                 molecule: "7-DHC → cholesterol (DHCR7)",
                 body: "The Kandutsch–Russell pathway terminates when DHCR7 reduces the C7–8 double bond of 7-dehydrocholesterol to yield cholesterol. Vitamin D forks off one step earlier, from 7-DHC itself.\n\nThe reaction is not reversible, so circulating or dietary cholesterol cannot re-enter as 7-DHC. \"Sunlight converts cholesterol to vitamin D\" is, strictly, wrong.",
                 aside: "The branch self-balances: cholesterol accelerates proteasomal degradation of DHCR7. In keratinocytes, added cholesterol cut DHCR7 activity by 55% and raised vitamin D synthesis by 50%."),
        SciStage(icon: "square.stack.3d.up.fill",
                 title: "The cutaneous 7-DHC pool",
                 molecule: "7-dehydrocholesterol",
                 body: "The epidermis is avascular and synthesises its own sterols in the nucleated layers, so the 7-DHC available to UVB is locally produced rather than delivered from the liver. Concentration is highest in the stratum basale and spinosum.\n\nThe pool declines with age, which accounts for much of the reduced synthetic capacity in older skin."),
        SciStage(icon: "sun.max.fill",
                 title: "UVB opens the B-ring",
                 molecule: "previtamin D3",
                 body: "Photons at 295–300 nm drive conrotatory ring opening of the 5,7-diene, cleaving the B-ring to give the 9,10-secosteroid previtamin D3.\n\nNo enzyme performs this step. It is photochemistry, and it is the sole reason sunlight is required at all.",
                 aside: "The action spectrum sits further into the UVB than the erythemal one — which is why sunburn is a poor proxy for vitamin D yield, and why this app weights dose by solar elevation."),
        SciStage(icon: "thermometer.medium",
                 title: "Membrane-enhanced thermal isomerisation",
                 molecule: "vitamin D3 (cholecalciferol)",
                 body: "Previtamin D3 undergoes a temperature-driven [1,7]-sigmatropic hydrogen shift to vitamin D3. Because it forms within the phospholipid bilayer, which stabilises the required helical conformer, the reaction proceeds roughly ten times faster than in isotropic solution.",
                 aside: "Consequence: cutaneous D3 continues to appear for a day or more after exposure ends. The sun starts the reaction; body heat completes it."),
        SciStage(icon: "arrow.triangle.branch",
                 title: "Photostationary state",
                 molecule: "lumisterol3 · tachysterol3",
                 body: "Continued irradiation drives previtamin D3 into lumisterol3 and tachysterol3 rather than accumulating further, plateauing near 10–15% conversion of available 7-DHC.\n\nThe partitioning is reversible: as previtamin D3 is drawn down by thermal isomerisation, the photoproducts can revert, functioning as a reservoir rather than a sink."),
        SciStage(icon: "wand.and.stars",
                 title: "The photoproducts are not inert",
                 molecule: "20S(OH)L3 · 20S(OH)T3 · 25(OH)T3",
                 body: "Long assumed to be dead ends, lumisterol3 and tachysterol3 are hydroxylated by CYP11A1 (and CYP27A1) into families of metabolites detected in human epidermis and serum.\n\nThey act on VDR, AhR, LXRα/β, RORα/γ and PPARγ, with reported antioxidant, DNA-protective, anti-inflammatory and pro-differentiation activity.",
                 aside: "These arise only from photochemistry. No oral preparation delivers them."),
        SciStage(icon: "drop.fill",
                 title: "DBP-mediated transport",
                 molecule: "D3 · vitamin D binding protein",
                 body: "Cutaneous D3 partitions into the circulation bound to vitamin D binding protein, and does so gradually — a sustained release over days rather than a bolus."),
        SciStage(icon: "cross.case.fill",
                 title: "Hepatic 25-hydroxylation",
                 molecule: "25(OH)D — calcifediol",
                 body: "CYP2R1 (with CYP27A1 contributing) hydroxylates D3 at C25. The product is the storage and transport form, half-life two to three weeks, and the analyte reported by clinical vitamin D testing.\n\nThis step is largely substrate-driven rather than tightly regulated — which is why intake and sun exposure translate fairly directly into 25(OH)D."),
        SciStage(icon: "bolt.fill",
                 title: "Renal 1α-hydroxylation",
                 molecule: "1,25(OH)₂D — calcitriol",
                 body: "CYP27B1 adds the 1α-hydroxyl to produce the active hormone. Unlike the hepatic step this one is closely governed — upregulated by PTH and hypophosphataemia, suppressed by FGF23 and by calcitriol itself.",
                 aside: "Extrarenal CYP27B1 in immune cells, keratinocytes, placenta and elsewhere generates calcitriol for local autocrine and paracrine use, independent of the circulating pool."),
        SciStage(icon: "dna",
                 title: "VDR–RXR transcriptional regulation",
                 molecule: "VDR · RXR · VDRE",
                 body: "Calcitriol binds the vitamin D receptor, which heterodimerises with the retinoid X receptor and occupies vitamin D response elements across the genome, recruiting coactivators or corepressors.\n\nTargets span intestinal calcium absorption, bone remodelling, innate and adaptive immunity, and cell-cycle control. It is a transcription factor ligand, not a substrate."),
        SciStage(icon: "arrow.uturn.down",
                 title: "CYP24A1 catabolism",
                 molecule: "→ calcitroic acid",
                 body: "Calcitriol induces CYP24A1, which initiates C24 oxidation of both 25(OH)D and 1,25(OH)₂D, terminating in calcitroic acid and biliary excretion.\n\nThe hormone induces its own catabolism — the loop that keeps the signal transient and self-limiting.")
    ]
}

private struct SciContrast: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String

    static let all: [SciContrast] = [
        SciContrast(icon: "shield.lefthalf.filled",
                    title: "Photochemical ceiling vs unbounded intake",
                    body: "The photostationary state caps cutaneous output regardless of exposure duration. Oral intake has no equivalent limit, which is why hypervitaminosis D is achievable orally and not by sun."),
        SciContrast(icon: "chart.line.flattrend.xyaxis",
                    title: "Divergent pharmacokinetics",
                    body: "Cutaneous D3 enters bound to DBP over days. Oral D3 is absorbed in chylomicrons as a bolus, with substantial partitioning into adipose tissue. Intermittent high-dose regimens depart further still from any physiological pattern."),
        SciContrast(icon: "wand.and.stars",
                    title: "Co-produced metabolites",
                    body: "Photochemistry yields the CYP11A1-derived lumisterol and tachysterol hydroxyderivatives alongside D3. A capsule delivers one molecule of the several sunlight generates."),
        SciContrast(icon: "heart.fill",
                    title: "Vitamin-D-independent effects of UV",
                    body: "UVA — which produces no vitamin D — mobilises cutaneous nitrite/nitrate stores as nitric oxide, causing vasodilation and measurably lowering blood pressure in controlled trials, independently of vitamin D status."),
        SciContrast(icon: "questionmark.circle.fill",
                    title: "The observational–interventional gap",
                    body: "Cohort data associate high 25(OH)D with substantially reduced cardiovascular, metabolic, oncological and all-cause mortality risk. Randomised supplementation has largely failed to reproduce these effects.\n\nThe favoured interpretation is that low 25(OH)D substantially indexes ill health, inflammation, adiposity and low sun exposure, rather than causing the outcomes — in which case correcting the biomarker was never going to reproduce the exposure.")
    ]
}

private struct SciReference: Identifiable {
    let id = UUID()
    let title: String
    let note: String
    let url: String

    static let all: [SciReference] = [
        SciReference(title: "Prabhu AV et al., J Biol Chem — cholesterol-mediated degradation of DHCR7",
                     note: "DHCR7 reduces the C7–8 double bond of 7-DHC to form cholesterol; cholesterol accelerates its proteasomal degradation, raising 7-DHC and vitamin D synthesis. Stages 2–3.",
                     url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4861412/"),
        SciReference(title: "Zerenturk EJ et al. — DHCR7: a vital enzyme switch",
                     note: "Review of DHCR7 governing the cholesterol/vitamin D split. Stage 2.",
                     url: "https://www.sciencedirect.com/science/article/abs/pii/S0163782716300340"),
        SciReference(title: "Origin of 7-dehydrocholesterol (provitamin D) in the skin",
                     note: "Cutaneous origin of the 7-DHC pool. Stage 3.",
                     url: "https://www.jidonline.org/article/S0022-202X(15)34937-X/fulltext"),
        SciReference(title: "MacLaughlin JA, Anderson RR, Holick MF (1982), Science 216:1001–3",
                     note: "Action spectrum for previtamin D3 photosynthesis; optimum 295–300 nm. Stage 4.",
                     url: "https://www.science.org/doi/10.1126/science.6281884"),
        SciReference(title: "Tian XQ & Holick MF — membrane-enhanced thermal isomerisation",
                     note: "Liposomal model showing previtamin D3 → D3 proceeds ~10× faster in phospholipid bilayers than in solution. Stage 5.",
                     url: "https://www.sciencedirect.com/science/article/pii/S002192581987895X"),
        SciReference(title: "Holick MF et al. (1981), Science 211:590–3",
                     note: "Photoequilibrium: previtamin D3 plateaus at ~10–15% conversion, partitioning into lumisterol3 and tachysterol3. Stage 6.",
                     url: "https://www.science.org/doi/10.1126/science.6256855"),
        SciReference(title: "Slominski AT et al. — CYP11A1-derived vitamin D and lumisterol metabolites",
                     note: "Photoproducts hydroxylated to bioactive metabolites acting on VDR, AhR, LXR and PPARγ; detected in human epidermis and serum. Stage 7.",
                     url: "https://www.sciencedirect.com/science/article/pii/S0022202X24003865"),
        SciReference(title: "Metabolic activation of tachysterol3 to hydroxyderivatives",
                     note: "Characterisation of 20S(OH)T3 and 25(OH)T3 and their receptor activity. Stage 7.",
                     url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC9345108/"),
        SciReference(title: "Liu D, Weller RB et al. (2014), J Invest Dermatol",
                     note: "UVA irradiation vasodilates and lowers blood pressure independently of vitamin D, via cutaneous nitric oxide stores.",
                     url: "https://pubmed.ncbi.nlm.nih.gov/24445737/"),
        SciReference(title: "Autier P et al. (2014), Lancet Diabetes Endocrinol 2:76–89",
                     note: "Systematic review of the observational–interventional discrepancy; argues low 25(OH)D substantially indexes ill health.",
                     url: "https://www.thelancet.com/journals/landia/article/PIIS2213-8587(13)70165-7/abstract"),
        SciReference(title: "Young AR et al. (2021), PNAS 118(40)",
                     note: "In vivo action spectrum revision; erythemally-weighted dose poorly predicts synthesis. Underpins this app's elevation weighting.",
                     url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8501902/")
    ]
}
