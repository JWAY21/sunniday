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
                      definition: "A steroid is a molecule built from four carbon rings fused together — cholesterol, testosterone and cortisol are all steroids. A secosteroid is one where a saw has been taken to one of those rings, breaking it open (\"seco\" is Latin for cut). In vitamin D, that one broken ring is everything: it lets the otherwise rigid molecule flex into an open shape, and it's that shape that slots into the receptor which switches genes on. Weld the ring shut again and it stops working as a hormone."),
        GlossaryEntry(id: "sterol", term: "Sterol",
                      definition: "A family of waxy, fat-like molecules all built on the same four-ring skeleton, found in the membranes of nearly every living cell. Cholesterol is the famous animal one; plants make their own (phytosterols). 7-DHC and vitamin D belong to the same family. Sterols keep cell membranes firm and fluid at the same time, and they're the raw material every steroid hormone is carved from — including vitamin D."),
        GlossaryEntry(id: "7-dhc", term: "7-DHC (7-dehydrocholesterol)",
                      definition: "Chemically, this is cholesterol with one extra double bond — the very last stop on the assembly line before finished cholesterol. Your skin deliberately keeps a pool of it, because that extra double bond is exactly the bond UVB light can break. It's also called provitamin D3: raw material sitting in the skin, waiting. Every molecule faces a fork — get finished into cholesterol, or, if a UVB photon arrives first, be turned into vitamin D."),
        GlossaryEntry(id: "dietary-cholesterol", term: "Dietary cholesterol",
                      definition: "The cholesterol you eat, found only in animal foods — eggs, meat, shellfish, butter and other dairy. It's easy to assume it feeds vitamin D, but it barely does. Skin builds its own 7-DHC from scratch rather than importing finished cholesterol, and the step that makes 7-DHC runs one way only, so cholesterol from your plate can't be turned back into it. Dietary cholesterol matters for your blood lipids, not for how much vitamin D your skin can make."),
        GlossaryEntry(id: "blood-cholesterol", term: "This cholesterol vs \"high cholesterol\"",
                      definition: "Worth being clear: the cholesterol on this page is the kind every cell makes and keeps inside itself, to build its membranes and molecules like vitamin D. \"High cholesterol\" on a blood test is a different quantity — cholesterol packaged into particles (LDL, HDL) and shipped around in the bloodstream. A cell dialling its own cholesterol up or down barely moves that blood number, which is set mostly by how well the liver clears LDL particles, plus diet and genetics. So nothing here is about the figure your doctor watches."),
        GlossaryEntry(id: "dhcr7", term: "DHCR7",
                      definition: "The enzyme (7-dehydrocholesterol reductase) that carries out the final step of cholesterol production: it grabs 7-DHC and removes its extra double bond, turning it into finished cholesterol. Because it's the gatekeeper of that last step, how active it is decides the split — how much 7-DHC gets spent making cholesterol versus left in the skin for sunlight. Slow it down and 7-DHC piles up; speed it up and it's used up."),
        GlossaryEntry(id: "acetyl-coa", term: "Acetyl-CoA",
                      definition: "A tiny two-carbon molecule that is the universal currency of your metabolism. Whatever you eat — sugar, fat or protein — is broken down inside your cells into acetyl-CoA, which is then either burned for energy or used as a building block. Its two carbon atoms trace back through your food to plants, and through plants to carbon dioxide pulled out of the air by photosynthesis. Roughly eighteen of them are stitched together to build a single cholesterol molecule."),
        GlossaryEntry(id: "mevalonate", term: "Mevalonate pathway",
                      definition: "The long assembly line your cells use to build sterols from scratch, starting from tiny acetyl-CoA units. It runs acetyl-CoA → HMG-CoA → mevalonate → … → squalene → lanosterol → cholesterol, roughly thirty steps in all. Its slowest, controlling step is an enzyme called HMG-CoA reductase — the exact target of statin drugs, which is why statins lower cholesterol (and, in theory though not in practice, might touch vitamin D)."),
        GlossaryEntry(id: "previtamin-d3", term: "Previtamin D3",
                      definition: "The fleeting, unstable molecule created the instant UVB light snaps open 7-DHC's ring. It isn't vitamin D yet, and it doesn't sit still: over the next hours, warmed by your body heat, it slowly rearranges itself into actual vitamin D3. Meanwhile, if UVB keeps hitting it, some is shunted off into the dead-end molecules lumisterol and tachysterol instead. It sits at a three-way crossroads, and where it goes depends on heat, light and time."),
        GlossaryEntry(id: "photoequilibrium", term: "Photoequilibrium",
                      definition: "A balance point reached under steady sunlight, where the rate of making previtamin D3 exactly matches the rate of converting it away into other molecules. Past this point, extra UVB no longer raises previtamin D3 — it just reshuffles it into lumisterol and tachysterol. This is the body's built-in overdose protection: however long you lie in the sun, only about 10–15% of your skin's 7-DHC is ever previtamin D3 at once, so you can burn but you can't reach a toxic dose of vitamin D from light."),
        GlossaryEntry(id: "isomerisation", term: "Isomerisation",
                      definition: "When a molecule rearranges its own atoms into a new shape without gaining or losing any — the same ingredients rebuilt into a different structure, which behaves differently. Previtamin D3 becoming vitamin D3 is an isomerisation driven by warmth rather than light: the atoms shuffle, a hydrogen hops across, and the floppy precursor settles into the stable vitamin your body can actually use."),
        GlossaryEntry(id: "photoproducts", term: "Lumisterol & tachysterol",
                      definition: "The two \"overflow\" molecules previtamin D3 is pushed into once sunlight passes the ceiling. For decades they were written off as inert waste. We now know skin enzymes turn them into a family of active compounds with antioxidant and skin-protective roles — but crucially they are not vitamin D and cannot be turned into it. They exist only because of light, which is one reason a supplement can't fully stand in for sun."),
        GlossaryEntry(id: "cholecalciferol", term: "Cholecalciferol (vitamin D3)",
                      definition: "Vitamin D3 itself — the molecule made in your skin and sold in supplement bottles. Despite the name it isn't active yet: it's an inactive precursor that must be modified twice, first in the liver and then in the kidney, before it can do anything. Think of it as the raw hormone, still needing two factory upgrades before it's switched on."),
        GlossaryEntry(id: "dbp", term: "DBP (vitamin D binding protein)",
                      definition: "Vitamin D and its relatives are fatty molecules that don't dissolve well in watery blood, so they travel clipped to a dedicated carrier — vitamin D binding protein — which ferries them from skin to liver to kidney to the tissues that need them. It also acts as a buffer, holding a reserve of vitamin D in circulation so levels don't swing wildly."),
        GlossaryEntry(id: "25ohd", term: "25(OH)D (calcifediol)",
                      definition: "25-hydroxyvitamin D, the stable storage form your liver makes from vitamin D3. It lingers in the blood for weeks, which is exactly why it's the number a lab reports as \"your vitamin D level\": it reflects your supply over the past month or two, not just today. It's a reservoir, not the working hormone — that comes one step later, in the kidney, and only on demand."),
        GlossaryEntry(id: "calcitriol", term: "1,25(OH)₂D (calcitriol)",
                      definition: "The fully active vitamin D hormone, switched on by the kidney only when it's needed. Its headline job is calcium: it tells your gut to absorb calcium and phosphate from food, and helps hold blood calcium in the narrow band your nerves, muscles and heart depend on — which is why it's essential for building and maintaining bone. Beyond that it helps regulate the immune system, dampens inflammation, and signals to cells when to grow and specialise. It's powerful, short-lived, and kept on a very tight leash."),
        GlossaryEntry(id: "hydroxylation", term: "Hydroxylation",
                      definition: "Bolting a single oxygen-plus-hydrogen (–OH) group onto a molecule — a small chemical tweak that can completely change what the molecule does. Vitamin D has to be hydroxylated twice to switch on: once in the liver (at a carbon called position 25) to make the storage form, then again in the kidney (at position 1) to make the active hormone."),
        GlossaryEntry(id: "cyp", term: "CYP enzymes",
                      definition: "Cytochrome P450s — a large family of workhorse enzymes that chemically modify molecules, usually by hydroxylation. Vitamin D passes through several by name: CYP2R1 in the liver switches on the storage form, CYP27B1 in the kidney makes the active hormone, CYP24A1 breaks it back down when there's enough, and CYP11A1 in skin turns the lumisterol/tachysterol overflow into active metabolites."),
        GlossaryEntry(id: "vdr", term: "VDR & RXR",
                      definition: "The vitamin D receptor (VDR) is the molecular lock that active vitamin D fits into. Once the hormone is bound, VDR teams up with a partner receptor (RXR, the retinoid X receptor) and the pair clamps onto specific spots on your DNA, switching nearby genes on or off. This is the final link in the chain: how a hormone that started as sunlight ends up changing which proteins your cells actually build."),
        GlossaryEntry(id: "pth-fgf23", term: "PTH & FGF23",
                      definition: "Two hormones that dial vitamin D activation up and down. Parathyroid hormone (PTH) is released when blood calcium drops, and it pushes the kidney to make more active vitamin D to pull calcium in. FGF23, released mainly by bone, does the opposite — reining activation back when phosphate runs high. Between them they keep the powerful active hormone from ever running away."),
        GlossaryEntry(id: "action-spectrum", term: "Action spectrum",
                      definition: "A graph of how effective each wavelength (colour) of light is at driving a particular reaction. It matters here because two processes — making vitamin D and getting sunburnt — respond to slightly different wavelengths. Vitamin D needs shorter, higher-energy UVB, which is filtered out more when the sun sits low. That mismatch is why a sunburn is only a rough guide to how much vitamin D you've made, and why this app adjusts for how high the sun is."),
        GlossaryEntry(id: "med", term: "MED (minimal erythemal dose)",
                      definition: "The smallest amount of UV that leaves your skin just visibly pink about a day later. It's a personal unit: fair skin reaches 1 MED far sooner than dark skin under the same sun. Because it already folds in both your skin type and the sun's current strength, it's a far fairer measure of exposure than counting minutes — and it's the unit this app tracks toward your burn limit."),
        GlossaryEntry(id: "half-life", term: "Half-life",
                      definition: "The time it takes for half of a substance to clear from your body. It tells you how long each form of vitamin D lingers, and the spread is huge: the active hormone (calcitriol) is largely gone within a day, so the body retunes it constantly, while the storage form (25(OH)D) lasts about three weeks — which is why a habit built over a month moves your blood level but a single sunny afternoon barely does."),
        GlossaryEntry(id: "solar-elevation", term: "Solar elevation",
                      definition: "How high the sun sits above the horizon, measured in degrees. It matters more than most people expect: when the sun is low, its light slices through far more atmosphere, and that thicker path soaks up the short-wavelength UVB that makes vitamin D. So the same time outdoors gives you much less vitamin D at 8am, or in midwinter, than at noon in summer — even though low sun can still burn you."),
        GlossaryEntry(id: "modelled-trend", term: "Modelled reserve",
                      definition: "The yellow line on the history chart. The bars show what you made each day; this line is a best-guess of the reserve those days have banked. Vitamin D's storage form (25(OH)D) has a roughly 2–3 week half-life, so what you make accumulates and clears slowly — a good run of days lifts the line, a lazy stretch lets it drop. It's shown in the same unit as everything else (mcg or IU), on its own scale on the right, because a reserve is much larger than a single day. It saturates too: twice the sun doesn't bank twice the reserve, because the real response is curvilinear. Most importantly it is an estimate, not a measurement — the app models skin synthesis, which isn't the same as the 25(OH)D a lab measures in your blood. Watch its direction, not the exact figure. Full detail is in \"How It Works\"."),
        GlossaryEntry(id: "one-compartment", term: "One-compartment model",
                      definition: "The simplest pharmacokinetic model: picture the body as a single tank that a substance flows into (intake) and drains from at a rate proportional to how full it is (clearance). It's the standard first-order description of how 25(OH)D builds and clears, and what the history trend line is based on — a deliberate simplification of a body that really has fat stores, protein binding and feedback."),
        GlossaryEntry(id: "clear-sky-uv", term: "Clear-sky UV",
                      definition: "The UV index the sky would show with no cloud at all. The app uses it as a physical ceiling: when you manually correct the cloud cover, it works back from the clear-sky value, so your override can never push the UV higher than the sun could actually deliver at that moment. It's what stops a cloud tweak from inventing impossible UV numbers.")
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

            VStack(alignment: .leading, spacing: 12) {
                // Pinned header
                HStack(alignment: .top) {
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.top, 3)
                    Text(entry.term)
                        .font(.system(size: 20, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .foregroundColor(.white)

                // Scrollable definition — long entries don't get clipped
                ScrollView {
                    Text(entry.definition)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.92))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                }
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
