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
        "blouse", "shirt", "kemeja", "top", "atasan",
        "bikini", "bikinis", "swimwear", "renang"
    ]

    /// The pieces the dresscode itself asks for ("mini dress" -> a dress, "skirt" -> separates),
    /// or `nil` when it only names a formality or a color.
    init?(dresscode: String) {
        let words = dresscode.lowercased()
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


/// What to wear for common occasions in Indonesia, matched from the occasion title.
///
/// A 3B model often misreads short titles ("holiday", "kondangan", "bukber"), so the matching guide
/// is added to the prompt: how formal the event is, where it happens, good pieces and what to avoid.
/// The pieces are ideas, not a fixed list, and the dresscode always wins over the guide.
nonisolated struct OccasionStyleGuide: Sendable {
    let name: String
    /// Lowercased words or phrases matched as whole words in the occasion title.
    let keywords: [String]
    let formality: String
    let setting: String
    let goodPieces: String
    let avoid: String

    /// The guide as a prompt section.
    var promptText: String {
        """
        OCCASION GUIDE (\(name), ideas to adapt, not a fixed list; the dresscode wins if it differs):
        - Formality: \(formality)
        - Setting: \(setting)
        - Good pieces: \(goodPieces)
        - Avoid: \(avoid)
        """
    }
}

nonisolated enum OccasionStyleBank {

    /// The first guide whose keyword appears in the title (or dresscode), or `nil` for an unknown occasion.
    /// More specific guides are listed first ("wedding party" before "party").
    static func guide(forTitle title: String, dresscode: String = "") -> OccasionStyleGuide? {
        let text = " " + normalized(title + " " + dresscode) + " "
        return guides.first { guide in
            guide.keywords.contains { text.contains(" \($0) ") }
        }
    }

    /// Lowercased letters and digits, one space between words.
    private static func normalized(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Guides

    static let guides: [OccasionStyleGuide] = [
        OccasionStyleGuide(
            name: "Wedding guest",
            keywords: ["wedding", "weddings", "kondangan", "nikahan", "pernikahan", "resepsi", "akad", "engagement", "lamaran", "tunangan", "sangjit"],
            formality: "Semi-formal to formal, polished and festive.",
            setting: "Indoor ballroom or garden venue, often in the evening, standing, eating and taking photos.",
            goodPieces: "Midi or maxi dresses in satin, chiffon or crepe; a modern kebaya top with a satin or pleated skirt; elegant wide-leg pants with a draped blouse; a light outer for the ceremony.",
            avoid: "White or ivory as the main color, denim, casual tees, sneakers-style looks, very short or very revealing pieces."
        ),
        OccasionStyleGuide(
            name: "Graduation",
            keywords: ["graduation", "wisuda", "yudisium"],
            formality: "Smart to semi-formal, neat and photo-ready.",
            setting: "Campus hall, long sitting, then outdoor photos in the heat.",
            goodPieces: "A modern kebaya or fitted blouse with a pleated or A-line midi skirt, a knee to midi dress, light tailored pieces in breathable fabric.",
            avoid: "Heavy layers, very short skirts, casual denim, anything that wrinkles badly."
        ),
        OccasionStyleGuide(
            name: "Job interview",
            keywords: ["interview", "wawancara"],
            formality: "Business formal to smart, confident and clean.",
            setting: "Office, sitting across a table.",
            goodPieces: "A light blazer with a simple blouse and straight or wide-leg trousers, a sheath or shirt dress, a knee-length skirt.",
            avoid: "Loud prints, sheer or revealing pieces, very casual pieces, mini lengths."
        ),
        OccasionStyleGuide(
            name: "Eid or family gathering",
            keywords: ["lebaran", "eid", "idul fitri", "halal bihalal", "silaturahmi", "bukber", "buka bersama", "family", "keluarga", "arisan"],
            formality: "Modest smart casual to semi-formal, festive.",
            setting: "Family homes or restaurants, sitting, eating and visiting.",
            goodPieces: "A modern tunic or kurung-inspired set, a flowy maxi dress with sleeves, a long blouse with wide-leg pants or a pleated skirt.",
            avoid: "Short, tight or revealing pieces, party clubwear."
        ),
        OccasionStyleGuide(
            name: "Office or meeting",
            keywords: ["office", "kantor", "work", "kerja", "meeting", "presentation", "presentasi", "internship", "magang", "conference", "seminar"],
            formality: "Business casual.",
            setting: "Air-conditioned office, sitting most of the day.",
            goodPieces: "Wide-leg or straight trousers, midi skirts, shirts and blouses with a modern detail, knit tops, a light blazer or cardigan.",
            avoid: "Very short or revealing pieces, party fabrics, distressed denim."
        ),
        OccasionStyleGuide(
            name: "Date",
            keywords: ["date", "dating", "kencan", "anniversary", "dinner", "candle light"],
            formality: "Smart casual, a little romantic and flattering.",
            setting: "Cafe or restaurant, usually in the evening, sitting and talking.",
            goodPieces: "A satin slip or wrap dress, a fitted top with a flowy or slit skirt, a soft blouse with tailored pants, a mini or midi dress with a light outer.",
            avoid: "Office-stiff suits, gym or very casual wear, overly formal gowns."
        ),
        OccasionStyleGuide(
            name: "Night out or party",
            keywords: ["party", "parties", "night out", "girls night", "clubbing", "club", "bar", "pesta", "dugem", "prom", "gala"],
            formality: "Dressy, going-out style.",
            setting: "Bar, club, rooftop or party venue at night, standing and dancing.",
            goodPieces: "A mini or bodycon dress, a satin or shimmer top with leather-look or tailored pants, a corset or halter top with a mini skirt, a cropped jacket.",
            avoid: "Daytime office looks, loose tunics, flat basic tees, long shapeless pieces."
        ),
        OccasionStyleGuide(
            name: "Birthday",
            keywords: ["birthday", "ultah", "ulang tahun", "bday"],
            formality: "Smart casual to dressy, festive.",
            setting: "Restaurant, cafe or home party, lots of photos.",
            goodPieces: "A cute mini or midi dress, a statement top with a skirt or tailored pants, a two-piece set.",
            avoid: "Plain office wear, very casual loungewear."
        ),
        OccasionStyleGuide(
            name: "Holiday or beach trip",
            keywords: ["holiday", "holidays", "vacation", "liburan", "beach", "pantai", "bali", "lombok", "labuan bajo", "resort", "staycation", "pool",
                       "swim", "swimming", "renang", "bikini", "swimsuit", "swimwear", "berenang"],
            formality: "Casual, relaxed and photo-ready.",
            setting: "Outdoors in hot sun, beach, resort or walking around.",
            goodPieces: "A linen or cotton sundress, a crochet or linen top with shorts or a flowy skirt, a matching linen set, an open shirt worn as a light cover-up. When she will swim or the user asks for swimwear: a bikini (bikini top as \"Top\", bikini bottom as \"Bottom\") or a one-piece swimsuit (as \"Dress\"), with a sheer cover-up, sarong or linen shirt as the optional outer.",
            avoid: "Dark heavy fabrics, formal tailoring, tight synthetic pieces, heavy outers."
        ),
        OccasionStyleGuide(
            name: "Travel",
            keywords: ["travel", "trip", "airport", "flight", "pesawat", "road trip", "mudik"],
            formality: "Casual and comfortable but put-together.",
            setting: "Airport, car or train, long sitting and walking.",
            goodPieces: "A knit set, wide-leg pants with a fitted top, a relaxed shirt dress, a light jacket for air conditioning.",
            avoid: "Tight or stiff pieces, delicate fabrics, very short skirts."
        ),
        OccasionStyleGuide(
            name: "Brunch or hangout",
            keywords: ["brunch", "hangout", "hang out", "nongkrong", "ngopi", "coffee", "cafe", "mall", "jalan", "shopping", "picnic", "piknik"],
            formality: "Casual to smart casual, trendy.",
            setting: "Cafe, mall or park during the day.",
            goodPieces: "A cute top with wide-leg jeans or a skort, a casual mini or midi dress, a two-piece set, a cropped cardigan.",
            avoid: "Formal gowns, office suits, heavy fabrics."
        ),
        OccasionStyleGuide(
            name: "Campus",
            keywords: ["campus", "kampus", "kuliah", "class", "kelas", "school", "sekolah", "academy"],
            formality: "Casual, neat and trendy.",
            setting: "Classrooms with air conditioning, walking between buildings.",
            goodPieces: "Jeans or wide-leg pants with a knit or shirt top, a casual midi skirt, an oversized shirt as a light outer.",
            avoid: "Party fabrics, very revealing pieces, formal gowns."
        ),
        OccasionStyleGuide(
            name: "Concert or festival",
            keywords: ["concert", "konser", "festival", "gig", "music"],
            formality: "Casual, expressive and comfortable.",
            setting: "Crowded venue or open field, standing and jumping for hours.",
            goodPieces: "A graphic or cropped top with denim shorts or cargo pants, a mini skirt with a fitted top, a light shirt tied at the waist.",
            avoid: "Long flowing gowns, delicate fabrics, formal tailoring."
        ),
        OccasionStyleGuide(
            name: "Religious service",
            keywords: ["church", "gereja", "ibadah", "misa", "mass", "sunday service", "pengajian", "mosque", "masjid"],
            formality: "Modest smart casual.",
            setting: "Indoor service, sitting and standing.",
            goodPieces: "A midi or maxi dress with sleeves, a blouse with a midi skirt or wide-leg pants, a light cardigan.",
            avoid: "Short, tight, sheer or low-cut pieces."
        ),
        OccasionStyleGuide(
            name: "Christmas or new year",
            keywords: ["christmas", "natal", "xmas", "new year", "tahun baru", "nye", "imlek", "chinese new year", "cny"],
            formality: "Smart casual to dressy, festive.",
            setting: "Family dinner or party, lots of photos.",
            goodPieces: "A satin or velvet-look dress, a festive top with tailored pants, a modern cheongsam-inspired dress for Imlek.",
            avoid: "Plain office wear, gym or loungewear."
        ),
        OccasionStyleGuide(
            name: "Funeral or condolence visit",
            keywords: ["funeral", "melayat", "pemakaman", "condolence", "duka"],
            formality: "Modest and respectful.",
            setting: "Funeral home or family home.",
            goodPieces: "Simple long-sleeve blouses, midi or maxi skirts, straight trousers, a plain dress, in black, white or dark muted colors.",
            avoid: "Bright colors, prints, sparkly fabrics, short or revealing pieces."
        ),
        OccasionStyleGuide(
            name: "Workout or sport",
            keywords: ["gym", "workout", "olahraga", "yoga", "pilates", "run", "lari", "jogging", "tennis", "padel"],
            formality: "Activewear.",
            setting: "Gym, studio or court, moving and sweating.",
            goodPieces: "A sports top or fitted tee with leggings, bike shorts or a tennis skirt, a light zip jacket.",
            avoid: "Woven fabrics, dresses, anything that restricts movement."
        ),
        OccasionStyleGuide(
            name: "Photoshoot",
            keywords: ["photoshoot", "photo shoot", "foto", "prewedding", "pre wedding"],
            formality: "Depends on the theme, styled and camera-ready.",
            setting: "Studio or outdoor location.",
            goodPieces: "Pieces with a clear silhouette and texture, a statement dress, a coordinated set.",
            avoid: "Busy small prints, logos, wrinkled fabrics."
        )
    ]
}
