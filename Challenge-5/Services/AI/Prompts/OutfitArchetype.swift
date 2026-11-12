//
//  OutfitArchetype.swift
//  Challenge-5
//
//  Created by Natalie Grace on 04/11/26.
//

import Foundation

// MARK: - Outfit Structure

/// The pieces a look is made of. The fixed structures come from the reference photos;
/// the other looks use the "optional outer" structures, so the model decides whether an outer fits.
nonisolated enum OutfitStructure: String, Sendable, CaseIterable {
    case outerTopBottom
    case topBottom
    case dress
    case dressWithOuter
    /// A top and a bottom; the model adds an outer only when the look needs one.
    case topBottomOptionalOuter
    /// A dress or jumpsuit; the model adds an outer only when the look needs one.
    case dressOptionalOuter

    /// The garment categories the model must output, in order.
    var categories: [GarmentCategory] {
        switch self {
        case .outerTopBottom: [.outer, .top, .bottom]
        case .topBottom, .topBottomOptionalOuter: [.top, .bottom]
        case .dress, .dressOptionalOuter: [.dress]
        case .dressWithOuter: [.dress, .outer]
        }
    }

    /// Whether the model may add one outer layer on top of `categories`.
    var hasOptionalOuter: Bool {
        self == .topBottomOptionalOuter || self == .dressOptionalOuter
    }

    /// Every category a parsed look may keep: the required ones plus the optional outer.
    var allowedCategories: [GarmentCategory] {
        hasOptionalOuter ? [.outer] + categories : categories
    }

    /// Same base (dress or separates), with the outer left to the model.
    var withOptionalOuter: OutfitStructure {
        hasDress ? .dressOptionalOuter : .topBottomOptionalOuter
    }

    // MARK: - Dresscode

    /// Whole words only, so "dressy casual" or "dresscode" don't count as a dress.
    private static let dresscodeOnePieceKeywords: Set<String> = [
        "dress", "dresses", "gown", "gowns", "jumpsuit", "jumpsuits", "romper", "rompers", "playsuit", "terusan", "gaun",
        "swimsuit", "swimsuits", "monokini"
    ]
    private static let dresscodeSeparatesKeywords: Set<String> = [
        "skirt", "rok", "pants", "trousers", "jeans", "shorts", "culottes", "kulot", "celana",
        "blouse", "shirt", "kemeja", "top", "atasan", "kebaya", "jarik", "sarong",
        "bikini", "bikinis", "swimwear", "renang"
    ]

    /// The pieces the dresscode itself asks for ("mini dress" -> a dress, "skirt" -> separates),
    /// or `nil` when it only names a formality or a color.
    init?(dresscode: String) {
        let words = DresscodeText.affirmed(dresscode)
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
        guard !words.isEmpty else { return nil }
        if words.contains(where: { Self.dresscodeOnePieceKeywords.contains($0) }) {
            self = .dressOptionalOuter
        } else if words.contains(where: { Self.dresscodeSeparatesKeywords.contains($0) }) {
            self = .topBottomOptionalOuter
        } else {
            return nil
        }
    }

    var hasDress: Bool {
        categories.contains(.dress)
    }

    /// How the structure is described to the model.
    var promptDescription: String {
        switch self {
        case .outerTopBottom:
            "An outer layer (jacket, blazer, coat, cardigan or similar) over a top, with a bottom."
        case .topBottom:
            "A top and a bottom only, no outer layer."
        case .dress:
            "One dress or jumpsuit only, no top, bottom or outer layer."
        case .dressWithOuter:
            "A dress or jumpsuit with an outer layer over it, no separate top or bottom."
        case .topBottomOptionalOuter:
            "A top and a bottom. An outer layer is optional: add one only if the occasion, dresscode, weather or this look's idea really calls for it."
        case .dressOptionalOuter:
            "One dress or jumpsuit, no separate top or bottom. An outer layer is optional: add one only if the occasion, dresscode, weather or this look's idea really calls for it."
        }
    }
}

// MARK: - Outfit Archetype

/// The creative direction of each of the 5 looks, so they differ in style, not only in color.
///
/// The occasion, the Indonesian setting (tropical climate, local wardrobe), body shape and personality
/// (style vision + the user's taste) guide every look as a baseline; each direction adds its own focus:
/// - Look 1 `referenceMatch`: recreates the user's reference photos (or a signature look without them).
/// - Look 2 `localTouch`: one Indonesian element (batik, tenun, kebaya...) styled in a modern way.
/// - Look 3 `colorStory`: color-led: a deliberate tonal, monochrome or color-blocked palette story.
/// - Look 4 `surpriseMe`: a bold style direction the user wouldn't pick herself.
/// - Look 5 `lookMore`: the style vision ("I want to look more...") pushed to the maximum.
///
/// Looks generated later ("generate more") cycle through the same 5 directions.
nonisolated enum OutfitArchetype: Int, Sendable, CaseIterable {
    case referenceMatch
    case localTouch
    case colorStory
    case surpriseMe
    case lookMore

    // MARK: - Sampling Values

    /// Grounded looks (reference, local touch) stay lower; creative looks go higher.
    private static let referenceMatchTemperature: Float = 0.35
    private static let localTouchTemperature: Float = 0.55
    private static let colorStoryTemperature: Float = 0.60
    private static let surpriseMeTemperature: Float = 0.90
    private static let lookMoreTemperature: Float = 0.70
    private static let groundedTopP: Float = 0.90
    private static let creativeTopP: Float = 0.95

    // MARK: - Initializer

    /// The direction for a look: looks 0...4 get one each, later looks cycle through them again.
    init(lookIndex: Int) {
        let cases = Self.allCases
        self = cases[((lookIndex % cases.count) + cases.count) % cases.count]
    }

    // MARK: - Properties

    /// Name shown to the model and stored as the look's archetype.
    func title(hasReference: Bool, hasVision: Bool) -> String {
        switch self {
        case .referenceMatch: hasReference ? "Reference Match" : "Signature Look"
        case .localTouch: "Local Touch"
        case .colorStory: "Color Story"
        case .surpriseMe: "Surprise Me"
        case .lookMore: hasVision ? "Look More" : "Statement Look"
        }
    }

    var temperature: Float {
        switch self {
        case .referenceMatch: Self.referenceMatchTemperature
        case .localTouch: Self.localTouchTemperature
        case .colorStory: Self.colorStoryTemperature
        case .surpriseMe: Self.surpriseMeTemperature
        case .lookMore: Self.lookMoreTemperature
        }
    }

    var topP: Float {
        switch self {
        case .referenceMatch, .localTouch: Self.groundedTopP
        case .colorStory, .surpriseMe, .lookMore: Self.creativeTopP
        }
    }

    /// Only the surprise look may use one accent color outside the seasonal palette.
    var allowsOffPaletteAccent: Bool {
        self == .surpriseMe
    }

    /// The pieces for this look, in priority order:
    /// 1. A garment named in the dresscode ("mini dress") applies to every look.
    /// 2. Reference photos: look 1 copies their pieces; looks 2, 3 and 5 keep the same base
    ///    (dress or separates). The surprise look may go elsewhere.
    /// 3. Otherwise each direction picks separates or a dress, and the model decides on an outer.
    func structure(referenceStructure: OutfitStructure?, dresscodeStructure: OutfitStructure? = nil) -> OutfitStructure {
        if let dresscodeStructure {
            if self == .referenceMatch, let referenceStructure, referenceStructure.hasDress == dresscodeStructure.hasDress {
                return referenceStructure
            }
            return dresscodeStructure
        }
        if let referenceStructure, self != .surpriseMe {
            return self == .referenceMatch ? referenceStructure : referenceStructure.withOptionalOuter
        }
        switch self {
        case .referenceMatch:
            return referenceStructure ?? .topBottomOptionalOuter
        case .localTouch, .colorStory:
            return .topBottomOptionalOuter
        case .surpriseMe, .lookMore:
            return referenceStructure?.hasDress == true ? .topBottomOptionalOuter : .dressOptionalOuter
        }
    }
}


/// Groups seasonal palette colors by hue, so each look can be led by a different color family.
///
/// Autumn palettes list many browns and beiges first, and a small model tends to pick from the start
/// of a list, so most looks came out brown. Giving each look its own lead family spreads the colors.
nonisolated enum PaletteColorFamily: String, CaseIterable, Sendable {
    case red = "Reds, corals & pinks"
    case blue = "Blues & teals"
    case green = "Greens & olives"
    case purple = "Purples & plums"
    case gold = "Golds, oranges & yellows"
    case earth = "Browns & earth tones"
    case neutral = "Neutrals"

    /// Families that can lead a look, handed out in this order (look 1 gets the first one present).
    static let leadRotation: [PaletteColorFamily] = [.red, .blue, .green, .purple, .gold]

    /// Below this saturation a color reads as a neutral.
    private static let neutralMaximumSaturation = 0.2
    /// Warm colors darker or duller than these read as brown instead of gold or orange.
    private static let earthMaximumBrightness = 0.7
    private static let earthMaximumSaturation = 0.5

    /// The family of a `#RRGGBB` color, or `nil` when the hex is invalid.
    init?(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard clean.count == 6, let value = UInt32(clean, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        let maximum = max(red, green, blue)
        let delta = maximum - min(red, green, blue)
        let saturation = maximum == 0 ? 0 : delta / maximum
        guard delta > 0, saturation >= Self.neutralMaximumSaturation else {
            self = .neutral
            return
        }

        var hue: Double
        if maximum == red {
            hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maximum == green {
            hue = 60 * ((blue - red) / delta + 2)
        } else {
            hue = 60 * ((red - green) / delta + 4)
        }
        if hue < 0 { hue += 360 }

        switch hue {
        case 330..., ..<20:
            self = .red
        case 20..<70:
            self = (maximum < Self.earthMaximumBrightness || saturation < Self.earthMaximumSaturation) ? .earth : .gold
        case 70..<170:
            self = .green
        case 170..<260:
            self = .blue
        default:
            self = .purple
        }
    }

    /// The palette grouped by family: lead families first, browns and neutrals last.
    static func grouped(_ palette: [ColorSeason.ColorSwatch]) -> [(family: PaletteColorFamily, swatches: [ColorSeason.ColorSwatch])] {
        allCases.compactMap { family in
            let swatches = palette.filter { PaletteColorFamily(hex: $0.hex) == family }
            return swatches.isEmpty ? nil : (family, swatches)
        }
    }

    /// The lead family for a look, rotating through the families this palette has.
    static func leadFamily(forLookIndex lookIndex: Int, palette: [ColorSeason.ColorSwatch]) -> PaletteColorFamily? {
        let available = leadRotation.filter { family in
            palette.contains { PaletteColorFamily(hex: $0.hex) == family }
        }
        guard !available.isEmpty else { return nil }
        return available[((lookIndex % available.count) + available.count) % available.count]
    }
}


// MARK: - Occasion Style Bank

/// What to wear for common occasions in Indonesia, matched from the occasion title.
///
/// A small model often misreads short titles ("holiday", "kondangan", "bukber") and, without a
/// reference photo, falls back to plain, generic pieces. Each guide says how formal the event is,
/// how much "wow" it needs, which fabrics and details fit, and gives modern silhouette options:
/// every look gets a different option, so the 5 looks are 5 real alternatives.
/// The dresscode, the reference look and her styling goal always win over the guide.
nonisolated struct OccasionStyleGuide: Sendable {
    let name: String
    /// Lowercased words or phrases matched as whole words in the title, dresscode or note.
    let keywords: [String]
    let formality: String
    let setting: String
    /// How striking the outfit should be.
    let statementLevel: String
    let fabricsAndDetails: String
    /// Modern silhouettes for a one-piece look (dress or jumpsuit).
    let dressOptions: [String]
    /// Modern silhouettes for separates (top and bottom, with or without an outer).
    let separatesOptions: [String]
    let avoid: String
    /// Coverage rules for religious and mourning occasions. They override MODERN STYLE's fitted,
    /// cropped and statement-detail advice.
    var modesty: String? = nil
    /// Colors the occasion itself calls for when the dresscode names none (mourning colors for a funeral).
    var impliedColors: String? = nil
    /// A place or routine (office, campus, cafe, travel) rather than an event. An event named in the
    /// same title wins: "office party" is a party, "bukber kantor" is an iftar.
    var isContext: Bool = false

    /// The guide for one look, with the silhouette option picked for this look and its pieces.
    func promptText(lookIndex: Int, hasDress: Bool) -> String {
        let options = hasDress ? dressOptions : separatesOptions
        var lines = [
            "OCCASION GUIDE (\(name)):",
            "- Formality: \(formality)",
            "- Setting: \(setting)",
            "- Statement level: \(statementLevel)",
            "- Fabrics and details that fit: \(fabricsAndDetails)"
        ]
        if !options.isEmpty {
            let option = options[((lookIndex % options.count) + options.count) % options.count]
            lines.append("- Suggested silhouette for THIS look: \(option). Use it unless the dresscode, the reference look or her styling goal needs another; keep it modern.")
        }
        lines.append("- Avoid: \(avoid)")
        if let modesty {
            lines.append("- Modesty (overrides MODERN STYLE where they differ): \(modesty)")
        }
        return lines.joined(separator: "\n")
    }
}

nonisolated enum OccasionStyleBank {

    /// The first guide whose keyword appears in the title, dresscode or note.
    /// More specific guides are listed first ("bride" before "wedding", "bukber" before "kantor").
    /// When nothing matches, a guide for the dresscode's formality is used, or `nil`.
    static func guide(forTitle title: String, dresscode: String = "") -> OccasionStyleGuide? {
        let text = " " + normalized(title + " " + dresscode) + " "
        func matches(_ guide: OccasionStyleGuide, weak: Bool) -> Bool {
            guide.keywords.contains { keyword in weakKeywords.contains(keyword) == weak && text.contains(" \(keyword) ") }
        }
        let events = guides.filter { !$0.isContext }
        let contexts = guides.filter(\.isContext)
        // 1. An event named clearly, 2. an event named by a vague word ("dinner", "family"),
        // 3. a place or routine, 4. the dresscode's formality.
        return events.first { matches($0, weak: false) }
            ?? events.first { matches($0, weak: true) }
            ?? contexts.first { matches($0, weak: false) || matches($0, weak: true) }
            ?? formalityGuides.first { matches($0, weak: false) || matches($0, weak: true) }
    }

    /// Vague words that only decide the guide when nothing clearer is named.
    private static let weakKeywords: Set<String> = [
        "dinner", "family", "keluarga", "work", "kerja", "jalan", "trip", "foto", "music", "class", "kelas",
        "school", "sekolah", "coffee", "cafe", "mall", "bar", "club", "run", "lari", "pool"
    ]

    /// Lowercased letters and digits, one space between words.
    static func normalized(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Guides

    static let guides: [OccasionStyleGuide] = [
        OccasionStyleGuide(
            name: "Bride",
            keywords: ["bride", "bridal", "pengantin", "my wedding", "nikahku", "pernikahanku"],
            formality: "The most formal look of her life, timeless and photogenic.",
            setting: "Ceremony and reception, many hours, standing, walking and endless photos.",
            statementLevel: "Highest: a breathtaking, couture-like look that still feels like her.",
            fabricsAndDetails: "Duchess satin, mikado, silk crepe, tulle, organza, French lace, pearl or bead embellishment, a train or a cape.",
            dressOptions: [
                "a corset-bodice satin ball gown with a tulle overskirt",
                "an off-shoulder lace mermaid gown",
                "a sleek crepe column gown with a lace cape",
                "a pleated organza A-line gown with pearl-trimmed straps",
                "a draped satin gown with a cowl neckline and a long train"
            ],
            separatesOptions: [
                "a beaded lace bustier with a full tulle ball skirt",
                "a pearl-trimmed satin corset top with a draped satin maxi skirt",
                "a lace long-sleeve bodysuit-style top with a pleated organza skirt"
            ],
            avoid: "Casual fabrics, plain basic cuts, anything that looks like a guest outfit."
        ),
        OccasionStyleGuide(
            name: "Wedding guest",
            keywords: ["wedding", "weddings", "kondangan", "nikahan", "pernikahan", "resepsi", "akad", "engagement", "lamaran", "tunangan", "sangjit", "teapai"],
            formality: "Semi-formal to formal, polished and festive.",
            setting: "Ballroom or garden venue, often in the evening, standing, eating and taking photos.",
            statementLevel: "High: a wow, elegant look that stands out in photos without upstaging the bride.",
            fabricsAndDetails: "Satin, silk crepe, chiffon, organza, tulle, lace panels, corset boning, draping, pleats, pearl or bead details.",
            dressOptions: [
                "a corset-bodice satin midi dress with a draped skirt",
                "a one-shoulder pleated chiffon maxi dress",
                "an off-shoulder lace-trimmed column dress",
                "a tiered tulle midi dress with a fitted bodice",
                "a cowl-neck bias-cut satin maxi dress with a cape-sleeve detail"
            ],
            separatesOptions: [
                "a lace bustier top with a flowing pleated maxi skirt",
                "a draped satin corset top with a satin column maxi skirt",
                "a cape-sleeve fitted top with wide satin palazzo pants",
                "a pearl-trimmed structured top with a mermaid satin skirt"
            ],
            avoid: "White or ivory as the main color (unless the dresscode asks for it), denim, casual tees, plain basic cuts."
        ),
        OccasionStyleGuide(
            name: "Gala, prom or formal dinner",
            keywords: ["gala", "prom", "promnight", "prom night", "awards", "ball", "formal dinner", "malam keakraban", "makrab", "farewell", "perpisahan"],
            formality: "Formal evening wear.",
            setting: "Ballroom or hotel at night, red-carpet style photos, dancing.",
            statementLevel: "Highest: red-carpet glamour.",
            fabricsAndDetails: "Satin, velvet, sequins, beading, tulle, organza, corset boning, draping, a train.",
            dressOptions: [
                "a sequin-embellished column gown",
                "a corset-bodice satin gown with a dramatic draped skirt",
                "an off-shoulder velvet mermaid gown",
                "a one-shoulder tulle gown with a beaded bodice",
                "a halter-neck satin gown with an open back"
            ],
            separatesOptions: [
                "a beaded corset top with a voluminous satin ball skirt",
                "a sequin bustier with a satin column skirt",
                "a satin cape-sleeve blazer over a corset top with wide-leg trousers"
            ],
            avoid: "Day fabrics like cotton or denim, plain office cuts."
        ),
        OccasionStyleGuide(
            name: "Graduation",
            keywords: ["graduation", "wisuda", "yudisium"],
            formality: "Smart to semi-formal, neat and photo-ready.",
            setting: "Campus hall, long sitting, then outdoor photos in the heat.",
            statementLevel: "Medium-high: polished and memorable in photos.",
            fabricsAndDetails: "Crepe, satin, light jacquard, pleats, a bow, ruching, a lace collar or trim.",
            dressOptions: [
                "a square-neck fitted midi dress with a pleated skirt",
                "a short-sleeve satin A-line midi dress with a bow detail",
                "a ruched wrap midi dress",
                "a lace-trimmed fit-and-flare dress"
            ],
            separatesOptions: [
                "a bow-neck satin blouse with a pleated midi skirt",
                "a cropped fitted blazer with a matching mini skirt",
                "a ruched fitted top with a satin A-line midi skirt"
            ],
            avoid: "Heavy layers, very short skirts, casual denim, fabrics that wrinkle badly."
        ),
        OccasionStyleGuide(
            name: "Job interview",
            keywords: ["interview", "wawancara", "sidang", "sidang skripsi", "pitching", "pitch"],
            formality: "Business formal to smart, confident and clean.",
            setting: "Office, sitting across a table.",
            statementLevel: "Low-medium: polished and confident, one refined detail only.",
            fabricsAndDetails: "Crepe, suiting, cotton poplin, sharp tailoring details, a tie-neck or a pleat.",
            dressOptions: [
                "a belted sheath dress",
                "a collared shirt dress with a defined waist"
            ],
            separatesOptions: [
                "a cropped blazer with a fitted shell top and straight trousers",
                "a tie-neck blouse with a high-waist pencil skirt",
                "a waistcoat-style top with wide-leg trousers"
            ],
            avoid: "Loud prints, revealing pieces, very casual pieces, mini lengths."
        ),
        OccasionStyleGuide(
            name: "Eid or family gathering",
            keywords: ["lebaran", "eid", "eid mubarak", "mubarak", "idul fitri", "idulfitri", "idul adha", "iduladha", "ramadhan", "ramadan", "puasa",
                       "takbiran", "tarawih", "sahur", "halal bihalal", "halalbihalal", "silaturahmi", "open house", "bukber", "buka bersama", "buka puasa",
                       "family", "keluarga", "arisan"],
            formality: "Modest smart casual to semi-formal, festive.",
            setting: "Family homes or restaurants, sitting, eating and visiting.",
            statementLevel: "Medium: festive and graceful, modest coverage.",
            fabricsAndDetails: "Crepe, chiffon, satin, pleats, a bow, delicate embroidery or lace trim.",
            dressOptions: [
                "a long-sleeve pleated chiffon maxi dress with a belted waist",
                "a satin A-line maxi dress with a bow neckline",
                "a lace-trimmed long-sleeve column dress"
            ],
            separatesOptions: [
                "a long satin tunic blouse with wide palazzo pants",
                "a ruffle-cuff blouse with a pleated maxi skirt",
                "a cape-sleeve top with flowing wide-leg trousers"
            ],
            avoid: "Short, tight or revealing pieces, party clubwear.",
            modesty: "Long sleeves, ankle-length skirts, dresses or wide trousers, loose but shaped (a belt, pleats or a defined waist seam), no low necklines or bare shoulders. Festive details like satin, pleats, a bow or delicate lace trim are welcome."
        ),
        OccasionStyleGuide(
            name: "Office or meeting",
            keywords: ["office", "kantor", "work", "kerja", "meeting", "presentation", "presentasi", "internship", "magang", "conference", "seminar"],
            formality: "Business casual.",
            setting: "Air-conditioned office, sitting most of the day.",
            statementLevel: "Low-medium: polished with one modern detail.",
            fabricsAndDetails: "Crepe, cotton poplin, fine knit, light suiting, a pleat, a tie-neck, an asymmetric hem.",
            dressOptions: [
                "a belted shirt dress",
                "a knit midi dress with a defined waist"
            ],
            separatesOptions: [
                "a cropped blazer with a shell top and wide-leg trousers",
                "an asymmetric-hem blouse with straight trousers",
                "a fine-knit top with a pleated midi skirt"
            ],
            avoid: "Very short or revealing pieces, party fabrics, distressed denim.",
            isContext: true
        ),
        OccasionStyleGuide(
            name: "Date",
            keywords: ["date", "dating", "kencan", "anniversary", "dinner", "candle light", "valentine"],
            formality: "Smart casual, romantic and flattering.",
            setting: "Cafe or restaurant, usually in the evening, sitting and talking.",
            statementLevel: "Medium-high: romantic and memorable.",
            fabricsAndDetails: "Satin, silk, lace trim, a corset bodice, ruching, a bow, soft draping.",
            dressOptions: [
                "a satin slip midi dress with lace trim",
                "a corset-bodice mini dress",
                "a ruched wrap dress",
                "an off-shoulder fitted midi dress"
            ],
            separatesOptions: [
                "a lace-trimmed camisole with a satin midi skirt and a cropped cardigan",
                "a corset top with wide-leg trousers",
                "a bow-back fitted top with a flowy mini skirt"
            ],
            avoid: "Office-stiff suits, gym or very casual wear, formal gowns."
        ),
        OccasionStyleGuide(
            name: "Birthday",
            keywords: ["birthday", "ultah", "ulang tahun", "bday", "sweet seventeen", "sweet 17"],
            formality: "Smart casual to dressy, festive.",
            setting: "Restaurant, cafe or home party, lots of photos.",
            statementLevel: "Medium-high: fun, festive and photo-ready.",
            fabricsAndDetails: "Satin, tulle, organza, a bow, ruffles, pearl trim, lace.",
            dressOptions: [
                "a bow-detail satin mini dress",
                "a tiered tulle midi dress",
                "a ruffle-hem fit-and-flare dress",
                "a pearl-trimmed corset mini dress"
            ],
            separatesOptions: [
                "a ruffle-trim top with a satin mini skirt",
                "a bow-back corset top with flared trousers",
                "a coordinated pleated two-piece set"
            ],
            avoid: "Plain office wear, loungewear."
        ),
        OccasionStyleGuide(
            name: "Holiday or beach trip",
            keywords: ["holiday", "holidays", "vacation", "liburan", "beach", "pantai", "bali", "lombok", "labuan bajo", "resort", "staycation", "pool",
                       "swim", "swimming", "renang", "bikini", "swimsuit", "swimwear", "berenang"],
            formality: "Casual, relaxed and photo-ready.",
            setting: "Outdoors in hot sun, beach, resort or walking around.",
            statementLevel: "Medium: fresh and photogenic.",
            fabricsAndDetails: "Linen, cotton, crochet, broderie, light satin, ruffles, a tie detail. When she will swim or asks for swimwear: a bikini (top as \"Top\", bottom as \"Bottom\") or a one-piece swimsuit (as \"Dress\") with a cover-up, sarong or linen shirt as the outer.",
            dressOptions: [
                "a linen tie-shoulder sundress",
                "a crochet-trim maxi dress",
                "a ruffle-hem cotton mini dress"
            ],
            separatesOptions: [
                "a crochet top with linen wide-leg pants",
                "a matching linen shirt and shorts set",
                "a tie-front top with a flowy midi skirt"
            ],
            avoid: "Dark heavy fabrics, formal tailoring, tight synthetic pieces, heavy outers."
        ),
        OccasionStyleGuide(
            name: "Travel",
            keywords: ["travel", "trip", "airport", "flight", "pesawat", "road trip", "mudik"],
            formality: "Casual, comfortable but put-together.",
            setting: "Airport, car or train, long sitting and walking.",
            statementLevel: "Low-medium: effortless and polished.",
            fabricsAndDetails: "Knit, jersey, soft cotton, linen blends, a drawstring, ribbing.",
            dressOptions: [
                "a ribbed knit midi dress",
                "a belted shirt dress"
            ],
            separatesOptions: [
                "a matching knit set with wide-leg pants",
                "a fitted ribbed top with wide-leg trousers and a light jacket",
                "a cropped zip jacket with straight-leg pants"
            ],
            avoid: "Stiff or tight pieces, delicate fabrics, very short skirts.",
            isContext: true
        ),
        OccasionStyleGuide(
            name: "Brunch or hangout",
            keywords: ["brunch", "hangout", "hang out", "nongkrong", "ngopi", "coffee", "cafe", "mall", "jalan", "shopping", "picnic", "piknik"],
            formality: "Casual to smart casual, trendy.",
            setting: "Cafe, mall or park during the day.",
            statementLevel: "Medium: trendy and effortless.",
            fabricsAndDetails: "Cotton, denim, knit, eyelet, a bow, ruffles, a square neckline.",
            dressOptions: [
                "a square-neck eyelet mini dress",
                "a smocked-bodice midi dress",
                "a knit polo dress"
            ],
            separatesOptions: [
                "a ruffle-trim top with wide-leg jeans",
                "a cropped cardigan with a pleated skort",
                "a bow-detail blouse with a denim midi skirt"
            ],
            avoid: "Formal gowns, office suits, heavy fabrics.",
            isContext: true
        ),
        OccasionStyleGuide(
            name: "Campus",
            keywords: ["campus", "kampus", "kuliah", "class", "kelas", "school", "sekolah", "academy"],
            formality: "Casual, neat and trendy.",
            setting: "Air-conditioned classrooms, walking between buildings.",
            statementLevel: "Low-medium: neat and trendy.",
            fabricsAndDetails: "Cotton, denim, knit, poplin, a collar, pleats.",
            dressOptions: [
                "a collared knit mini dress",
                "a pinafore-style denim dress over a fitted top"
            ],
            separatesOptions: [
                "a fitted knit top with wide-leg jeans",
                "an oversized-collar poplin shirt with a pleated midi skirt",
                "a cropped cardigan with straight-leg trousers"
            ],
            avoid: "Party fabrics, revealing pieces, formal gowns.",
            isContext: true
        ),
        OccasionStyleGuide(
            name: "Concert or festival",
            keywords: ["concert", "konser", "festival", "gig", "music", "coachella"],
            formality: "Casual, expressive and comfortable.",
            setting: "Crowded venue or open field, standing and jumping for hours.",
            statementLevel: "Medium-high: expressive and fun.",
            fabricsAndDetails: "Denim, faux leather, crochet, metallic details, fringe.",
            dressOptions: [
                "a corset-detail denim mini dress",
                "a fringe-trim mini dress"
            ],
            separatesOptions: [
                "a cropped graphic top with denim shorts and a cropped jacket",
                "a corset top with cargo pants",
                "a crochet top with a faux-leather mini skirt"
            ],
            avoid: "Long flowing gowns, delicate fabrics, formal tailoring."
        ),
        OccasionStyleGuide(
            name: "Christmas or new year",
            keywords: ["christmas", "natal", "natalan", "xmas", "christmas eve", "malam natal", "new year", "tahun baru", "nye", "imlek", "chinese new year", "cny", "sincia"],
            formality: "Smart casual to dressy, festive.",
            setting: "Family dinner or party, lots of photos.",
            statementLevel: "Medium-high: festive.",
            fabricsAndDetails: "Satin, velvet, sequins, a bow, pearl trim; for Imlek a modern mandarin collar or frog closure.",
            dressOptions: [
                "a velvet bow-detail mini dress",
                "a satin wrap midi dress",
                "a modern mandarin-collar satin midi dress"
            ],
            separatesOptions: [
                "a sequin top with satin wide-leg trousers",
                "a velvet corset top with a pleated midi skirt"
            ],
            avoid: "Plain office wear, gym or loungewear. For a church service (misa or kebaktian natal), no bare shoulders, low necklines or very short lengths."
        ),
        OccasionStyleGuide(
            name: "Religious service",
            keywords: ["church", "gereja", "ibadah", "misa", "mass", "sunday service", "kebaktian", "persekutuan", "paskah", "easter",
                       "pengajian", "kajian", "mosque", "masjid", "sholat", "shalat", "jumatan", "umroh", "umrah", "haji",
                       "vihara", "waisak", "pura", "galungan", "nyepi", "klenteng", "kelenteng", "temple", "baptis", "baptism", "sidi", "komuni"],
            formality: "Modest smart casual.",
            setting: "Indoor service, sitting and standing.",
            statementLevel: "Low-medium: graceful and modest.",
            fabricsAndDetails: "Crepe, chiffon, cotton, pleats, a bow, a lace collar.",
            dressOptions: [
                "a long-sleeve pleated midi dress",
                "a belted maxi shirt dress"
            ],
            separatesOptions: [
                "a bow-neck blouse with a pleated midi skirt",
                "a long-sleeve top with wide-leg trousers and a light cardigan"
            ],
            avoid: "Short, tight, see-through or low-cut pieces.",
            modesty: "Covered shoulders, sleeves of at least elbow length (long sleeves for a mosque or umrah), knee length or longer, no tight or low-cut fit. Shape comes from a clean cut, pleats or a belt; keep details soft (a bow, a lace collar, pleats)."
        ),
        OccasionStyleGuide(
            name: "Funeral or condolence visit",
            keywords: ["funeral", "melayat", "pemakaman", "condolence", "duka", "rumah duka", "takziah", "takziyah", "kematian", "berkabung",
                       "requiem", "tahlilan", "kremasi", "persemayaman", "ziarah", "nyekar"],
            formality: "Modest and respectful.",
            setting: "Funeral home or family home.",
            statementLevel: "Lowest: quiet and respectful, no statement details.",
            fabricsAndDetails: "Plain crepe or cotton, clean lines.",
            dressOptions: ["a plain long-sleeve midi dress"],
            separatesOptions: ["a simple long-sleeve blouse with straight trousers or a midi skirt"],
            avoid: "Bright colors, prints, sparkly fabrics, short or revealing pieces, statement details.",
            modesty: "Black, white, navy or dark grey only, long sleeves or elbow sleeves, below-knee length, simple clean cuts. No statement details, sparkle, lace or ruffles: here quiet and respectful wins over MODERN STYLE.",
            impliedColors: "black white navy grey"
        ),
        OccasionStyleGuide(
            name: "Night out or party",
            keywords: ["party", "parties", "night out", "girls night", "clubbing", "club", "bar", "pesta", "dugem"],
            formality: "Dressy going-out style.",
            setting: "Bar, club, rooftop or party venue at night, standing and dancing.",
            statementLevel: "High: bold and eye-catching.",
            fabricsAndDetails: "Satin, sequins, metallic fabrics, faux leather, corset boning, ruching, feathers.",
            dressOptions: [
                "a sequin mini dress",
                "a corset-bodice satin mini dress",
                "a ruched one-shoulder bodycon dress",
                "a feather-trimmed mini dress"
            ],
            separatesOptions: [
                "a corset top with a faux-leather mini skirt",
                "a halter-neck satin top with tailored wide-leg trousers",
                "a sequin bustier with a cropped blazer and a mini skirt"
            ],
            avoid: "Daytime office looks, loose tunics, plain tees, long shapeless pieces."
        ),
        OccasionStyleGuide(
            name: "Workout or sport",
            keywords: ["gym", "workout", "olahraga", "yoga", "pilates", "run", "lari", "jogging", "tennis", "padel"],
            formality: "Activewear.",
            setting: "Gym, studio or court, moving and sweating.",
            statementLevel: "Low: sporty and cute.",
            fabricsAndDetails: "Performance jersey, ribbed knit, a zip, a pleated tennis skirt.",
            dressOptions: ["a fitted tennis dress"],
            separatesOptions: [
                "a sports top with high-rise leggings",
                "a fitted tee with a pleated tennis skirt",
                "a zip jacket with bike shorts"
            ],
            avoid: "Woven fabrics, dresses outside tennis, anything restrictive."
        ),
        OccasionStyleGuide(
            name: "Photoshoot",
            keywords: ["photoshoot", "photo shoot", "foto", "prewedding", "pre wedding"],
            formality: "Depends on the theme, styled and camera-ready.",
            setting: "Studio or outdoor location.",
            statementLevel: "High: strong silhouette and texture for the camera.",
            fabricsAndDetails: "Satin, tulle, organza, feathers, lace, draping.",
            dressOptions: [
                "a tulle-layered corset gown",
                "a feather-trimmed mini dress",
                "a draped satin maxi dress"
            ],
            separatesOptions: [
                "a lace bustier with a voluminous tulle skirt",
                "a satin corset top with wide-leg trousers"
            ],
            avoid: "Busy small prints, logos, wrinkled fabrics."
        )
    ]

    /// Used when the occasion isn't recognized: matched on the dresscode's formality words.
    static let formalityGuides: [OccasionStyleGuide] = [
        OccasionStyleGuide(
            name: "Formal event",
            keywords: ["black tie", "formal", "resmi"],
            formality: "Formal.",
            setting: "Evening event, photos.",
            statementLevel: "High: elegant and striking.",
            fabricsAndDetails: "Satin, crepe, velvet, lace, beading, corset boning, draping.",
            dressOptions: ["a corset-bodice satin gown", "a one-shoulder draped column gown", "a lace-trimmed mermaid gown"],
            separatesOptions: ["a beaded bustier with a satin maxi skirt", "a cape-sleeve top with wide satin trousers"],
            avoid: "Casual fabrics, plain basic cuts."
        ),
        OccasionStyleGuide(
            name: "Semi-formal or cocktail event",
            keywords: ["semi formal", "semiformal", "cocktail"],
            formality: "Semi-formal.",
            setting: "Indoor event, standing and mingling.",
            statementLevel: "Medium-high: polished with a statement detail.",
            fabricsAndDetails: "Satin, crepe, lace, sequins, ruching, a bow.",
            dressOptions: ["a ruched satin midi dress", "a lace-trimmed fit-and-flare dress", "a one-shoulder cocktail dress"],
            separatesOptions: ["a corset top with a satin midi skirt", "a sequin top with tailored wide-leg trousers"],
            avoid: "Casual tees, denim, gym wear."
        ),
        OccasionStyleGuide(
            name: "Smart casual",
            keywords: ["smart casual", "business casual"],
            formality: "Smart casual.",
            setting: "Day or evening, relaxed but polished.",
            statementLevel: "Medium: polished and modern.",
            fabricsAndDetails: "Crepe, poplin, fine knit, satin, pleats, a tie detail.",
            dressOptions: ["a belted shirt dress", "a knit midi dress with a defined waist"],
            separatesOptions: ["a cropped blazer with a satin top and wide-leg trousers", "a tie-front blouse with a pleated midi skirt"],
            avoid: "Gowns, gym wear, very revealing pieces."
        ),
        OccasionStyleGuide(
            name: "Casual",
            keywords: ["casual", "santai", "kasual"],
            formality: "Casual.",
            setting: "Daytime, relaxed.",
            statementLevel: "Low-medium: trendy and effortless.",
            fabricsAndDetails: "Cotton, denim, knit, linen, a bow, ruffles.",
            dressOptions: ["a square-neck cotton mini dress", "a knit polo dress"],
            separatesOptions: ["a fitted knit top with wide-leg jeans", "a ruffle-trim blouse with a denim skirt"],
            avoid: "Formal gowns, office suits."
        )
    ]
}

// MARK: - Dresscode Requirements

/// Textiles, patterns, themes and formality named in the dresscode ("batik", "brokat", "vintage",
/// "black tie"). They become a checklist every look must pass, next to the garment
/// (`OutfitStructure(dresscode:)`) and the colors (`DresscodeColorRule`).
nonisolated struct DresscodeRequirements: Sendable {
    /// One line per requirement, ready for the prompt.
    let checklist: [String]
    /// Whether the dresscode asks for an era or theme (vintage, Y2K...), which may override MODERN STYLE.
    let hasTheme: Bool
    /// Words a generated look must contain for each required textile, fabric or pattern
    /// (any word of a group is enough). Checked after generation.
    let requiredTermGroups: [[String]]

    private static let indonesianTextiles = ["batik", "tenun", "songket", "ulos", "lurik", "endek", "sasirangan", "jumputan"]
    private static let traditionalThemeWords = ["tradisional", "traditional", "adat", "nasional", "national", "etnik", "ethnic", "nusantara"]
    private static let surfaceWords: [(words: [String], label: String)] = [
        (["lace", "brokat", "renda"], "lace"),
        (["sequin", "sequins", "payet", "glitter", "sparkle", "sparkly"], "sequins or sparkle"),
        (["satin"], "satin"),
        (["velvet", "beludru"], "velvet"),
        (["tulle", "tile"], "tulle"),
        (["denim", "jeans"], "denim"),
        (["linen"], "linen"),
        (["silk", "sutra", "sutera"], "silk"),
        (["chiffon", "sifon"], "chiffon"),
        (["floral", "bunga", "flower", "flowers"], "a floral print"),
        (["polkadot", "polka"], "a polka-dot print"),
        (["stripe", "stripes", "striped", "garis", "salur"], "stripes"),
        (["plaid", "tartan", "gingham", "kotak"], "a plaid or gingham check"),
        (["leopard", "zebra", "animal print"], "an animal print"),
        (["feather", "feathers", "bulu"], "feathers")
    ]
    private static let themeWords = [
        "vintage", "retro", "y2k", "70s", "80s", "90s", "boho", "bohemian", "coquette", "old money", "korean", "princess",
        "fairy", "fairytale", "royal", "glamour", "glam", "western", "cowboy", "rock", "punk", "gothic", "pajama", "piyama", "costume", "kostum"
    ]
    private static let formalityPhrases: [(words: [String], label: String)] = [
        (["semi formal", "semiformal", "cocktail"], "semi-formal / cocktail"),
        (["black tie", "formal", "resmi", "gala"], "formal"),
        (["smart casual", "business casual"], "smart casual"),
        (["casual", "santai", "kasual"], "casual")
    ]

    init(dresscode: String) {
        let text = " " + OccasionStyleBank.normalized(DresscodeText.affirmed(dresscode)) + " "
        func has(_ word: String) -> Bool { text.contains(" \(word) ") }
        var lines: [String] = []
        var termGroups: [[String]] = []

        let textiles = Self.indonesianTextiles.filter(has)
        termGroups += Set(textiles).sorted().map { [$0] }
        for textile in Set(textiles).sorted() {
            lines.append("Textile \"\(textile)\": EVERY look includes at least one \(textile) piece, cut in a current silhouette (for example a corset top, a wrap or slip dress, a pleated or column skirt, a cropped jacket). Its base color comes from the allowed colors; the other pieces are solid and pick up one of its colors. Put \"\(textile)\" in that garment's \"name\" and \"playgroundPrompt\".")
        }
        if has("kebaya") {
            termGroups.append(["kebaya"])
            lines.append("Kebaya: EVERY look has a modern kebaya top (a current neckline, sleeve or corset-style fit, lace or brocade) with a modern skirt or trousers, not a costume-like traditional set.")
        } else if textiles.isEmpty, Self.traditionalThemeWords.contains(where: has) {
            termGroups.append(["kebaya", "batik", "tenun", "songket", "ulos", "lurik", "endek", "sasirangan", "jumputan"])
            lines.append("Traditional Indonesian: EVERY look includes a modern take on an Indonesian piece (a modern kebaya top, a batik, tenun or songket piece), styled in a current way, not like a costume.")
        }
        for surface in Self.surfaceWords where surface.words.contains(where: has) {
            termGroups.append(surface.words + surface.label.components(separatedBy: " ").filter { $0.count > 3 })
            lines.append("Fabric or pattern: EVERY look uses \(surface.label) in at least one piece; name it in that garment's \"name\" and \"playgroundPrompt\".")
        }
        let themes = Self.themeWords.filter(has)
        if !themes.isEmpty {
            lines.append("Theme \"\(themes.joined(separator: ", "))\": EVERY look follows this theme with a current twist. Where it differs from MODERN STYLE, the theme wins.")
        }
        if let formality = Self.formalityPhrases.first(where: { $0.words.contains(where: has) }) {
            lines.append("Formality: \(formality.label) in every look.")
        }
        checklist = lines
        hasTheme = !themes.isEmpty
        requiredTermGroups = termGroups
    }
}

// MARK: - Dresscode Colors

extension DresscodeColorRule {
    /// The colors this occasion requires: the dresscode's colors, or else the colors the occasion
    /// itself calls for (a funeral). The prompt and the parser both use this, so they always agree.
    /// Palette colors the dresscode rules out ("no black", "jangan merah"), as uppercased hex.
    static func excludedHexes(dresscode: String, palette: [ColorSeason.ColorSwatch]) -> Set<String> {
        let negated = DresscodeText.negatedSubjects(dresscode)
        guard !negated.isEmpty, let rule = DresscodeColorRule(dresscode: negated, palette: palette) else { return [] }
        return Set(rule.swatches.prefix(rule.paletteSwatchCount).map { $0.hex.uppercased() })
    }

    static func forOccasion(title: String, dresscode: String, note: String?, palette: [ColorSeason.ColorSwatch]) -> DresscodeColorRule? {
        if let rule = DresscodeColorRule(dresscode: dresscode, palette: palette) { return rule }
        let implied = OccasionStyleBank.guide(forTitle: title, dresscode: dresscode + " " + (note ?? ""))?.impliedColors
        return implied.flatMap { DresscodeColorRule(dresscode: $0, palette: palette) }
    }
}

/// Colors the dresscode requires ("biru", "pastel", "pastel blue", "hitam putih").
///
/// The event decides these colors, so they override the season palette, the look direction,
/// the reference photos and the style vision. Every garment must use one of `swatches`:
/// the season palette colors that fit the request first (they suit her), then standard shades
/// so there is always a choice, for example when an Autumn palette has no pastels.
nonisolated struct DresscodeColorRule: Sendable {
    /// What the dresscode asked for, in plain words, for the prompt ("blue", "pastel").
    let label: String
    /// The only colors a garment may use.
    let swatches: [ColorSeason.ColorSwatch]
    /// How many of `swatches` come from her season palette (they are listed first).
    let paletteSwatchCount: Int

    // MARK: Requested Colors

    private struct ColorFamily: Sendable {
        let name: String
        let keywords: [String]
        /// Whether a palette color (hue in degrees, saturation and brightness 0...1) belongs here.
        let matches: @Sendable (Double, Double, Double) -> Bool
        let standardShades: [ColorSeason.ColorSwatch]
        let pastelShades: [ColorSeason.ColorSwatch]
    }

    private enum Tone: Sendable { case pastel, neon, earth }

    private static let toneKeywords: [(tone: Tone, words: [String])] = [
        (.pastel, ["pastel", "pastels"]),
        (.neon, ["neon", "stabilo"]),
        (.earth, ["earth", "earthy", "earthtone", "earthtones"])
    ]

    private static func swatch(_ name: String, _ hex: String) -> ColorSeason.ColorSwatch {
        ColorSeason.ColorSwatch(name: name, hex: hex)
    }

    /// Checked in this order, so "navy" and "maroon" win over "blue" and "red" when both could match.
    private static let families: [ColorFamily] = [
        ColorFamily(name: "navy", keywords: ["navy"],
                    matches: { h, s, v in (200...250).contains(h) && s >= 0.3 && v < 0.45 },
                    standardShades: [swatch("Navy", "#1F2A44"), swatch("Midnight Navy", "#1B2340"), swatch("Ink Navy", "#26324F")],
                    pastelShades: [swatch("Powder Blue", "#B6CCE4")]),
        ColorFamily(name: "maroon", keywords: ["maroon", "burgundy", "marun", "wine"],
                    matches: { h, s, v in (h >= 330 || h < 15) && s >= 0.4 && v < 0.5 },
                    standardShades: [swatch("Maroon", "#6B1E2B"), swatch("Burgundy", "#7A2434"), swatch("Wine", "#5E1A2A")],
                    pastelShades: [swatch("Dusty Rose", "#D8A7AF")]),
        ColorFamily(name: "blue", keywords: ["blue", "biru", "cobalt"],
                    matches: { h, s, _ in (190...255).contains(h) && s >= 0.2 },
                    standardShades: [swatch("Cobalt Blue", "#2F5DAA"), swatch("Royal Blue", "#3A5BC7"), swatch("Sky Blue", "#7FB3E0"), swatch("Navy", "#1F2A44")],
                    pastelShades: [swatch("Baby Blue", "#BFD7ED"), swatch("Powder Blue", "#B6CCE4"), swatch("Periwinkle", "#C5CBEF")]),
        ColorFamily(name: "teal", keywords: ["teal", "tosca", "turquoise", "turkis"],
                    matches: { h, s, _ in (160..<190).contains(h) && s >= 0.2 },
                    standardShades: [swatch("Teal", "#1F7A7A"), swatch("Tosca", "#2AA198"), swatch("Turquoise", "#3BB5B0")],
                    pastelShades: [swatch("Pastel Aqua", "#BFE6E2"), swatch("Seafoam", "#C3E8DC")]),
        ColorFamily(name: "green", keywords: ["green", "hijau", "sage", "emerald", "olive", "mint"],
                    matches: { h, s, _ in (70..<160).contains(h) && s >= 0.15 },
                    standardShades: [swatch("Emerald", "#2E8B57"), swatch("Sage", "#9CAF88"), swatch("Olive", "#6B6F2E"), swatch("Forest Green", "#2F5233")],
                    pastelShades: [swatch("Mint", "#BDE5D0"), swatch("Pastel Sage", "#D3E2C7"), swatch("Pistachio", "#D4E8B8")]),
        ColorFamily(name: "yellow", keywords: ["yellow", "kuning", "mustard"],
                    matches: { h, s, v in (45..<70).contains(h) && s >= 0.3 && v >= 0.6 },
                    standardShades: [swatch("Sunflower Yellow", "#F2C230"), swatch("Mustard", "#C99A2E"), swatch("Lemon", "#F4E04D")],
                    pastelShades: [swatch("Butter Yellow", "#F8E9A1"), swatch("Pastel Lemon", "#FAF0B8")]),
        ColorFamily(name: "orange", keywords: ["orange", "oranye", "jingga", "terracotta", "coral"],
                    matches: { h, s, v in (15..<45).contains(h) && s >= 0.5 && v >= 0.7 },
                    standardShades: [swatch("Tangerine", "#F08A3C"), swatch("Coral", "#F27F6B"), swatch("Terracotta", "#C8623D")],
                    pastelShades: [swatch("Peach", "#F9D5BE"), swatch("Apricot Cream", "#FBD9B5")]),
        ColorFamily(name: "pink", keywords: ["pink", "fuchsia", "magenta", "rose", "blush"],
                    matches: { h, s, v in ((300..<345).contains(h) && v >= 0.6) || ((h >= 345 || h < 15) && v >= 0.8 && s <= 0.55) },
                    standardShades: [swatch("Rose Pink", "#E58FA8"), swatch("Fuchsia", "#C2477F"), swatch("Blush Pink", "#EDB8C4")],
                    pastelShades: [swatch("Pastel Pink", "#F4C2C2"), swatch("Ballet Pink", "#F6D3DA"), swatch("Blush", "#F2CFD3")]),
        ColorFamily(name: "red", keywords: ["red", "merah"],
                    matches: { h, s, v in (h >= 345 || h < 15) && s >= 0.5 && v >= 0.45 },
                    standardShades: [swatch("True Red", "#C1272D"), swatch("Cherry Red", "#B3202E"), swatch("Brick Red", "#A83A32")],
                    pastelShades: [swatch("Pastel Red", "#F2B8B5")]),
        ColorFamily(name: "purple", keywords: ["purple", "ungu", "lilac", "lavender", "violet", "plum"],
                    matches: { h, s, _ in (255..<300).contains(h) && s >= 0.15 },
                    standardShades: [swatch("Plum", "#6E3B6E"), swatch("Violet", "#7B5BA6"), swatch("Lilac", "#B49CCB")],
                    pastelShades: [swatch("Lavender", "#D7C6E8"), swatch("Pastel Lilac", "#DCCBEA")]),
        ColorFamily(name: "brown", keywords: ["brown", "coklat", "cokelat", "mocca", "mocha", "chocolate", "camel"],
                    matches: { h, s, v in (15..<45).contains(h) && s >= 0.25 && v < 0.7 },
                    standardShades: [swatch("Chocolate Brown", "#5C3A2E"), swatch("Camel", "#B07D4F"), swatch("Mocha", "#7B5B4C")],
                    pastelShades: [swatch("Latte", "#D8C3A5")]),
        ColorFamily(name: "beige", keywords: ["beige", "cream", "krem", "nude", "ivory", "khaki"],
                    matches: { h, s, v in (20..<60).contains(h) && (0.06...0.35).contains(s) && v >= 0.7 },
                    standardShades: [swatch("Cream", "#F3E9D7"), swatch("Beige", "#E3D3B8"), swatch("Nude", "#D9B8A0")],
                    pastelShades: [swatch("Cream", "#F3E9D7")]),
        ColorFamily(name: "gold", keywords: ["gold", "emas", "golden"],
                    matches: { h, s, v in (38..<58).contains(h) && (0.4...0.85).contains(s) && (0.55...0.92).contains(v) },
                    standardShades: [swatch("Gold", "#C9A44C"), swatch("Antique Gold", "#B08D3C")],
                    pastelShades: [swatch("Champagne", "#EBD9B4")]),
        ColorFamily(name: "silver", keywords: ["silver", "perak"],
                    matches: { _, s, v in s < 0.08 && (0.65...0.85).contains(v) },
                    standardShades: [swatch("Silver", "#BFC1C2"), swatch("Metallic Silver", "#A9ABAE")],
                    pastelShades: [swatch("Pearl Grey", "#DADBDD")]),
        ColorFamily(name: "black", keywords: ["black", "hitam"],
                    matches: { _, _, v in v < 0.2 },
                    standardShades: [swatch("Black", "#111111"), swatch("Soft Black", "#1E1E1E")],
                    pastelShades: []),
        ColorFamily(name: "white", keywords: ["white", "putih"],
                    matches: { _, s, v in s < 0.08 && v > 0.9 },
                    standardShades: [swatch("White", "#FFFFFF"), swatch("Off White", "#F5F3EE")],
                    pastelShades: [swatch("Off White", "#F5F3EE")]),
        ColorFamily(name: "grey", keywords: ["grey", "gray", "abu", "abuabu"],
                    matches: { _, s, v in s < 0.1 && (0.25...0.9).contains(v) },
                    standardShades: [swatch("Charcoal Grey", "#4A4A4A"), swatch("Heather Grey", "#9E9E9E"), swatch("Light Grey", "#D3D3D3")],
                    pastelShades: [swatch("Pale Grey", "#E2E2E2")])
    ]

    private static let neonShades: [ColorSeason.ColorSwatch] = [
        swatch("Neon Green", "#39FF14"), swatch("Neon Pink", "#FF2E9A"), swatch("Neon Yellow", "#E7FF2E"), swatch("Neon Orange", "#FF6B1A")
    ]
    private static let earthShades: [ColorSeason.ColorSwatch] = [
        swatch("Terracotta", "#C8623D"), swatch("Olive", "#6B6F2E"), swatch("Camel", "#B07D4F"), swatch("Rust", "#A0472B"), swatch("Sand", "#D8C3A5")
    ]

    // MARK: Initializer

    /// - Parameter palette: her season palette; colors in it that fit the request are offered first.
    /// - Returns: `nil` when the dresscode names no color or tone.
    init?(dresscode: String, palette: [ColorSeason.ColorSwatch]) {
        let words = DresscodeText.affirmed(dresscode).lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
        guard !words.isEmpty else { return nil }
        let text = " " + words.joined(separator: " ") + " "

        let tone = Self.toneKeywords.first { entry in entry.words.contains { text.contains(" \($0) ") } }?.tone
        // "biru dongker" and "abu-abu" are read word by word, so "abu abu" is joined first.
        let joined = text.replacingOccurrences(of: " abu abu ", with: " abuabu ")
        var requested: [ColorFamily] = []
        for family in Self.families where family.keywords.contains(where: { joined.contains(" \($0) ") }) {
            // "navy blue" means navy, not every blue.
            if family.name == "blue", requested.contains(where: { $0.name == "navy" }) { continue }
            if family.name == "red", requested.contains(where: { $0.name == "maroon" }) { continue }
            requested.append(family)
        }
        guard tone != nil || !requested.isEmpty else { return nil }

        func hsv(_ hex: String) -> (Double, Double, Double)? {
            let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
            guard clean.count == 6, let value = UInt32(clean, radix: 16) else { return nil }
            let r = Double((value >> 16) & 0xFF) / 255, g = Double((value >> 8) & 0xFF) / 255, b = Double(value & 0xFF) / 255
            let maximum = max(r, g, b), delta = maximum - min(r, g, b)
            let saturation = maximum == 0 ? 0 : delta / maximum
            var hue = 0.0
            if delta > 0 {
                if maximum == r { hue = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
                else if maximum == g { hue = 60 * ((b - r) / delta + 2) }
                else { hue = 60 * ((r - g) / delta + 4) }
            }
            if hue < 0 { hue += 360 }
            return (hue, saturation, maximum)
        }
        func fitsTone(_ h: Double, _ s: Double, _ v: Double) -> Bool {
            switch tone {
            // Soft but clearly colored: beige and cream (low saturation warm tones) don't count as pastel.
            case .pastel?: return v >= 0.8 && (0.15...0.45).contains(s) && !((20...55).contains(h) && s < 0.3)
            case .neon?: return v >= 0.9 && s >= 0.8
            case .earth?: return (10...90).contains(h) && (0.2...0.75).contains(s) && (0.25...0.8).contains(v)
            case nil: return true
            }
        }

        // 1. Her palette colors that fit the request (they suit her best). Palette names like "Titan"
        //    don't say the color, so the requested color word is added for the UI and Image Playground.
        let toneWord: String? = tone == .pastel ? "pastel" : (tone == .neon ? "neon" : nil)
        let fromPalette: [ColorSeason.ColorSwatch] = palette.compactMap { swatch in
            guard let color = hsv(swatch.hex), fitsTone(color.0, color.1, color.2) else { return nil }
            let family = requested.first { $0.matches(color.0, color.1, color.2) }
            guard requested.isEmpty || family != nil else { return nil }
            guard let word = family?.name ?? toneWord, !swatch.name.lowercased().contains(word) else { return swatch }
            return ColorSeason.ColorSwatch(name: "\(swatch.name) \(word.capitalized)", hex: swatch.hex)
        }

        // 2. Standard shades, so there is always a choice.
        let standard: [ColorSeason.ColorSwatch]
        switch (tone, requested.isEmpty) {
        case (.pastel?, true):
            standard = Self.families.flatMap(\.pastelShades)
        case (.pastel?, false):
            standard = requested.flatMap { $0.pastelShades.isEmpty ? $0.standardShades : $0.pastelShades }
        case (.neon?, true):
            standard = Self.neonShades
        case (.earth?, true):
            standard = Self.earthShades
        default:
            standard = requested.flatMap(\.standardShades)
        }

        var seen = Set<String>()
        let combined = (fromPalette + standard).filter { seen.insert($0.hex.uppercased()).inserted }
        guard !combined.isEmpty else { return nil }

        let toneLabel: String?
        switch tone {
        case .pastel?: toneLabel = "pastel"
        case .neon?: toneLabel = "neon"
        case .earth?: toneLabel = "earth tone"
        case nil: toneLabel = nil
        }
        label = ([toneLabel] + requested.map { Optional($0.name) }).compactMap { $0 }.joined(separator: " ")
        swatches = combined
        paletteSwatchCount = Set(fromPalette.map { $0.hex.uppercased() }).count
    }

    /// The color list for the prompt; her palette colors are marked.
    var promptList: String {
        swatches.enumerated().map { index, swatch in
            "\(swatch.name) (\(swatch.hex))" + (index < paletteSwatchCount ? " [suits her]" : "")
        }.joined(separator: ", ")
    }
}

// MARK: - Outfit Palette

extension ColorSeason {
    /// Names of every swatch in every season, so a "suits you" hex can be shown by its name.
    private static let swatchNamesByHex: [String: String] = {
        var names: [String: String] = [:]
        for season in ColorSeason.allCases {
            for swatch in season.allSwatches where names[normalizedHex(swatch.hex)] == nil {
                names[normalizedHex(swatch.hex)] = swatch.name
            }
        }
        return names
    }()

    private static func normalizedHex(_ hex: String) -> String {
        "#" + hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
    }

    /// The colors outfits may use: her neutrals plus the "Color suits you the most" colors shown on her
    /// profile (`wheelHexColors`). The full `palette` also holds colors that aren't on that screen
    /// (for Light Spring, Lemon Drop, Beach Ball, Raw Umber...), which made outfits use colors she was
    /// never shown as hers. Using the same list keeps the app consistent.
    var outfitSwatches: [ColorSwatch] {
        var seen = Set<String>()
        var result: [ColorSwatch] = []
        for swatch in neutralSwatches where seen.insert(Self.normalizedHex(swatch.hex)).inserted {
            result.append(swatch)
        }
        for hex in wheelHexColors {
            let key = Self.normalizedHex(hex)
            guard seen.insert(key).inserted else { continue }
            // Swatch names can mislead an image model ("Mint" for a deep green), so the plain color word is added.
            let plainName = Self.descriptiveName(forHex: key)
            var name = Self.swatchNamesByHex[key] ?? plainName
            if let colorWord = plainName.split(separator: " ").last,
               !Self.plainColorWords.contains(where: { name.lowercased().contains($0) }) {
                name += " \(colorWord)"
            }
            result.append(ColorSwatch(name: name, hex: key))
        }
        return result
    }

    /// Color words that already tell an image model the color. "Mint" isn't one: it reads as pale green.
    private static let plainColorWords = [
        "red", "pink", "coral", "peach", "orange", "apricot", "gold", "yellow", "green", "teal", "blue", "navy",
        "purple", "lavender", "lilac", "brown", "taupe", "gray", "grey", "cream", "ivory", "white", "black",
        "charcoal", "beige", "sand", "rose", "berry", "plum", "olive", "sage"
    ]

    /// A plain color name ("Deep Teal", "Pink", "Taupe") for a hex.
    static func descriptiveName(forHex hex: String) -> String {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard clean.count == 6, let value = UInt32(clean, radix: 16) else { return hex }
        let r = Double((value >> 16) & 0xFF) / 255, g = Double((value >> 8) & 0xFF) / 255, b = Double(value & 0xFF) / 255
        let maximum = max(r, g, b), delta = maximum - min(r, g, b)
        let saturation = maximum == 0 ? 0 : delta / maximum

        if saturation < 0.25 {
            switch maximum {
            case 0.85...: return "Cream"
            case 0.6..<0.85: return "Greige"
            case 0.35..<0.6: return "Taupe"
            default: return "Charcoal"
            }
        }
        var hue = 0.0
        if maximum == r { hue = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
        else if maximum == g { hue = 60 * ((b - r) / delta + 2) }
        else { hue = 60 * ((r - g) / delta + 4) }
        if hue < 0 { hue += 360 }

        let base: String
        switch hue {
        case 345..., ..<15: base = maximum < 0.8 ? "Red" : (saturation < 0.5 ? "Pink" : "Coral")
        case 15..<30: base = maximum < 0.6 ? "Brown" : "Coral"
        case 30..<45: base = maximum < 0.6 ? "Brown" : "Apricot"
        case 45..<65: base = maximum < 0.6 ? "Olive" : "Yellow"
        case 65..<160: base = "Green"
        case 160..<200: base = "Teal"
        case 200..<250: base = "Blue"
        case 250..<290: base = "Purple"
        default: base = "Pink"
        }
        return maximum < 0.45 ? "Deep \(base)" : base
    }
}

// MARK: - Dresscode Negations

/// Splits a dresscode into what it asks for and what it rules out ("no black", "tanpa batik",
/// "jangan warna merah"), so a word after "no" is never read as a requirement.
nonisolated enum DresscodeText {
    private static let negationWords: Set<String> = [
        "no", "not", "without", "except", "avoid", "non", "never",
        "jangan", "bukan", "tanpa", "kecuali", "selain", "dilarang", "hindari", "tidak", "nggak", "gak", "ga", "enggak"
    ]

    /// Clauses split at commas, "and", "but" and similar, so "white, no black" becomes two clauses.
    private static func clauses(_ text: String) -> [String] {
        var lower = " " + text.lowercased() + " "
        // "dress code: putih" talks about the dresscode itself, not about a dress.
        for label in ["dress code", "dresscode", "dress-code"] {
            lower = lower.replacingOccurrences(of: label, with: " ")
        }
        for joiner in [" dan ", " and ", " tapi ", " but ", " serta ", " atau ", " or "] {
            lower = lower.replacingOccurrences(of: joiner, with: ",")
        }
        return lower.components(separatedBy: CharacterSet(charactersIn: ",;./\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func isNegated(_ clause: String) -> Bool {
        clause.components(separatedBy: CharacterSet.letters.inverted).contains { negationWords.contains($0) }
    }

    /// The parts of the dresscode that ask for something.
    static func affirmed(_ text: String) -> String {
        clauses(text).filter { !isNegated($0) }.joined(separator: ", ")
    }

    /// The parts of the dresscode that rule something out.
    static func negated(_ text: String) -> String {
        clauses(text).filter(isNegated).joined(separator: ", ")
    }

    /// What is ruled out, without the negation words ("no black" -> "black").
    static func negatedSubjects(_ text: String) -> String {
        clauses(text).filter(isNegated).map { clause in
            clause.components(separatedBy: CharacterSet.letters.inverted)
                .filter { !$0.isEmpty && !negationWords.contains($0) }
                .joined(separator: " ")
        }.joined(separator: ", ")
    }
}
