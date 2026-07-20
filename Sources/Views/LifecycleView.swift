import SwiftUI

/// Easter egg: tapping the SUNniDAY wordmark opens the full life cycle of
/// vitamin D, from cholesterol through to gene expression and breakdown.
struct LifecycleView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "6d7fc9"), Color(hex: "a9a3e0"), Color(hex: "f2b79c")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header

                        ForEach(Array(LifecycleStage.all.enumerated()), id: \.element.id) { index, stage in
                            StageRow(stage: stage,
                                     number: index + 1,
                                     isLast: index == LifecycleStage.all.count - 1)
                        }

                        supplementsSection
                        referencesSection

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

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A molecule's journey")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Vitamin D isn't a vitamin at all — it's a hormone, and one of the few your body can only finish building with help from the sky. Here is the whole route, from a molecule your own cells assemble to a switch sitting on your DNA.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 24)
    }

    // MARK: Supplements

    private var supplementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Why a capsule isn't the same")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 12)

            Text("Swallowing D3 joins the story at stage 6, skipping everything before it. That turns out to matter in ways that go beyond the number on a blood test.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(SecondOrderEffect.all) { effect in
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Image(systemName: effect.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(effect.title)
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    Text(effect.body)
                        .font(.system(size: 13.5))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.white.opacity(0.16))
                .cornerRadius(14)
            }

            Text("None of which means supplements don't work — they reliably raise 25(OH)D and they matter for people who can't get sun. But \"sunlight\" and \"vitamin D\" are not synonyms, and the capsule only carries part of the parcel.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    // MARK: References

    private var referencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sources")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 24)

            ForEach(LifecycleReference.all) { ref in
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

// MARK: - Stage row

private struct StageRow: View {
    let stage: LifecycleStage
    let number: Int
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Number badge + connector
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
                    Image(systemName: stage.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "f5c842"))
                    Text(stage.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }

                if let molecule = stage.molecule {
                    Text(molecule)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.18))
                        .cornerRadius(6)
                }

                Text(stage.body)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.92))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let aside = stage.aside {
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "f5c842"))
                        Text(aside)
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
            .padding(.bottom, isLast ? 0 : 26)
        }
    }
}

// MARK: - Content

private struct LifecycleStage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let molecule: String?
    let body: String
    var aside: String? = nil

    static let all: [LifecycleStage] = [
        LifecycleStage(
            icon: "arrow.branch",
            title: "Not from cholesterol — from one step before it",
            molecule: "acetyl-CoA → … → 7-DHC → cholesterol",
            body: "You'll often read that sunlight turns the cholesterol in your skin into vitamin D. That's backwards.\n\nYour cells build sterols from scratch, in a long chain that ends: 7-dehydrocholesterol, then cholesterol. An enzyme called DHCR7 catalyses that final step. Vitamin D branches off the chain one rung earlier — it's made from 7-DHC, cholesterol's immediate precursor.\n\nThe distinction matters, because the reaction only runs one way. Cholesterol already in your blood cannot be turned back into 7-DHC, so dietary cholesterol isn't feedstock for vitamin D.",
            aside: "Vitamin D is a steroid. It shares an ancestor with testosterone, oestrogen and cortisol — the difference is that this one needs a photon to finish."
        ),
        LifecycleStage(
            icon: "square.stack.3d.up.fill",
            title: "Your skin holds the branch point open",
            molecule: "7-dehydrocholesterol (7-DHC)",
            body: "The epidermis has no blood supply of its own, so it manufactures its own sterols — meaning the 7-DHC pool sitting in your skin was built there, in the living layers beneath the surface, rather than shipped in from the liver.\n\nHow much stays as 7-DHC comes down to DHCR7. Every molecule it converts becomes cholesterol; every molecule it leaves alone stays available to the sun.",
            aside: "It self-balances rather elegantly: when cholesterol is plentiful it accelerates DHCR7's own destruction, so 7-DHC builds up and more is left for vitamin D. In keratinocytes, added cholesterol cut DHCR7 activity by 55% and raised vitamin D synthesis by 50%."
        ),
        LifecycleStage(
            icon: "hourglass",
            title: "And the reserve thins with age",
            molecule: nil,
            body: "The amount of 7-DHC held in the epidermis falls steadily over a lifetime. It's a large part of why an older person can sit in exactly the same sunshine as a younger one and make substantially less vitamin D from it.",
            aside: "The app applies an age adjustment for this — about 1% per year past 20, levelling off around a quarter of youthful capacity."
        ),
        LifecycleStage(
            icon: "sun.max.fill",
            title: "UVB snaps the ring open",
            molecule: "previtamin D3",
            body: "A photon of UVB — a narrow band around 295–300 nm — carries just the right energy to break one bond in 7-DHC's four-ring steroid skeleton. The B-ring springs open.\n\nThe result is a secosteroid: a steroid that has been cut. That opened ring is the whole point; it's what lets the molecule fold into a shape your receptors can read.",
            aside: "This is the step nothing else can do for you. No enzyme in your body performs it — the energy has to arrive as light."
        ),
        LifecycleStage(
            icon: "thermometer.medium",
            title: "Your body heat finishes the job",
            molecule: "vitamin D3 (cholecalciferol)",
            body: "Previtamin D3 isn't stable. Over the following hours it rearranges into vitamin D3 — driven not by light but by your own body temperature, quietly, in the membranes of your skin cells.",
            aside: "So you keep making vitamin D after you've gone inside. The sun starts the reaction; your warmth completes it over the next day or two."
        ),
        LifecycleStage(
            icon: "arrow.triangle.branch",
            title: "The overflow valve",
            molecule: "lumisterol3 · tachysterol3",
            body: "Keep the UVB coming and previtamin D3 stops accumulating at around 10–15% of the available 7-DHC. Past that point, further photons divert it into two other shapes — lumisterol and tachysterol — rather than making more vitamin D.\n\nThis is why sunlight cannot give you vitamin D toxicity. The chemistry itself refuses.",
            aside: "Better still, it's reversible: as previtamin D3 is drawn down, lumisterol and tachysterol can convert back. They act as a buffer, not a bin."
        ),
        LifecycleStage(
            icon: "wand.and.stars",
            title: "The \"waste\" products have day jobs",
            molecule: "20S(OH)L3 · 20S(OH)T3 · 25(OH)T3",
            body: "For decades lumisterol and tachysterol were written off as inert dead ends. They aren't. An enzyme called CYP11A1 — the same one that starts every steroid hormone in your body — hydroxylates them into a family of active metabolites, and they've been found in human skin and serum.\n\nThose metabolites protect against DNA damage and oxidative stress, guide skin cell differentiation, and act on a spread of nuclear receptors including VDR, AhR, LXR and PPARγ.",
            aside: "You only ever get these from light. There is no capsule that delivers them."
        ),
        LifecycleStage(
            icon: "drop.fill",
            title: "Into the bloodstream",
            molecule: "D3 + vitamin D binding protein",
            body: "Vitamin D3 leaves the skin bound to vitamin D binding protein and travels to the liver. Because it seeps out of the skin gradually, sunlight delivers a slow, steady trickle over days rather than a single spike."
        ),
        LifecycleStage(
            icon: "cross.case.fill",
            title: "The liver files it away",
            molecule: "25(OH)D — calcifediol",
            body: "The liver adds one hydroxyl group, via CYP2R1, producing 25-hydroxyvitamin D. This is the storage and transport form, with a half-life of two to three weeks.\n\nIt's also the number your blood test reports. \"Your vitamin D level\" is really this molecule — a reservoir, not the active hormone.",
            aside: "Because it's a reservoir, it responds slowly. A single sunny weekend barely moves it; a habit over months does."
        ),
        LifecycleStage(
            icon: "bolt.fill",
            title: "The kidney flips the switch",
            molecule: "1,25(OH)₂D — calcitriol",
            body: "A second hydroxylation by CYP27B1, mostly in the kidney, produces calcitriol — the genuinely active hormone. This step is guarded closely, tuned by parathyroid hormone, calcium, phosphate and FGF23, and calcitriol lasts only hours.",
            aside: "Immune cells, skin and other tissues run this step locally too, making calcitriol for their own use rather than for the bloodstream — a private supply, made on site."
        ),
        LifecycleStage(
            icon: "dna",
            title: "It reads your DNA",
            molecule: "VDR · RXR · VDRE",
            body: "Calcitriol slips into the cell nucleus and binds the vitamin D receptor, which pairs with the retinoid X receptor. Together they settle onto specific stretches of DNA and turn genes up or down — hundreds of them, across calcium handling, bone remodelling, immune regulation and cell differentiation.\n\nThis is why it behaves like a hormone rather than a nutrient: it doesn't get consumed, it issues instructions."
        ),
        LifecycleStage(
            icon: "arrow.uturn.down",
            title: "And then it switches itself off",
            molecule: "CYP24A1 → calcitroic acid",
            body: "Calcitriol induces CYP24A1 — the very enzyme that dismantles it — which breaks it down to calcitroic acid for excretion in bile.\n\nThe hormone triggers its own removal, so the signal stays brief and self-correcting."
        )
    ]
}

private struct SecondOrderEffect: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String

    static let all: [SecondOrderEffect] = [
        SecondOrderEffect(
            icon: "shield.lefthalf.filled",
            title: "One route has a brake, the other doesn't",
            body: "Sunlight self-limits at stage 5 — the chemistry simply stops making more. Swallowed vitamin D has no such brake, which is why toxicity from supplements is possible and toxicity from sunshine is not."
        ),
        SecondOrderEffect(
            icon: "chart.line.flattrend.xyaxis",
            title: "A trickle, not a spike",
            body: "Skin releases vitamin D3 slowly over days, bound to its carrier protein. An oral dose arrives packaged in chylomicrons as a bolus, and a meaningful share is taken up by fat tissue on the way past. Same molecule, different delivery — and a weekly or monthly mega-dose looks nothing like daily sun."
        ),
        SecondOrderEffect(
            icon: "wand.and.stars",
            title: "The parcel is bigger than the capsule",
            body: "Light also produces the lumisterol and tachysterol metabolites from stage 6, with their own antioxidant, DNA-protective and anti-inflammatory activity. A D3 capsule contains exactly one of the molecules sunlight makes."
        ),
        SecondOrderEffect(
            icon: "heart.fill",
            title: "Sunlight does things vitamin D doesn't",
            body: "UVA — which makes no vitamin D at all — releases nitric oxide stored in your skin, widening blood vessels and measurably lowering blood pressure. Controlled trials show the effect is independent of vitamin D. Add circadian timing through the eyes and mood effects, and \"go outside\" is doing several jobs at once."
        ),
        SecondOrderEffect(
            icon: "questionmark.circle.fill",
            title: "The awkward evidence gap",
            body: "Observational studies link low vitamin D to heart disease, diabetes, cancer and early death. Yet large randomised trials of supplementation have mostly failed to reproduce those benefits.\n\nThe leading explanation is uncomfortable but important: low 25(OH)D may often be a marker of ill health and little time outdoors, rather than its cause. If that's right, topping up the marker was never going to deliver what the sunshine was doing."
        )
    ]
}

private struct LifecycleReference: Identifiable {
    let id = UUID()
    let title: String
    let note: String
    let url: String

    static let all: [LifecycleReference] = [
        LifecycleReference(
            title: "Holick MF et al. (1981), Science 211:590–3",
            note: "Photoequilibrium: previtamin D3 plateaus at ~10–15% conversion, diverting to lumisterol3 and tachysterol3. Stage 5.",
            url: "https://www.science.org/doi/10.1126/science.6256855"),
        LifecycleReference(
            title: "Prabhu AV et al., J Biol Chem — cholesterol-mediated degradation of DHCR7",
            note: "DHCR7 reduces the C7–8 double bond of 7-DHC to form cholesterol; cholesterol accelerates DHCR7's proteasomal degradation, so 7-DHC accumulates and vitamin D synthesis rises. Stages 1–2.",
            url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4861412/"),
        LifecycleReference(
            title: "Zerenturk EJ et al. — DHCR7: a vital enzyme switch between cholesterol and vitamin D production",
            note: "Review of DHCR7 as the branch point governing the split between cholesterol and vitamin D. Stage 2.",
            url: "https://www.sciencedirect.com/science/article/abs/pii/S0163782716300340"),
        LifecycleReference(
            title: "MacLaughlin JA, Anderson RR, Holick MF (1982), Science 216:1001–3",
            note: "Action spectrum for previtamin D3; optimum 295–300 nm. Stage 3.",
            url: "https://www.science.org/doi/10.1126/science.6281884"),
        LifecycleReference(
            title: "Slominski AT et al. — CYP11A1-derived lumisterol and vitamin D metabolites",
            note: "Lumisterol and tachysterol are metabolised to bioactive hydroxyderivatives acting on VDR, AhR, LXRα/β and PPARγ, detected in human epidermis and serum. Stage 6.",
            url: "https://www.sciencedirect.com/science/article/pii/S0022202X24003865"),
        LifecycleReference(
            title: "Metabolic activation of tachysterol3 to biologically active hydroxyderivatives",
            note: "20S(OH)T3 and 25(OH)T3 characterised; receptor activity described. Stage 6.",
            url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC9345108/"),
        LifecycleReference(
            title: "Liu D, Weller RB et al. (2014), J Invest Dermatol",
            note: "UVA irradiation of human skin vasodilates arteries and lowers blood pressure — independently of vitamin D, via cutaneous nitric oxide stores.",
            url: "https://pubmed.ncbi.nlm.nih.gov/24445737/"),
        LifecycleReference(
            title: "Autier P et al. (2014), Lancet Diabetes Endocrinol 2:76–89",
            note: "Systematic review finding observational benefits of high 25(OH)D are largely not reproduced by randomised supplementation trials; argues low 25(OH)D is substantially a marker of ill health.",
            url: "https://www.thelancet.com/journals/landia/article/PIIS2213-8587(13)70165-7/abstract"),
        LifecycleReference(
            title: "Young AR et al. (2021), PNAS 118(40)",
            note: "In vivo action spectrum revision; erythemally-weighted dose is a poor predictor of synthesis. Underpins this app's solar-elevation weighting.",
            url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8501902/")
    ]
}
