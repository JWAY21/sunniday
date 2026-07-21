import SwiftUI

// Shared glossary used by both info screens (InfoView / "How It Works" and
// LifecycleView / "The Life of Vitamin D"). One source of truth for the terms,
// one inline-link mechanism, one definition presentation.
//
// Inline usage: write body copy as markdown with links of the form
//   [display text](glossary://slug)
// rendered by `GlossaryText`. A container that applies `.glossaryTaps()`
// intercepts those taps and shows the definition; real http links pass through
// to the browser unchanged.

struct GlossaryEntry: Identifiable {
    let id: String          // slug used in glossary://<slug> links
    let term: String        // display name in the glossary list
    let definition: String
}

enum Glossary {
    static func entry(_ slug: String) -> GlossaryEntry? {
        all.first { $0.id == slug }
    }

    static let all: [GlossaryEntry] = [
        GlossaryEntry(id: "secosteroid", term: "Secosteroid",
                      definition: "A steroid whose four-ring core has had one ring cut open. Vitamin D is a secosteroid — the opened B-ring is what lets it act as a hormone."),
        GlossaryEntry(id: "7-dhc", term: "7-DHC (7-dehydrocholesterol)",
                      definition: "The immediate precursor to cholesterol, and the molecule UVB converts to previtamin D3. Also called provitamin D3."),
        GlossaryEntry(id: "dhcr7", term: "DHCR7",
                      definition: "The enzyme that turns 7-DHC into cholesterol — the branch point between making cholesterol and leaving 7-DHC free for vitamin D."),
        GlossaryEntry(id: "mevalonate", term: "Mevalonate pathway",
                      definition: "The chain of reactions that builds sterols from acetyl-CoA, via squalene and lanosterol. Its rate-limiting enzyme, HMG-CoA reductase, is what statins block."),
        GlossaryEntry(id: "acetyl-coa", term: "Acetyl-CoA",
                      definition: "The two-carbon building block that carbohydrate, fat and protein all break down into. Around eighteen are assembled into one sterol."),
        GlossaryEntry(id: "previtamin-d3", term: "Previtamin D3",
                      definition: "The immediate, unstable product of UVB acting on 7-DHC. It rearranges into vitamin D3 over hours, driven by body heat."),
        GlossaryEntry(id: "photoequilibrium", term: "Photoequilibrium",
                      definition: "A balance point under continued light where previtamin D3 stops accumulating and further UVB diverts it into other molecules instead. This ceiling prevents vitamin D toxicity from sun."),
        GlossaryEntry(id: "isomerisation", term: "Isomerisation",
                      definition: "A molecule rearranging into a different shape with the same atoms. Previtamin D3 → vitamin D3 is a heat-driven isomerisation."),
        GlossaryEntry(id: "photoproducts", term: "Lumisterol & tachysterol",
                      definition: "The two molecules previtamin D3 is diverted into once the ceiling is reached. Long thought inert, they are now known to yield biologically active metabolites — but they make no vitamin D."),
        GlossaryEntry(id: "cholecalciferol", term: "Cholecalciferol (vitamin D3)",
                      definition: "The form made in skin and found in supplements. Not yet active — it must be hydroxylated twice, in liver then kidney."),
        GlossaryEntry(id: "dbp", term: "DBP (vitamin D binding protein)",
                      definition: "The carrier protein that ferries vitamin D and its metabolites through the blood."),
        GlossaryEntry(id: "25ohd", term: "25(OH)D (calcifediol)",
                      definition: "The storage form made in the liver, with a half-life of weeks. This is what a vitamin D blood test measures."),
        GlossaryEntry(id: "calcitriol", term: "1,25(OH)₂D (calcitriol)",
                      definition: "The active hormone, made mainly in the kidney. Short-lived and tightly regulated — the working form that acts on your genes."),
        GlossaryEntry(id: "hydroxylation", term: "Hydroxylation",
                      definition: "Adding an –OH group to a molecule. Vitamin D is activated by two hydroxylations, at carbon 25 (liver) then carbon 1 (kidney)."),
        GlossaryEntry(id: "cyp", term: "CYP enzymes",
                      definition: "Cytochrome P450 enzymes. Several handle vitamin D: CYP2R1 (liver activation), CYP27B1 (kidney activation), CYP24A1 (breakdown), CYP11A1 (photoproduct metabolites)."),
        GlossaryEntry(id: "vdr", term: "VDR & RXR",
                      definition: "The vitamin D receptor and its partner, the retinoid X receptor. Calcitriol binds VDR; the VDR–RXR pair docks onto DNA to switch genes on or off."),
        GlossaryEntry(id: "pth-fgf23", term: "PTH & FGF23",
                      definition: "Hormones that tune vitamin D activation. Parathyroid hormone (PTH) raises it when calcium is low; FGF23 restrains it."),
        GlossaryEntry(id: "action-spectrum", term: "Action spectrum",
                      definition: "How effective each wavelength of light is at driving a reaction. The vitamin D action spectrum peaks at shorter wavelengths than the sunburn one, so burning is a poor proxy for vitamin D."),
        GlossaryEntry(id: "med", term: "MED (minimal erythemal dose)",
                      definition: "The smallest UV dose that leaves skin faintly pink a day later. A personalised unit of sunburn risk that already accounts for skin type and sun strength — the unit this app tracks."),
        GlossaryEntry(id: "half-life", term: "Half-life",
                      definition: "The time for half of a substance to clear. Vitamin D3 ~1 day, 25(OH)D ~3 weeks, calcitriol ~half a day."),
        GlossaryEntry(id: "clear-sky-uv", term: "Clear-sky UV",
                      definition: "The UV index the sky would have with no cloud. The app back-calculates from it so a manual cloud override can't inflate UV beyond what's physically possible."),
        GlossaryEntry(id: "solar-elevation", term: "Solar elevation",
                      definition: "How high the sun sits above the horizon. Low sun means a longer path through the atmosphere, which filters out the short UVB that makes vitamin D — so morning and winter sun yield less per sunburn.")
    ]
}

// MARK: - Inline text with tappable glossary links

/// Renders body copy that may contain `[text](glossary://slug)` links (and
/// real http links). Glossary links are drawn gold + underlined; taps are
/// handled by the enclosing `.glossaryTaps()` container.
struct GlossaryText: View {
    let markdown: String
    var size: CGFloat = 14
    var opacity: Double = 0.92

    init(_ markdown: String, size: CGFloat = 14, opacity: Double = 0.92) {
        self.markdown = markdown
        self.size = size
        self.opacity = opacity
    }

    var body: some View {
        Text(attributed)
            .font(.system(size: size))
            .foregroundColor(.white.opacity(opacity))
            .tint(Color(hex: "f5c842"))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard var a = try? AttributedString(markdown: markdown, options: options) else {
            return AttributedString(markdown)
        }
        for run in a.runs where run.link != nil {
            a[run.range].underlineStyle = .single
            a[run.range].foregroundColor = Color(hex: "f5c842")
        }
        return a
    }
}

// MARK: - Tap handling + definition presentation

private struct GlossaryModifier: ViewModifier {
    @State private var selected: GlossaryEntry?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "glossary", let e = Glossary.entry(url.host ?? "") {
                    selected = e
                    return .handled
                }
                return .systemAction   // real links open in the browser
            })
            .sheet(item: $selected) { entry in
                GlossaryDefinitionSheet(entry: entry)
            }
    }
}

extension View {
    /// Makes `glossary://slug` links inside this subtree open a definition card.
    func glossaryTaps() -> some View { modifier(GlossaryModifier()) }
}

private struct GlossaryDefinitionSheet: View {
    let entry: GlossaryEntry
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "6d7fc9"), Color(hex: "a9a3e0")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text(entry.term)
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .foregroundColor(.white)

                Text(entry.definition)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.92))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(24)
        }
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    }
}
