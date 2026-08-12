import SwiftUI

/// A single citation.
///
/// Every reference the app shows comes from `AppReferences` below, so the
/// Sources sheet and the in-context reference cards on the two info screens
/// cannot drift apart.
struct Reference: Identifiable {
    let id = UUID()
    /// Author, year and journal. Rendered as the tappable link.
    let title: String
    /// What this paper establishes, and which part of the app rests on it.
    let detail: String
    let url: String
}

enum AppReferences {

    /// Sources behind the estimate itself: the saturating curve, its
    /// calibration, the elevation weighting and the history trend line.
    static let model: [Reference] = [
        Reference(title: "Holick MF et al. (1981)",
                  detail: "Regulation of cutaneous previtamin D3 photosynthesis in man: skin pigment is not an essential regulator. Science 211:590–3. Photoequilibrium plateau; the basis for saturation and for omitting a pigment multiplier.",
                  url: "https://www.science.org/doi/10.1126/science.6256855"),
        Reference(title: "MacLaughlin JA, Anderson RR, Holick MF (1982)",
                  detail: "Spectral character of sunlight modulates photosynthesis of previtamin D3 and its photoisomers in human skin. Science 216:1001–3. Action spectrum; optimum 295–300 nm.",
                  url: "https://www.science.org/doi/10.1126/science.6281884"),
        Reference(title: "Young AR et al. (2021)",
                  detail: "A revised action spectrum for vitamin D synthesis by suberythemal UV radiation exposure in humans in vivo. PNAS 118(40). In vivo, n=75; finds erythemally-weighted dose is a poor predictor of synthesis, and proposes a 5 nm shift. The basis for elevation weighting.",
                  url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8501902/"),
        Reference(title: "Holick's rule and vitamin D from sunlight",
                  detail: "Notes the rule derives from a fluorescent-lamp spectrum; solar UV is about 1.32× more previtamin-D-effective per erythemal unit. The basis for the 1.25 calibration.",
                  url: "https://www.sciencedirect.com/science/article/abs/pii/S0960076010001925"),
        Reference(title: "MacLaughlin JA, Holick MF (1985)",
                  detail: "Aging decreases the capacity of human skin to produce vitamin D3. J Clin Invest 76(4):1536–8. The original basis for this app's age-decline factor.",
                  url: "https://www.jci.org/articles/view/112134"),
        Reference(title: "Borecka O et al. (2024)",
                  detail: "Comparative study of healthy older and younger adults shows they have the same skin concentration of 7-dehydrocholesterol and similar response to UVR. Nutrients. Found no significant age difference, which is why the age factor is treated as contested.",
                  url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC11053405/"),
        Reference(title: "Pope SJ et al. (2008)",
                  detail: "Action spectrum conversion factors that change erythemally weighted to previtamin D3-weighted UV doses. Photochem Photobiol 84(5).",
                  url: "https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1751-1097.2008.00373.x"),
        Reference(title: "Webb AR et al. (2023)",
                  detail: "Previtamin D action spectrum: challenging CIE towards a standard. The spectrum remains formally unsettled.",
                  url: "https://journals.sagepub.com/doi/full/10.1177/14771535221122937"),
        Reference(title: "Jones G (2008)",
                  detail: "Pharmacokinetics of vitamin D toxicity. Am J Clin Nutr. 25(OH)D3 circulating half-life about 15 days; the basis for the history trend line's decay.",
                  url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4207933/"),
        Reference(title: "Gallagher JC et al. (2012)",
                  detail: "Dose-response to vitamin D supplementation in postmenopausal women. Ann Intern Med 156:425–37. Serum 25(OH)D response is curvilinear and plateaus; the basis for the trend line's saturation.",
                  url: "https://www.acpjournals.org/doi/10.7326/0003-4819-156-6-201203200-00005")
    ]

    /// Sources behind the biology on "The Life of Vitamin D".
    static let biology: [Reference] = [
        Reference(title: "Prabhu AV et al., J Biol Chem. Cholesterol-mediated degradation of DHCR7",
                  detail: "DHCR7 makes cholesterol from 7-DHC; cholesterol accelerates its breakdown, raising 7-DHC and vitamin D synthesis. The branch point.",
                  url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4861412/"),
        Reference(title: "Zerenturk EJ et al. DHCR7: a vital enzyme switch",
                  detail: "Review of DHCR7 governing the cholesterol and vitamin D split.",
                  url: "https://www.sciencedirect.com/science/article/abs/pii/S0163782716300340"),
        Reference(title: "Origin of 7-dehydrocholesterol (provitamin D) in the skin",
                  detail: "Cutaneous origin of the 7-DHC pool.",
                  url: "https://www.jidonline.org/article/S0022-202X(15)34937-X/fulltext"),
        Reference(title: "Tian XQ & Holick MF. Membrane-enhanced thermal isomerisation",
                  detail: "Liposomal model: previtamin D3 becomes D3 about ten times faster in membranes than in solution.",
                  url: "https://www.sciencedirect.com/science/article/pii/S002192581987895X"),
        Reference(title: "Slominski AT et al. CYP11A1-derived vitamin D and lumisterol metabolites",
                  detail: "Photoproducts converted to active metabolites acting on VDR, AhR, LXR and PPARγ; found in human skin and serum.",
                  url: "https://www.sciencedirect.com/science/article/pii/S0022202X24003865"),
        Reference(title: "Liu D, Weller RB et al. (2014), J Invest Dermatol",
                  detail: "UVA lowers blood pressure independently of vitamin D, via cutaneous nitric oxide stores.",
                  url: "https://pubmed.ncbi.nlm.nih.gov/24445737/"),
        Reference(title: "Autier P et al. (2014), Lancet Diabetes Endocrinol 2:76–89",
                  detail: "The observational versus interventional gap; argues low 25(OH)D substantially indexes ill health.",
                  url: "https://www.thelancet.com/journals/landia/article/PIIS2213-8587(13)70165-7/abstract"),
        Reference(title: "Endocrine Society (2024). Vitamin D for the Prevention of Disease",
                  detail: "Current clinical guideline. Recommends against routine 25(OH)D screening in healthy adults, and against exceeding standard intakes for most under 75.",
                  url: "https://www.endocrine.org/clinical-practice-guidelines/vitamin-d-for-prevention-of-disease")
    ]

    /// Where the UV, cloud and sun-time numbers come from.
    static let data: [Reference] = [
        Reference(title: "Open-Meteo",
                  detail: "UV index, clear-sky UV, cloud cover and sun times. No API key, no tracking.",
                  url: "https://open-meteo.com")
    ]

    /// Upstream project and this fork.
    static let attribution: [Reference] = [
        Reference(title: "github.com/jackjackbits/sunday",
                  detail: "Original project.",
                  url: "https://github.com/jackjackbits/sunday"),
        Reference(title: "github.com/JWAY21/sunniday",
                  detail: "This fork, full source.",
                  url: "https://github.com/JWAY21/sunniday")
    ]
}

/// One citation row: a tappable title that opens the paper, plus a plain-English
/// note on what it establishes.
struct ReferenceLink: View {
    let reference: Reference

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let url = URL(string: reference.url) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text(reference.title)
                            .font(.system(size: 13, weight: .semibold))
                            .underline()
                            .multilineTextAlignment(.leading)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            } else {
                Text(reference.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(reference.detail)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Every source the app rests on, in one place.
///
/// Reachable in one tap from a labelled Sources button on both info screens,
/// whichever tab you are on. The citations were previously only at the foot of
/// the Science tab, which is not the tab that opens.
struct SourcesView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "7f92d6"), Color(hex: "a9a3e0")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        intro
                        section("How the estimate is calculated", "function", AppReferences.model)
                        section("The biology", "atom", AppReferences.biology)
                        section("Where the UV data comes from", "antenna.radiowaves.left.and.right", AppReferences.data)
                        section("Open source", "chevron.left.forwardslash.chevron.right", AppReferences.attribution)
                        disclaimer
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Sources")
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

    private var intro: some View {
        Text("Every number in SUNniDAY traces back to published research. Each source below links to the paper, with a note on what it establishes and which part of the app rests on it.")
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.9))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var disclaimer: some View {
        Text("SUNniDAY gives estimates, not measurements. It is not medical advice. Talk to a doctor before changing sun habits or supplements.")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .padding(.top, 4)
            .padding(.horizontal, 8)
    }

    private func section(_ title: String, _ icon: String, _ references: [Reference]) -> some View {
        InfoCard(icon: icon, title: title) {
            VStack(alignment: .leading, spacing: 11) {
                ForEach(references) { ReferenceLink(reference: $0) }
            }
        }
    }
}
