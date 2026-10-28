//
//  ColorSeason.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import Foundation

/// 12 Personal Color Seasons classification system.
///
/// Combines the 4 primary seasonal families (Spring, Summer, Autumn, Winter) with
/// 3 tonal dimensions (Hue, Value, Chroma) to determine optimal skin-tone-flattering color palettes.
public enum ColorSeason: String, Codable, CaseIterable, Identifiable, Sendable {
    case brightSpring = "Bright Spring"
    case trueSpring = "True Spring"
    case lightSpring = "Light Spring"
    case lightSummer = "Light Summer"
    case trueSummer = "True Summer"
    case softSummer = "Soft Summer"
    case softAutumn = "Soft Autumn"
    case trueAutumn = "True Autumn"
    case darkAutumn = "Dark Autumn"
    case darkWinter = "Dark Winter"
    case trueWinter = "True Winter"
    case brightWinter = "Bright Winter"

    public var id: String { rawValue }

    // MARK: - Swatch Model

    public struct ColorSwatch: Sendable, Hashable, Identifiable, Codable {
        public var id: String { hex }
        public let name: String
        public let pantoneCode: String
        public let hex: String

        public init(name: String, pantoneCode: String, hex: String) {
            self.name = name
            self.pantoneCode = pantoneCode
            self.hex = hex
        }
    }

    // MARK: - Tonal Coordinates Model

    /// The 3 tonal dimensions (Hue, Value, Chroma) defining the color season.
    public struct TonalCoordinates: Sendable, Hashable, Codable {
        public let hue: String
        public let value: String
        public let chroma: String

        public init(hue: String, value: String, chroma: String) {
            self.hue = hue
            self.value = value
            self.chroma = chroma
        }
    }

    // MARK: - Season Attributes & Ruleset

    /// Definition and prominent visual features.
    public var definition: String {
        switch self {
        case .brightSpring:
            return "Bright Spring is the combination of bright and warm. The most prominent characteristic of Bright Springs is the clearness of their features, which gives them a bright, luminous, and fresh appearance."
        case .trueSpring:
            return "True Spring is the combination of warm and bright. It is the original Spring season, characterized by a sunny, glowing appearance with no trace of coolness."
        case .lightSpring:
            return "Light Spring is the combination of light and warm. Flowing from Spring into Summer, it combines Spring warmth with Summer delicacy, featuring a colorful palette reminiscent of a box of sweets."
        case .lightSummer:
            return "Light Summer is the combination of light and cool. Flowing from Spring into Summer, it features neutral-cool, delicate, ice-cream-like colors."
        case .trueSummer:
            return "True Summer is the combination of cool and muted. As the coolest season of the Summer family, features lack any warmth and are overlaid with a gentle, watery coolness."
        case .softSummer:
            return "Soft Summer is the combination of muted and cool. Flowing from Summer into Autumn, features are gently greyed out, giving a blended, understated appearance."
        case .softAutumn:
            return "Soft Autumn is the combination of muted and warm. Flowing from Summer into Autumn, features are soft, greyed/walnut-tinted, understated, and gentle."
        case .trueAutumn:
            return "True Autumn is the combination of warm and muted. Being the warmest season of the Autumn family, True Autumn features comprise rich, earthy foliage-like colors."
        case .darkAutumn:
            return "Dark Autumn is the combination of dark and warm. Flowing from Autumn into Winter, it combines deep, bronzy warmth with mysterious dark depth."
        case .darkWinter:
            return "Dark Winter is the combination of dark and cool. Flowing from Autumn into Winter, it features prominent dark features set against lighter skin, creating deep, frosty intensity."
        case .trueWinter:
            return "True Winter is the combination of cool and bright. As the coolest Winter sub-season, features have a frost-like coolness and striking, brilliant contrast."
        case .brightWinter:
            return "Bright Winter is the combination of bright and cool. Flowing from Winter into Spring, it features clear, striking, highly saturated features with a frosted brilliance."
        }
    }

    /// Primary & secondary tonal aspects (Act).
    public var act: String {
        switch self {
        case .brightSpring:
            return "Primary aspect is Bright (highly saturated, clear, no greyness), secondary aspect is Warm (neutral-warm undertones). Features have a very high contrast between skin, hair, and eyes, with sparkling or vivid eyes."
        case .trueSpring:
            return "Primary aspect is Warm (pure warm golden/yellow undertones), secondary aspect is Bright (saturated, fresh, vibrant). Features have medium contrast with a luminous, radiant warmth."
        case .lightSpring:
            return "Primary aspect is Light (absence of dark depth in hair, eyes, and skin), secondary aspect is Warm (neutral-warm undertones). Overall contrast between features is low."
        case .lightSummer:
            return "Primary aspect is Light (light features with low contrast), secondary aspect is Cool (neutral-cool). Contrast between hair, eyes, and skin is low."
        case .trueSummer:
            return "Primary aspect is Cool (pure cool undertones), secondary aspect is Muted (softened, greyed out). Features are gently contrasted without harshness."
        case .softSummer:
            return "Primary aspect is Muted (high content of grey pigments, low feature contrast), secondary aspect is Cool (neutral-cool)."
        case .softAutumn:
            return "Primary aspect is Muted (low contrast, blended features), secondary aspect is Warm (neutral-warm undertones)."
        case .trueAutumn:
            return "Primary aspect is Warm (pure warm golden/bronze undertones), secondary aspect is Muted (rich, earthy, non-vibrant). Contrast level is medium."
        case .darkAutumn:
            return "Primary aspect is Dark (deep hair, eyes, and high contrast with skin), secondary aspect is Warm (neutral-warm undertones)."
        case .darkWinter:
            return "Primary aspect is Dark (deep hair/eyes, high contrast), secondary aspect is Cool (neutral-cool undertones)."
        case .trueWinter:
            return "Primary aspect is Cool (pure cool blue undertones), secondary aspect is Bright (vibrant, clear, highly contrasted)."
        case .brightWinter:
            return "Primary aspect is Bright (extreme saturation and clarity, high contrast), secondary aspect is Cool (neutral-cool undertones)."
        }
    }

    /// Color styling combination guidelines.
    public var colorCombinationRules: String {
        switch self {
        case .brightSpring:
            return "High hue contrast is key. Combine contrasting colors across the color wheel (e.g., pink and green), or pair dark neutrals with bright accent colors. Always include at least one bright color in every outfit; avoid neutrals-only or desaturated monochromatic looks."
        case .trueSpring:
            return "Pair warm colors together in tonal or complementary mixes; combine bright warm shades with light warm neutrals (e.g., camel, warm ivory). Avoid cool or icy color contrast."
        case .lightSpring:
            return "Low-to-medium contrast, delicate or tonal combinations; pair light colorful tints together or with light warm neutrals (ivory, light beige)."
        case .lightSummer:
            return "Gentle, low-contrast combinations; pair light cool pastels together or combine them with soft light neutrals (soft white, light ash grey, heather blue)."
        case .trueSummer:
            return "Cool, gentle, tonal combinations; pair cool medium tones with soft cool neutrals (slate, soft navy, cool white); avoid high-contrast warm pairings."
        case .softSummer:
            return "Monochromatic, blended, low-contrast outfits; pair muted cool tones with soft neutrals (grey, taupe, soft rose); subtle tone-on-tone dressing."
        case .softAutumn:
            return "Tone-on-tone, low-contrast earthy combinations; blend soft warm shades together (e.g., olive and wheat, dusty rose and terracotta)."
        case .trueAutumn:
            return "Warm earthy combinations; combine rich warm tones (mustard, rust, olive) with rich warm neutrals (chocolate, camel, bronze)."
        case .darkAutumn:
            return "Deep, high-value contrast combinations; pair rich dark shades with warm light neutrals (cream, warm bronze); spice-inspired contrasts."
        case .darkWinter:
            return "High-contrast combinations; pair deep dark neutrals (black, deep navy) with light icy accents or vivid cool jewels (emerald, magenta)."
        case .trueWinter:
            return "Stark, high value & hue contrast; pair icy light shades directly with dark/vibrant cool shades (e.g., stark white & black, icy blue & royal blue)."
        case .brightWinter:
            return "High-contrast combinations; pair bright cool colors with black, white, or dark navy, or combine vivid complementary colors (magenta and turquoise)."
        }
    }

    /// Colors that disharmonize with this season.
    public var colorsToAvoid: String {
        switch self {
        case .brightSpring:
            return "Muted, dusty, or desaturated colors (e.g., dusty blue, muddy brown) and very cool, icy shades (e.g., icy blue, cool grey)."
        case .trueSpring:
            return "Cool colors (fuchsia, icy blue, silver), muted/ashy tones (cool grey, taupe, dusty rose), and stark black or harsh cool white."
        case .lightSpring:
            return "Very dark colors (black, deep navy, dark chocolate), cool icy shades, and greyish muted tones."
        case .lightSummer:
            return "Dark colors (black, deep burgundy, dark chocolate), warm golden colors (orange, mustard, copper), and heavy saturated shades."
        case .trueSummer:
            return "Warm colors (orange, yellow-gold, coral, rust) and bright/vibrant colors (neon green, electric blue)."
        case .softSummer:
            return "Highly saturated, bright colors (electric pink, vivid yellow) and stark black or bright warm orange."
        case .softAutumn:
            return "Bright, vibrant colors (magenta, neon green, royal blue) and stark cool colors (icy blue, pure black, bright white)."
        case .trueAutumn:
            return "Cool colors (icy pink, bright royal blue, silver) and stark black or pure cool white."
        case .darkAutumn:
            return "Light pastels, cool icy colors (icy blue, silver), and muted greyish tones (lavender, dusty pink)."
        case .darkWinter:
            return "Warm golden colors (orange, mustard, rust), earthy muted tones, and pale warm pastels."
        case .trueWinter:
            return "Warm colors (orange, golden yellow, peach, rust, brown) and muted/muddy shades (khaki, taupe)."
        case .brightWinter:
            return "Muted, dusty, desaturated colors (dusty rose, sage green) and warm golden/earthy shades (orange, mustard, golden brown)."
        }
    }

    /// Tonal dimensions (Hue, Value, Chroma) for this season.
    public var tonalCoordinates: TonalCoordinates {
        switch self {
        case .brightSpring:
            return TonalCoordinates(
                hue: "Warm (neutral-warm with yellow undertones).",
                value: "Medium leaning light (ranges from light to medium-dark, clustering around middle-light).",
                chroma: "High (intensely bright, vibrant, and clear)."
            )
        case .trueSpring:
            return TonalCoordinates(
                hue: "Warm (pure warm, golden-yellow undertones with no blue).",
                value: "Medium-light (luminous, sunny depth).",
                chroma: "High (saturated, fresh, coloring-pencil vibrancy)."
            )
        case .lightSpring:
            return TonalCoordinates(
                hue: "Warm (neutral-warm, light golden undertones).",
                value: "Light (high on the value scale, no dark depth).",
                chroma: "Medium-bright (clear and colourful tints without being greyed out)."
            )
        case .lightSummer:
            return TonalCoordinates(
                hue: "Cool (neutral-cool, blue undertones).",
                value: "Light (high value, delicate tints).",
                chroma: "Medium-muted / soft-bright (delicate ice-cream tones)."
            )
        case .trueSummer:
            return TonalCoordinates(
                hue: "Cool (pure cool, blue undertones).",
                value: "Medium-light to Medium (soft water-like depth).",
                chroma: "Medium-low / Muted (toned down, greyed out)."
            )
        case .softSummer:
            return TonalCoordinates(
                hue: "Cool (neutral-cool, greyed blue undertones).",
                value: "Medium (mid-range value, balanced depth).",
                chroma: "Low (extremely muted, greyed out)."
            )
        case .softAutumn:
            return TonalCoordinates(
                hue: "Warm (neutral-warm, olive/walnut undertones).",
                value: "Medium (rich yet softened value).",
                chroma: "Low (extremely muted, desaturated)."
            )
        case .trueAutumn:
            return TonalCoordinates(
                hue: "Warm (pure warm, golden-red undertones).",
                value: "Medium to Dark (deep foliage richness).",
                chroma: "Medium-low / Muted (rich, non-bright saturation)."
            )
        case .darkAutumn:
            return TonalCoordinates(
                hue: "Warm (neutral-warm, golden-bronze undertones).",
                value: "Dark (deep value scale).",
                chroma: "Medium (rich, slightly brightened deep tones)."
            )
        case .darkWinter:
            return TonalCoordinates(
                hue: "Cool (neutral-cool, blue undertones).",
                value: "Dark (low on the value scale, deep value).",
                chroma: "Medium-high (intense, brilliant dark shades)."
            )
        case .trueWinter:
            return TonalCoordinates(
                hue: "Cool (pure cool, blue undertones).",
                value: "Dark & Light extremes (high value contrast range).",
                chroma: "High (intensely bright, clear, icy)."
            )
        case .brightWinter:
            return TonalCoordinates(
                hue: "Cool (neutral-cool, icy blue undertones).",
                value: "Medium to Dark (with icy light support).",
                chroma: "High (maximum vibrancy and saturation)."
            )
        }
    }

    /// Hue dimension description.
    public var hue: String {
        tonalCoordinates.hue
    }

    /// Value dimension description.
    public var value: String {
        tonalCoordinates.value
    }

    /// Chroma dimension description.
    public var chroma: String {
        tonalCoordinates.chroma
    }

    // MARK: - Color Palettes

    /// Curated 35 Pantone TCX color swatches for this season.
    public var palette: [ColorSwatch] {
        switch self {
        case .brightSpring:
            return [
                ColorSwatch(name: "Snow White", pantoneCode: "11-0602 TCX", hex: "#F2F0EB"),
                ColorSwatch(name: "Vanilla Ice", pantoneCode: "11-0104 TCX", hex: "#F0EADA"),
                ColorSwatch(name: "Rutabaga", pantoneCode: "12-0806 TCX", hex: "#ECDDBE"),
                ColorSwatch(name: "Summer Sand", pantoneCode: "12-0908 TCX", hex: "#D6CBBA"),
                ColorSwatch(name: "Oatmeal", pantoneCode: "13-0401 TCX", hex: "#CBC3B4"),
                ColorSwatch(name: "Silver Lining", pantoneCode: "14-4501 TCX", hex: "#BDB6AB"),
                ColorSwatch(name: "Brindle", pantoneCode: "18-1110 TCX", hex: "#82776B"),
                ColorSwatch(name: "Chimera", pantoneCode: "19-0406 TCX", hex: "#4D4C47"),
                ColorSwatch(name: "Imperial Blue", pantoneCode: "19-4245 TCX", hex: "#005A92"),
                ColorSwatch(name: "Déja Vu Blue", pantoneCode: "19-4041 TCX", hex: "#2E5283"),
                ColorSwatch(name: "Aspen Gold", pantoneCode: "13-0850 TCX", hex: "#FFD662"),
                ColorSwatch(name: "Pale Marigold", pantoneCode: "13-0945 TCX", hex: "#FFC66E"),
                ColorSwatch(name: "Artisan’s Gold", pantoneCode: "15-1049 TCX", hex: "#F2AB46"),
                ColorSwatch(name: "Buckskin", pantoneCode: "16-1342 TCX", hex: "#D18E54"),
                ColorSwatch(name: "Aurora Red", pantoneCode: "18-1550 TCX", hex: "#B93A32"),
                ColorSwatch(name: "Orchid Pink", pantoneCode: "13-2010 TCX", hex: "#F3BBCA"),
                ColorSwatch(name: "Geranium Pink", pantoneCode: "15-1922 TCX", hex: "#F6909D"),
                ColorSwatch(name: "Hot Pink", pantoneCode: "17-1937 TCX", hex: "#E55982"),
                ColorSwatch(name: "Pink Lemonade", pantoneCode: "16-1735 TCX", hex: "#EE6D8A"),
                ColorSwatch(name: "Geranium", pantoneCode: "17-1753 TCX", hex: "#DA3D58"),
                ColorSwatch(name: "Fuchsia Pink", pantoneCode: "15-2718 TCX", hex: "#DF88B7"),
                ColorSwatch(name: "Raspberry Rose", pantoneCode: "18-2333 TCX", hex: "#CC4385"),
                ColorSwatch(name: "Raspberry Radiance", pantoneCode: "19-2432 TCX", hex: "#802A50"),
                ColorSwatch(name: "Nouveau Navy", pantoneCode: "19-4054 TCX", hex: "#3A5589"),
                ColorSwatch(name: "Mazarine Blue", pantoneCode: "19-3864 TCX", hex: "#273C76"),
                ColorSwatch(name: "Blue Radiance", pantoneCode: "14-4816 TCX", hex: "#58C9D4"),
                ColorSwatch(name: "Peacock Blue", pantoneCode: "16-4728 TCX", hex: "#00A0B0"),
                ColorSwatch(name: "Tropical Green", pantoneCode: "18-4930 TCX", hex: "#008786"),
                ColorSwatch(name: "Bachelor Button", pantoneCode: "14-4522 TCX", hex: "#4ABBD5"),
                ColorSwatch(name: "Mosaic Blue", pantoneCode: "18-4528 TCX", hex: "#00758F"),
                ColorSwatch(name: "Sharp Green", pantoneCode: "13-0535 TCX", hex: "#C6E67A"),
                ColorSwatch(name: "Macaw Green", pantoneCode: "16-0230 TCX", hex: "#9BB53E"),
                ColorSwatch(name: "Online Lime", pantoneCode: "17-0145 TCX", hex: "#44883C"),
                ColorSwatch(name: "Rolling Hills", pantoneCode: "18-6028 TCX", hex: "#227949"),
                ColorSwatch(name: "Formal Garden", pantoneCode: "19-6350 TCX", hex: "#1F5129")
            ]
        case .trueSpring:
            return [
                ColorSwatch(name: "Vanilla", pantoneCode: "12-0712 TCX", hex: "#F3E5C8"),
                ColorSwatch(name: "Sun Kiss", pantoneCode: "12-0807 TCX", hex: "#EBDBC3"),
                ColorSwatch(name: "Golden Fleece", pantoneCode: "12-0822 TCX", hex: "#F2D1A0"),
                ColorSwatch(name: "Jojoba", pantoneCode: "14-0835 TCX", hex: "#DDBF7E"),
                ColorSwatch(name: "Desert Mist", pantoneCode: "14-1127 TCX", hex: "#E0B589"),
                ColorSwatch(name: "Golden Mist", pantoneCode: "13-0624 TCX", hex: "#D5CD94"),
                ColorSwatch(name: "Moonstone", pantoneCode: "14-1026 TCX", hex: "#BEA987"),
                ColorSwatch(name: "Pale Gold", pantoneCode: "15-0927 TCX", hex: "#BD9865"),
                ColorSwatch(name: "Dachshund", pantoneCode: "18-1033 TCX", hex: "#704F3B"),
                ColorSwatch(name: "Demitasse", pantoneCode: "19-0712 TCX", hex: "#40342B"),
                ColorSwatch(name: "Impala", pantoneCode: "13-1025 TCX", hex: "#F8CE97"),
                ColorSwatch(name: "Sunshine", pantoneCode: "12-0727 TCX", hex: "#FAD055"),
                ColorSwatch(name: "Yarrow", pantoneCode: "12-0758 TCX", hex: "#F6C345"),
                ColorSwatch(name: "Mimosa", pantoneCode: "14-0848 TCX", hex: "#F0A83B"),
                ColorSwatch(name: "Amber", pantoneCode: "14-1045 TCX", hex: "#ECA349"),
                ColorSwatch(name: "Burnt Coral", pantoneCode: "16-1529 TCX", hex: "#E9897E"),
                ColorSwatch(name: "Emberglow", pantoneCode: "17-1547 TCX", hex: "#EA6759"),
                ColorSwatch(name: "Cayenne", pantoneCode: "18-1651 TCX", hex: "#E04951"),
                ColorSwatch(name: "Georgia Peach", pantoneCode: "16-1641 TCX", hex: "#F97272"),
                ColorSwatch(name: "Hibiscus", pantoneCode: "18-1762 TCX", hex: "#DD3848"),
                ColorSwatch(name: "Windsurfer", pantoneCode: "15-4031 TCX", hex: "#99B9DD"),
                ColorSwatch(name: "Della Robbia Blue", pantoneCode: "16-4020 TCX", hex: "#7DA3C6"),
                ColorSwatch(name: "Marina", pantoneCode: "17-4041 TCX", hex: "#4F84C4"),
                ColorSwatch(name: "Directoire Blue", pantoneCode: "18-4244 TCX", hex: "#0061A3"),
                ColorSwatch(name: "True Blue", pantoneCode: "19-4057 TCX", hex: "#1E3F66"),
                ColorSwatch(name: "Spring Bouquet", pantoneCode: "14-6340 TCX", hex: "#70C68E"),
                ColorSwatch(name: "Irish Green", pantoneCode: "15-6340 TCX", hex: "#3FAD67"),
                ColorSwatch(name: "Biscay Green", pantoneCode: "15-5718 TCX", hex: "#55C6A9"),
                ColorSwatch(name: "Holly Green", pantoneCode: "16-5932 TCX", hex: "#199B65"),
                ColorSwatch(name: "Bosphorus", pantoneCode: "18-5633 TCX", hex: "#007558"),
                ColorSwatch(name: "Daiquiri Green", pantoneCode: "12-0435 TCX", hex: "#C9E37A"),
                ColorSwatch(name: "Bright Chartreuse", pantoneCode: "14-0445 TCX", hex: "#B3CE50"),
                ColorSwatch(name: "Titanite", pantoneCode: "16-0229 TCX", hex: "#9AA639"),
                ColorSwatch(name: "Salted Lime", pantoneCode: "17-0232 TCX", hex: "#687C39"),
                ColorSwatch(name: "First Tee", pantoneCode: "18-6031 TCX", hex: "#156D3F")
            ]
        case .lightSpring:
            return [
                ColorSwatch(name: "Shortbread", pantoneCode: "12-0710 TCX", hex: "#F1DEC7"),
                ColorSwatch(name: "Whitecap Gray", pantoneCode: "12-0304 TCX", hex: "#E3DACB"),
                ColorSwatch(name: "Alabaster Gleam", pantoneCode: "12-0812 TCX", hex: "#F4E2C7"),
                ColorSwatch(name: "Lamb's Wool", pantoneCode: "12-0910 TCX", hex: "#E8D0AE"),
                ColorSwatch(name: "Boulder", pantoneCode: "14-1110 TCX", hex: "#D1BA9C"),
                ColorSwatch(name: "Ancient Scroll", pantoneCode: "13-0404 TCX", hex: "#CBC3B7"),
                ColorSwatch(name: "Agate Gray", pantoneCode: "15-6307 TCX", hex: "#B3B1A0"),
                ColorSwatch(name: "Driftwood", pantoneCode: "18-1210 TCX", hex: "#887B75"),
                ColorSwatch(name: "Bungee Cord", pantoneCode: "18-0513 TCX", hex: "#696256"),
                ColorSwatch(name: "Chocolate Chip", pantoneCode: "19-0809 TCX", hex: "#5A4E44"),
                ColorSwatch(name: "Lemon Verbena", pantoneCode: "12-0742 TCX", hex: "#F4E87C"),
                ColorSwatch(name: "Lemon Drop", pantoneCode: "12-0736 TCX", hex: "#FDCE5B"),
                ColorSwatch(name: "Beach Ball", pantoneCode: "14-0849 TCX", hex: "#F2B94A"),
                ColorSwatch(name: "Golden Haze", pantoneCode: "12-0826 TCX", hex: "#F8D397"),
                ColorSwatch(name: "Sunset Gold", pantoneCode: "13-0940 TCX", hex: "#F7BA5B"),
                ColorSwatch(name: "Strawberry Cream", pantoneCode: "13-2005 TCX", hex: "#F4C4C2"),
                ColorSwatch(name: "Blossom", pantoneCode: "14-1513 TCX", hex: "#F4B3B2"),
                ColorSwatch(name: "Candlelight Peach", pantoneCode: "15-1621 TCX", hex: "#F89B93"),
                ColorSwatch(name: "Peach Blossom", pantoneCode: "16-1626 TCX", hex: "#DE7879"),
                ColorSwatch(name: "Sun Kissed Coral", pantoneCode: "17-1736 TCX", hex: "#EA5C6B"),
                ColorSwatch(name: "Lavender", pantoneCode: "15-3817 TCX", hex: "#A99BC5"),
                ColorSwatch(name: "Bougainvillea", pantoneCode: "17-3725 TCX", hex: "#987EA8"),
                ColorSwatch(name: "Deep Lavender", pantoneCode: "18-3633 TCX", hex: "#734F82"),
                ColorSwatch(name: "Natural", pantoneCode: "16-1310 TCX", hex: "#A8917F"),
                ColorSwatch(name: "Raw Umber", pantoneCode: "17-1422 TCX", hex: "#926E5A"),
                ColorSwatch(name: "Atomizer", pantoneCode: "14-4514 TCX", hex: "#99D1E9"),
                ColorSwatch(name: "Baltic Sea", pantoneCode: "14-4320 TCX", hex: "#78B0D3"),
                ColorSwatch(name: "Blue Topaz", pantoneCode: "14-4310 TCX", hex: "#73B4D3"),
                ColorSwatch(name: "Blue Curacao", pantoneCode: "15-4825 TCX", hex: "#33B1C5"),
                ColorSwatch(name: "Blue Moon", pantoneCode: "17-4328 TCX", hex: "#367D9C"),
                ColorSwatch(name: "Lettuce Green", pantoneCode: "13-0324 TCX", hex: "#BED388"),
                ColorSwatch(name: "Jade Lime", pantoneCode: "14-0232 TCX", hex: "#A1C66F"),
                ColorSwatch(name: "Bud Green", pantoneCode: "15-6442 TCX", hex: "#73A75E"),
                ColorSwatch(name: "Poison Green", pantoneCode: "16-6444 TCX", hex: "#4B9E5A"),
                ColorSwatch(name: "Mint", pantoneCode: "16-5938 TCX", hex: "#009973")
            ]
        case .lightSummer:
            return [
                ColorSwatch(name: "Tofu", pantoneCode: "11-4801 TCX", hex: "#E7E5D9"),
                ColorSwatch(name: "Bone White", pantoneCode: "12-0105 TCX", hex: "#D7D1C1"),
                ColorSwatch(name: "Pelican", pantoneCode: "14-6305 TCX", hex: "#C2BCAC"),
                ColorSwatch(name: "Atmosphere", pantoneCode: "16-1406 TCX", hex: "#A99C94"),
                ColorSwatch(name: "Silent Storm", pantoneCode: "17-1508 TCX", hex: "#827D77"),
                ColorSwatch(name: "Shadow Gray", pantoneCode: "16-1509 TCX", hex: "#BAA5A0"),
                ColorSwatch(name: "Toadstool", pantoneCode: "17-2411 TCX", hex: "#967C7F"),
                ColorSwatch(name: "Peppercorn", pantoneCode: "18-1409 TCX", hex: "#6B5655"),
                ColorSwatch(name: "Plum Truffle", pantoneCode: "18-1506 TCX", hex: "#665858"),
                ColorSwatch(name: "Catawba Grape", pantoneCode: "19-1621 TCX", hex: "#5C3B42"),
                ColorSwatch(name: "Salmon Rose", pantoneCode: "15-1626 TCX", hex: "#FF8E94"),
                ColorSwatch(name: "Dubarry", pantoneCode: "17-1647 TCX", hex: "#F25F67"),
                ColorSwatch(name: "Sugar Coral", pantoneCode: "16-1640 TCX", hex: "#F56C73"),
                ColorSwatch(name: "Paradise Pink", pantoneCode: "17-1755 TCX", hex: "#E4445E"),
                ColorSwatch(name: "Winterberry", pantoneCode: "17-1640 TCX", hex: "#BD3950"),
                ColorSwatch(name: "Candy Pink", pantoneCode: "14-1911 TCX", hex: "#F4B0BD"),
                ColorSwatch(name: "Confetti", pantoneCode: "16-1723 TCX", hex: "#E6798E"),
                ColorSwatch(name: "Sachet Pink", pantoneCode: "15-2216 TCX", hex: "#F28AAD"),
                ColorSwatch(name: "Carmine Rose", pantoneCode: "17-2230 TCX", hex: "#E45B8F"),
                ColorSwatch(name: "Lilac Rose", pantoneCode: "17-2227 TCX", hex: "#BD4376"),
                ColorSwatch(name: "Open Air", pantoneCode: "15-3922 TCX", hex: "#93B2E0"),
                ColorSwatch(name: "Vista Blue", pantoneCode: "15-3930 TCX", hex: "#80A0D3"),
                ColorSwatch(name: "Granada Sky", pantoneCode: "16-4033 TCX", hex: "#5D81BD"),
                ColorSwatch(name: "Star Sapphire", pantoneCode: "18-4041 TCX", hex: "#35619E"),
                ColorSwatch(name: "Turkish Sea", pantoneCode: "19-4053 TCX", hex: "#1A528F"),
                ColorSwatch(name: "Blue Elixir", pantoneCode: "14-4515 TCX", hex: "#8ECBDD"),
                ColorSwatch(name: "River Blue", pantoneCode: "15-4720 TCX", hex: "#38AECC"),
                ColorSwatch(name: "Capri", pantoneCode: "15-4722 TCX", hex: "#44BAC8"),
                ColorSwatch(name: "Baltic", pantoneCode: "16-5123 TCX", hex: "#269E9F"),
                ColorSwatch(name: "Pagoda Blue", pantoneCode: "17-4724 TCX", hex: "#1B7F8E"),
                ColorSwatch(name: "Cabbage", pantoneCode: "13-5714 TCX", hex: "#63DBBF"),
                ColorSwatch(name: "Mint Leaf", pantoneCode: "15-5728 TCX", hex: "#02B694"),
                ColorSwatch(name: "Sea Green", pantoneCode: "16-5421 TCX", hex: "#149B88"),
                ColorSwatch(name: "Simply Green", pantoneCode: "17-5936 TCX", hex: "#179E75"),
                ColorSwatch(name: "Antique Green", pantoneCode: "18-5418 TCX", hex: "#2A685D")
            ]
        case .trueSummer:
            return [
                ColorSwatch(name: "Light Gray", pantoneCode: "12-0404 TCX", hex: "#DAD9CB"),
                ColorSwatch(name: "Perfectly Pale", pantoneCode: "13-0003 TCX", hex: "#D2C9C0"),
                ColorSwatch(name: "Silver Cloud", pantoneCode: "15-4502 TCX", hex: "#BDB7B2"),
                ColorSwatch(name: "Rock Ridge", pantoneCode: "17-0207 TCX", hex: "#96918C"),
                ColorSwatch(name: "Major Brown", pantoneCode: "19-0810 TCX", hex: "#625955"),
                ColorSwatch(name: "Lunar Rock", pantoneCode: "14-4201 TCX", hex: "#C6C6C6"),
                ColorSwatch(name: "Ashes of Roses", pantoneCode: "15-0703 TCX", hex: "#B7ADAD"),
                ColorSwatch(name: "Purple Dove", pantoneCode: "16-1606 TCX", hex: "#A08D94"),
                ColorSwatch(name: "Moonscape", pantoneCode: "17-1708 TCX", hex: "#76636C"),
                ColorSwatch(name: "Forged Iron", pantoneCode: "19-3907 TCX", hex: "#454348"),
                ColorSwatch(name: "Dusty Blue", pantoneCode: "16-4010 TCX", hex: "#8FA0B0"),
                ColorSwatch(name: "Troposphere", pantoneCode: "17-3926 TCX", hex: "#7B8AA4"),
                ColorSwatch(name: "Gray Mist", pantoneCode: "15-4706 TCX", hex: "#9EB5B3"),
                ColorSwatch(name: "Trooper", pantoneCode: "18-4510 TCX", hex: "#6B7F80"),
                ColorSwatch(name: "Turbulence", pantoneCode: "19-4215 TCX", hex: "#4E535A"),
                ColorSwatch(name: "Sea Pink", pantoneCode: "15-1912 TCX", hex: "#D994A7"),
                ColorSwatch(name: "Chateau Rose", pantoneCode: "17-2120 TCX", hex: "#CE7290"),
                ColorSwatch(name: "Bubblegum", pantoneCode: "17-1928 TCX", hex: "#E96F8C"),
                ColorSwatch(name: "Carmine", pantoneCode: "17-1831 TCX", hex: "#BA456B"),
                ColorSwatch(name: "Anemone", pantoneCode: "19-2033 TCX", hex: "#812B49"),
                ColorSwatch(name: "Baby Lavender", pantoneCode: "16-3923 TCX", hex: "#A4ACD4"),
                ColorSwatch(name: "Deep Periwinkle", pantoneCode: "17-3932 TCX", hex: "#7F86BD"),
                ColorSwatch(name: "Corsican Blue", pantoneCode: "18-3828 TCX", hex: "#625D91"),
                ColorSwatch(name: "Orient Blue", pantoneCode: "19-3947 TCX", hex: "#494679"),
                ColorSwatch(name: "Blue Ribbon", pantoneCode: "19-3839 TCX", hex: "#39385F"),
                ColorSwatch(name: "Crystal Seas", pantoneCode: "15-4428 TCX", hex: "#5DB1C9"),
                ColorSwatch(name: "Wave Ride", pantoneCode: "17-4129 TCX", hex: "#3084A6"),
                ColorSwatch(name: "Ipanema", pantoneCode: "15-4716 TCX", hex: "#61B9C0"),
                ColorSwatch(name: "Larkspur", pantoneCode: "17-4421 TCX", hex: "#3E7F90"),
                ColorSwatch(name: "Saxony Blue", pantoneCode: "18-4225 TCX", hex: "#21667D"),
                ColorSwatch(name: "Neptune Green", pantoneCode: "14-6017 TCX", hex: "#81BDA4"),
                ColorSwatch(name: "Ming Green", pantoneCode: "16-5930 TCX", hex: "#39A17E"),
                ColorSwatch(name: "Ivy", pantoneCode: "18-5620 TCX", hex: "#226B62"),
                ColorSwatch(name: "Teal", pantoneCode: "17-4919 TCX", hex: "#4A8588"),
                ColorSwatch(name: "Chesapeake Bay", pantoneCode: "19-4534 TCX", hex: "#15545C")
            ]
        case .softSummer:
            return [
                ColorSwatch(name: "Icicle", pantoneCode: "12-5201 TCX", hex: "#D9DCD1"),
                ColorSwatch(name: "Birch", pantoneCode: "13-0905 TCX", hex: "#DED6C8"),
                ColorSwatch(name: "Chateau Gray", pantoneCode: "15-4503 TCX", hex: "#BDB3AB"),
                ColorSwatch(name: "Satellite", pantoneCode: "16-3800 TCX", hex: "#9A908D"),
                ColorSwatch(name: "Iron", pantoneCode: "18-1306 TCX", hex: "#766762"),
                ColorSwatch(name: "Mirage Gray", pantoneCode: "15-4703 TCX", hex: "#AEB4B2"),
                ColorSwatch(name: "Sedona Sage", pantoneCode: "18-5105 TCX", hex: "#696F6D"),
                ColorSwatch(name: "Gray Quill", pantoneCode: "17-4013 TCX", hex: "#827E80"),
                ColorSwatch(name: "Thunderstorm", pantoneCode: "18-5206 TCX", hex: "#5B585B"),
                ColorSwatch(name: "Raven", pantoneCode: "19-0000 TCX", hex: "#3F3D3D"),
                ColorSwatch(name: "English Rose", pantoneCode: "13-1310 TCX", hex: "#F3C6C3"),
                ColorSwatch(name: "Quartz Pink", pantoneCode: "14-1714 TCX", hex: "#ECA1A7"),
                ColorSwatch(name: "Flowering Ginger", pantoneCode: "15-1915 TCX", hex: "#E6878E"),
                ColorSwatch(name: "Slate Rose", pantoneCode: "18-1635 TCX", hex: "#B45667"),
                ColorSwatch(name: "Earth Red", pantoneCode: "18-1631 TCX", hex: "#93414F"),
                ColorSwatch(name: "Cameo Pink", pantoneCode: "14-2307 TCX", hex: "#D9A7B5"),
                ColorSwatch(name: "Wild Rose", pantoneCode: "16-1715 TCX", hex: "#C98095"),
                ColorSwatch(name: "Mesa Rose", pantoneCode: "17-1609 TCX", hex: "#A96D7C"),
                ColorSwatch(name: "Hawthorn Rose", pantoneCode: "18-1718 TCX", hex: "#854A5D"),
                ColorSwatch(name: "Blackberry Wine", pantoneCode: "19-2816 TCX", hex: "#4C3044"),
                ColorSwatch(name: "Icelandic Blue", pantoneCode: "15-3908 TCX", hex: "#A9ADC2"),
                ColorSwatch(name: "Purple Impression", pantoneCode: "17-3919 TCX", hex: "#858FB1"),
                ColorSwatch(name: "Lavender Violet", pantoneCode: "17-3924 TCX", hex: "#777CA6"),
                ColorSwatch(name: "Heron", pantoneCode: "18-3817 TCX", hex: "#615F7C"),
                ColorSwatch(name: "Mood Indigo", pantoneCode: "19-4025 TCX", hex: "#34394D"),
                ColorSwatch(name: "Leisure Time", pantoneCode: "14-4815 TCX", hex: "#80BEC2"),
                ColorSwatch(name: "Porcelain", pantoneCode: "16-4719 TCX", hex: "#5C9DA3"),
                ColorSwatch(name: "Hydro", pantoneCode: "18-4718 TCX", hex: "#426B74"),
                ColorSwatch(name: "Arctic", pantoneCode: "17-4911 TCX", hex: "#648589"),
                ColorSwatch(name: "Atlantic Deep", pantoneCode: "19-4726 TCX", hex: "#244D53"),
                ColorSwatch(name: "Meadow", pantoneCode: "14-6319 TCX", hex: "#8BBF9A"),
                ColorSwatch(name: "Beryl Green", pantoneCode: "16-5515 TCX", hex: "#61948A"),
                ColorSwatch(name: "Hunter Green", pantoneCode: "19-5511 TCX", hex: "#315548"),
                ColorSwatch(name: "Garden Glade", pantoneCode: "13-0614 TCX", hex: "#DFDDAA"),
                ColorSwatch(name: "Shadow Green", pantoneCode: "14-0627 TCX", hex: "#CEC68A")
            ]
        case .softAutumn:
            return [
                ColorSwatch(name: "Sweet Corn", pantoneCode: "11-0106 TCX", hex: "#F0ECD7"),
                ColorSwatch(name: "White Asparagus", pantoneCode: "12-0104 TCX", hex: "#E1DCCB"),
                ColorSwatch(name: "Turtledove", pantoneCode: "12-5202 TCX", hex: "#DCD6C7"),
                ColorSwatch(name: "Overcast", pantoneCode: "14-0105 TCX", hex: "#C3BEAC"),
                ColorSwatch(name: "Bog", pantoneCode: "14-0418 TCX", hex: "#B9B69A"),
                ColorSwatch(name: "Sage Green", pantoneCode: "15-0318 TCX", hex: "#ACAD8A"),
                ColorSwatch(name: "Aloe", pantoneCode: "17-0620 TCX", hex: "#827D63"),
                ColorSwatch(name: "Olive Night", pantoneCode: "19-0515 TCX", hex: "#514F3E"),
                ColorSwatch(name: "Sage", pantoneCode: "16-0421 TCX", hex: "#969777"),
                ColorSwatch(name: "Beetle", pantoneCode: "19-0312 TCX", hex: "#55574A"),
                ColorSwatch(name: "Burlwood", pantoneCode: "17-1516 TCX", hex: "#9D736D"),
                ColorSwatch(name: "Russet", pantoneCode: "18-1235 TCX", hex: "#936152"),
                ColorSwatch(name: "Carob Brown", pantoneCode: "18-1229 TCX", hex: "#865E4D"),
                ColorSwatch(name: "Hot Chocolate", pantoneCode: "19-1325 TCX", hex: "#673B3A"),
                ColorSwatch(name: "Rum Raisin", pantoneCode: "19-1321 TCX", hex: "#573432"),
                ColorSwatch(name: "Coral Almond", pantoneCode: "16-1434 TCX", hex: "#E59B90"),
                ColorSwatch(name: "Tea Rose", pantoneCode: "16-1620 TCX", hex: "#D96F79"),
                ColorSwatch(name: "Holly Berry", pantoneCode: "17-1633 TCX", hex: "#B44D60"),
                ColorSwatch(name: "Crabapple", pantoneCode: "16-1532 TCX", hex: "#D77E70"),
                ColorSwatch(name: "Cardinal", pantoneCode: "18-1643 TCX", hex: "#AD3D4A"),
                ColorSwatch(name: "Crystal Rose", pantoneCode: "12-1708 TCX", hex: "#F9C1C5"),
                ColorSwatch(name: "Murex Shell", pantoneCode: "15-1712 TCX", hex: "#F39DA2"),
                ColorSwatch(name: "Faded Rose", pantoneCode: "18-1629 TCX", hex: "#BE6263"),
                ColorSwatch(name: "Baroque Rose", pantoneCode: "18-1634 TCX", hex: "#AD5665"),
                ColorSwatch(name: "Tibetan Red", pantoneCode: "19-1934 TCX", hex: "#762A3A"),
                ColorSwatch(name: "Dusk Blue", pantoneCode: "16-4120 TCX", hex: "#7DA3C1"),
                ColorSwatch(name: "Blue Jasper", pantoneCode: "18-4033 TCX", hex: "#507DA7"),
                ColorSwatch(name: "High Tide", pantoneCode: "18-4022 TCX", hex: "#345D87"),
                ColorSwatch(name: "Deep Dive", pantoneCode: "19-4126 TCX", hex: "#254655"),
                ColorSwatch(name: "Estate Blue", pantoneCode: "19-4027 TCX", hex: "#233656"),
                ColorSwatch(name: "Ocean Wave", pantoneCode: "14-5711 TCX", hex: "#8DC3B6"),
                ColorSwatch(name: "Dusty Jade Green", pantoneCode: "15-5711 TCX", hex: "#7FB5A5"),
                ColorSwatch(name: "Bottle Green", pantoneCode: "17-5722 TCX", hex: "#417D6D"),
                ColorSwatch(name: "Bristol Blue", pantoneCode: "17-4818 TCX", hex: "#548D91"),
                ColorSwatch(name: "Mallard Green", pantoneCode: "19-4818 TCX", hex: "#3D5B58")
            ]
        case .trueAutumn:
            return [
                ColorSwatch(name: "Seedpearl", pantoneCode: "12-0703 TCX", hex: "#E6DCC5"),
                ColorSwatch(name: "Angora", pantoneCode: "12-0605 TCX", hex: "#DFD0BB"),
                ColorSwatch(name: "Fog", pantoneCode: "13-0607 TCX", hex: "#CEC5B2"),
                ColorSwatch(name: "Double Cream", pantoneCode: "12-0715 TCX", hex: "#F4E1AD"),
                ColorSwatch(name: "Straw", pantoneCode: "13-0922 TCX", hex: "#E1CA94"),
                ColorSwatch(name: "Tidal Foam", pantoneCode: "14-0210 TCX", hex: "#C2BDA7"),
                ColorSwatch(name: "Oil Green", pantoneCode: "17-0115 TCX", hex: "#838873"),
                ColorSwatch(name: "Lead Gray", pantoneCode: "17-1118 TCX", hex: "#8F7D66"),
                ColorSwatch(name: "Stone Gray", pantoneCode: "18-0615 TCX", hex: "#6B6151"),
                ColorSwatch(name: "Deep Depths", pantoneCode: "19-0413 TCX", hex: "#414438"),
                ColorSwatch(name: "Peach Nougat", pantoneCode: "14-1220 TCX", hex: "#E7AE91"),
                ColorSwatch(name: "Peach Bloom", pantoneCode: "15-1327 TCX", hex: "#D99A7D"),
                ColorSwatch(name: "Cedar Wood", pantoneCode: "17-1525 TCX", hex: "#A36A5E"),
                ColorSwatch(name: "Henna", pantoneCode: "19-1334 TCX", hex: "#7D403A"),
                ColorSwatch(name: "Chicory Coffee", pantoneCode: "19-1419 TCX", hex: "#49312D"),
                ColorSwatch(name: "Muskmelon", pantoneCode: "15-1242 TCX", hex: "#ED9560"),
                ColorSwatch(name: "Amberglow", pantoneCode: "16-1350 TCX", hex: "#DF793D"),
                ColorSwatch(name: "Orange Rust", pantoneCode: "18-1447 TCX", hex: "#C35A3B"),
                ColorSwatch(name: "Summer Fig", pantoneCode: "17-1450 TCX", hex: "#BF4C3A"),
                ColorSwatch(name: "Picante", pantoneCode: "19-1250 TCX", hex: "#8C3D2C"),
                ColorSwatch(name: "Peach Amber", pantoneCode: "15-1423 TCX", hex: "#F99F91"),
                ColorSwatch(name: "Porcelain Rose", pantoneCode: "17-1643 TCX", hex: "#E9686A"),
                ColorSwatch(name: "American Beauty", pantoneCode: "19-1759 TCX", hex: "#A82F40"),
                ColorSwatch(name: "Merlot", pantoneCode: "19-1534 TCX", hex: "#76272E"),
                ColorSwatch(name: "Maroon Banner", pantoneCode: "19-1528 TCX", hex: "#592A37"),
                ColorSwatch(name: "Sea Jet", pantoneCode: "15-4713 TCX", hex: "#55B0BB"),
                ColorSwatch(name: "Bayou", pantoneCode: "18-5121 TCX", hex: "#216D6B"),
                ColorSwatch(name: "Blue Mist", pantoneCode: "16-4421 TCX", hex: "#5AAEC2"),
                ColorSwatch(name: "Biscay Bay", pantoneCode: "18-4726 TCX", hex: "#087D87"),
                ColorSwatch(name: "Deep Teal", pantoneCode: "19-4914 TCX", hex: "#19474A"),
                ColorSwatch(name: "Beechnut", pantoneCode: "14-0425 TCX", hex: "#C3C294"),
                ColorSwatch(name: "Fern", pantoneCode: "16-0430 TCX", hex: "#9BA16A"),
                ColorSwatch(name: "Split Pea", pantoneCode: "16-0545 TCX", hex: "#9D9B3E"),
                ColorSwatch(name: "Fir Green", pantoneCode: "18-0627 TCX", hex: "#6A592A"),
                ColorSwatch(name: "Forest Night", pantoneCode: "19-0414 TCX", hex: "#414136")
            ]
        case .darkAutumn:
            return [
                ColorSwatch(name: "White Swan", pantoneCode: "12-0000 TCX", hex: "#E4D8C7"),
                ColorSwatch(name: "Smoke Gray", pantoneCode: "14-1209 TCX", hex: "#CDBBAA"),
                ColorSwatch(name: "Summer Melon", pantoneCode: "13-0814 TCX", hex: "#EBD3AD"),
                ColorSwatch(name: "Autumn Blonde", pantoneCode: "12-0813 TCX", hex: "#F0D0AE"),
                ColorSwatch(name: "Lattè", pantoneCode: "15-1220 TCX", hex: "#C6A585"),
                ColorSwatch(name: "French Oak", pantoneCode: "13-0400 TCX", hex: "#C9C0B4"),
                ColorSwatch(name: "Elephant Skin", pantoneCode: "17-0205 TCX", hex: "#918B85"),
                ColorSwatch(name: "Tarmac", pantoneCode: "19-0822 TCX", hex: "#5B5448"),
                ColorSwatch(name: "Savannah Tan", pantoneCode: "16-1213 TCX", hex: "#AB9785"),
                ColorSwatch(name: "Pavement", pantoneCode: "19-3900 TCX", hex: "#514C50"),
                ColorSwatch(name: "Ochre", pantoneCode: "14-1036 TCX", hex: "#D7B066"),
                ColorSwatch(name: "Mustard Gold", pantoneCode: "16-1133 TCX", hex: "#AD8E50"),
                ColorSwatch(name: "Cathay Spice", pantoneCode: "18-0950 TCX", hex: "#99632D"),
                ColorSwatch(name: "Butternum", pantoneCode: "16-1341 TCX", hex: "#C89169"),
                ColorSwatch(name: "Sunburn", pantoneCode: "16-1429 TCX", hex: "#B5745B"),
                ColorSwatch(name: "Blooming Dahlia", pantoneCode: "15-1520 TCX", hex: "#ED9588"),
                ColorSwatch(name: "Burnt Sienna", pantoneCode: "17-1544 TCX", hex: "#C65D53"),
                ColorSwatch(name: "Cranberry", pantoneCode: "17-1545 TCX", hex: "#B8474F"),
                ColorSwatch(name: "Burnt Russet", pantoneCode: "19-1530 TCX", hex: "#7C3940"),
                ColorSwatch(name: "Pomegranate", pantoneCode: "19-1930 TCX", hex: "#672830"),
                ColorSwatch(name: "Pastel Lavender", pantoneCode: "14-3209 TCX", hex: "#D6A0C3"),
                ColorSwatch(name: "Spring Crocus", pantoneCode: "17-3020 TCX", hex: "#B6659E"),
                ColorSwatch(name: "Rosé Sorbet", pantoneCode: "18-2615 TCX", hex: "#A0467C"),
                ColorSwatch(name: "Plum Caspia", pantoneCode: "19-2429 TCX", hex: "#5B2147"),
                ColorSwatch(name: "Titan", pantoneCode: "19-4128 TCX", hex: "#283D53"),
                ColorSwatch(name: "Bermuda", pantoneCode: "14-5416 TCX", hex: "#60C4B1"),
                ColorSwatch(name: "Lagoon", pantoneCode: "16-5418 TCX", hex: "#4D9E9B"),
                ColorSwatch(name: "Frosty Spruce", pantoneCode: "18-5622 TCX", hex: "#568271"),
                ColorSwatch(name: "Evergreen", pantoneCode: "19-5420 TCX", hex: "#105448"),
                ColorSwatch(name: "Green Gables", pantoneCode: "19-4806 TCX", hex: "#344343"),
                ColorSwatch(name: "Willow", pantoneCode: "16-0632 TCX", hex: "#9C8F4F"),
                ColorSwatch(name: "Plantation", pantoneCode: "18-0832 TCX", hex: "#79612F"),
                ColorSwatch(name: "Military Olive", pantoneCode: "19-0622 TCX", hex: "#5F523B"),
                ColorSwatch(name: "Wren", pantoneCode: "19-0614 TCX", hex: "#494039"),
                ColorSwatch(name: "Glamour Gold", pantoneCode: "20-0033 TPM", hex: "#C3A06B")
            ]
        case .darkWinter:
            return [
                ColorSwatch(name: "Lucent White", pantoneCode: "11-0700 TCX", hex: "#F2F5FC"),
                ColorSwatch(name: "Vaporous Gray", pantoneCode: "12-4302 TCX", hex: "#DEDDD7"),
                ColorSwatch(name: "Pumice Stone", pantoneCode: "14-0002 TCX", hex: "#C9C3BA"),
                ColorSwatch(name: "Ghost Gray", pantoneCode: "16-4703 TCX", hex: "#9D9D9B"),
                ColorSwatch(name: "Charcoal Gray", pantoneCode: "18-0601 TCX", hex: "#6D696A"),
                ColorSwatch(name: "Lemonade", pantoneCode: "12-0721 TCX", hex: "#F0E69C"),
                ColorSwatch(name: "Ballet Slipper", pantoneCode: "13-2808 TCX", hex: "#EBCDD4"),
                ColorSwatch(name: "Bay", pantoneCode: "12-5507 TCX", hex: "#B7E4D6"),
                ColorSwatch(name: "Spun Sugar", pantoneCode: "12-4401 TCX", hex: "#B3DDE8"),
                ColorSwatch(name: "Purple Heather", pantoneCode: "14-3911 TCX", hex: "#B8B5D0"),
                ColorSwatch(name: "Plumeria", pantoneCode: "15-1822 TCX", hex: "#F58DA1"),
                ColorSwatch(name: "Fruit Dove", pantoneCode: "17-1926 TCX", hex: "#D05776"),
                ColorSwatch(name: "Bossy Pink", pantoneCode: "18-2054 TSX", hex: "#CF3566"),
                ColorSwatch(name: "Innuendo", pantoneCode: "18-2042 TCX", hex: "#C32F62"),
                ColorSwatch(name: "Red Bud", pantoneCode: "19-1850 TCX", hex: "#922C4A"),
                ColorSwatch(name: "Lipstick Red", pantoneCode: "19-1764 TCX", hex: "#B51D3D"),
                ColorSwatch(name: "Scarlet Smile", pantoneCode: "19-1558 TCX", hex: "#9E253A"),
                ColorSwatch(name: "Rio Red", pantoneCode: "19-1656 TCX", hex: "#862336"),
                ColorSwatch(name: "Rhubarb", pantoneCode: "19-1652 TCX", hex: "#76212F"),
                ColorSwatch(name: "Zinfandel", pantoneCode: "19-1522 TCX", hex: "#582833"),
                ColorSwatch(name: "African Violet", pantoneCode: "16-3520 TCX", hex: "#B184B7"),
                ColorSwatch(name: "Bellflower", pantoneCode: "18-3628 TCX", hex: "#94649D"),
                ColorSwatch(name: "Plum Jam", pantoneCode: "18-3521 TCX", hex: "#633F78"),
                ColorSwatch(name: "Grape Royale", pantoneCode: "19-3518 TCX", hex: "#512D52"),
                ColorSwatch(name: "Baritone Blue", pantoneCode: "19-3812 TCX", hex: "#252633"),
                ColorSwatch(name: "Splish Splash", pantoneCode: "16-4520 TCX", hex: "#67B9D8"),
                ColorSwatch(name: "Mediterranean Blue", pantoneCode: "18-4334 TCX", hex: "#147BA4"),
                ColorSwatch(name: "Moroccan Blue", pantoneCode: "19-4241 TCX", hex: "#104F67"),
                ColorSwatch(name: "Deep Water", pantoneCode: "18-4032 TCX", hex: "#28688D"),
                ColorSwatch(name: "Pageant Blue", pantoneCode: "19-4111 TCX", hex: "#202D46"),
                ColorSwatch(name: "Marine Green", pantoneCode: "16-5721 TCX", hex: "#3EA38F"),
                ColorSwatch(name: "Lush Meadow", pantoneCode: "18-5845 TCX", hex: "#007257"),
                ColorSwatch(name: "Forest Biome", pantoneCode: "19-5230 TCX", hex: "#194C47"),
                ColorSwatch(name: "Ponderosa Pine", pantoneCode: "19-5320 TCX", hex: "#1F3F3F"),
                ColorSwatch(name: "Tap Shoe", pantoneCode: "19-4004 TCX", hex: "#29292B")
            ]
        case .trueWinter:
            return [
                ColorSwatch(name: "Brilliant White", pantoneCode: "11-4001 TCX", hex: "#EEF1FF"),
                ColorSwatch(name: "Lily White", pantoneCode: "11-4301 TCX", hex: "#E3E3DB"),
                ColorSwatch(name: "Silver Birch", pantoneCode: "13-4403 TCX", hex: "#D1D0C5"),
                ColorSwatch(name: "Mourning Dove", pantoneCode: "16-4400 TCX", hex: "#99948F"),
                ColorSwatch(name: "Brushed Nickel", pantoneCode: "18-5102 TCX", hex: "#706E6D"),
                ColorSwatch(name: "Tender Touch", pantoneCode: "12-2807 TCX", hex: "#F2D5DF"),
                ColorSwatch(name: "Elfin Yellow", pantoneCode: "11-0626 TCX", hex: "#F0E99A"),
                ColorSwatch(name: "Misty Jade", pantoneCode: "13-6008 TCX", hex: "#B8D8C8"),
                ColorSwatch(name: "Spa Retreat", pantoneCode: "13-4808 TCX", hex: "#B1E4E9"),
                ColorSwatch(name: "Halogen Blue", pantoneCode: "13-3920 TCX", hex: "#BBC5DC"),
                ColorSwatch(name: "Pirouette", pantoneCode: "14-3205 TCX", hex: "#E9B9D9"),
                ColorSwatch(name: "Bonbon", pantoneCode: "15-2213 TCX", hex: "#EDA0CC"),
                ColorSwatch(name: "Strawberry Moon", pantoneCode: "17-2619 TCX", hex: "#D7659F"),
                ColorSwatch(name: "Very Berry", pantoneCode: "18-2336 TCX", hex: "#B72F75"),
                ColorSwatch(name: "Wild Aster", pantoneCode: "19-2630 TCX", hex: "#8F2E70"),
                ColorSwatch(name: "Lilac Chiffon", pantoneCode: "15-2913 TCX", hex: "#D995C1"),
                ColorSwatch(name: "Violet", pantoneCode: "16-3320 TCX", hex: "#BB80B7"),
                ColorSwatch(name: "Radiant Orchid", pantoneCode: "18-3224 TCX", hex: "#A75A98"),
                ColorSwatch(name: "Hollyhock", pantoneCode: "19-2924 TCX", hex: "#80336F"),
                ColorSwatch(name: "Charisma", pantoneCode: "18-3340 TCX", hex: "#62295F"),
                ColorSwatch(name: "Persian Jewel", pantoneCode: "17-3934 TCX", hex: "#7184C1"),
                ColorSwatch(name: "Amparo Blue", pantoneCode: "18-3945 TCX", hex: "#4B61A4"),
                ColorSwatch(name: "Surf the Web", pantoneCode: "19-3952 TCX", hex: "#233F7E"),
                ColorSwatch(name: "Bellwether Blue", pantoneCode: "19-3943 TCX", hex: "#25345F"),
                ColorSwatch(name: "Ocean Cavern", pantoneCode: "19-3937 TCX", hex: "#252940"),
                ColorSwatch(name: "Cyan Blue", pantoneCode: "16-4529 TCX", hex: "#12A2C3"),
                ColorSwatch(name: "Faience", pantoneCode: "18-4232 TCX", hex: "#2D6F8E"),
                ColorSwatch(name: "Spectra Green", pantoneCode: "17-5335 TCX", hex: "#009B8E"),
                ColorSwatch(name: "Tidepool", pantoneCode: "18-5619 TCX", hex: "#08736C"),
                ColorSwatch(name: "Green Heron", pantoneCode: "19-4727 TCX", hex: "#285258"),
                ColorSwatch(name: "Gentian Violet", pantoneCode: "19-3730 TCX", hex: "#514071"),
                ColorSwatch(name: "Navy Blue", pantoneCode: "19-3832 TCX", hex: "#3D3D70"),
                ColorSwatch(name: "Medieval Blue", pantoneCode: "19-3933 TCX", hex: "#292F50"),
                ColorSwatch(name: "Bracken", pantoneCode: "19-1015 TCX", hex: "#4D3D39"),
                ColorSwatch(name: "Môle", pantoneCode: "19-1106 TCX", hex: "#382B2A")
            ]
        case .brightWinter:
            return [
                ColorSwatch(name: "Bright White", pantoneCode: "11-0601 TCX", hex: "#F3F8FF"),
                ColorSwatch(name: "Arctic Wolf", pantoneCode: "12-0602 TCX", hex: "#E6DFCE"),
                ColorSwatch(name: "Abbey Stone", pantoneCode: "14-6408 TCX", hex: "#ADA99B"),
                ColorSwatch(name: "Steeple Gray", pantoneCode: "17-1500 TCX", hex: "#858180"),
                ColorSwatch(name: "Steel Gray", pantoneCode: "18-4005 TCX", hex: "#747273"),
                ColorSwatch(name: "Pastel Yellow", pantoneCode: "11-0616 TCX", hex: "#F2E7B0"),
                ColorSwatch(name: "Pink Dogwood", pantoneCode: "12-1706 TCX", hex: "#F5D0D1"),
                ColorSwatch(name: "Fair Aqua", pantoneCode: "12-5409 TCX", hex: "#B8E2DC"),
                ColorSwatch(name: "Festival Bloom", pantoneCode: "12-2908 TCX", hex: "#F2D5E5"),
                ColorSwatch(name: "Pastel Lilac", pantoneCode: "14-3812 TCX", hex: "#BFB3CA"),
                ColorSwatch(name: "Ranunculus", pantoneCode: "16-1634 TSX", hex: "#EC898D"),
                ColorSwatch(name: "Honeysuckle", pantoneCode: "18-2120 TCX", hex: "#D74770"),
                ColorSwatch(name: "Raspberry Sorbet", pantoneCode: "18-2043 TCX", hex: "#D03168"),
                ColorSwatch(name: "Vivacious", pantoneCode: "19-2045 TCX", hex: "#A32658"),
                ColorSwatch(name: "Red Plum", pantoneCode: "19-2025 TCX", hex: "#762744"),
                ColorSwatch(name: "Fuchsia Purple", pantoneCode: "18-2436 TCX", hex: "#D12F79"),
                ColorSwatch(name: "Fuchsia Fedora", pantoneCode: "18-2330 TCX", hex: "#C63F87"),
                ColorSwatch(name: "Fuchsia Red", pantoneCode: "18-2328 TCX", hex: "#A83276"),
                ColorSwatch(name: "Rose Violet", pantoneCode: "17-2624 TCX", hex: "#BD428B"),
                ColorSwatch(name: "Purple Wine", pantoneCode: "18-2929 TCX", hex: "#853675"),
                ColorSwatch(name: "Iolite", pantoneCode: "17-3940 TCX", hex: "#737DB7"),
                ColorSwatch(name: "Blue Iris", pantoneCode: "18-3943 TCX", hex: "#5B5B9B"),
                ColorSwatch(name: "Bluing", pantoneCode: "19-3954 TCX", hex: "#303F82"),
                ColorSwatch(name: "Ultramarine", pantoneCode: "17-4037 TCX", hex: "#5B7DBD"),
                ColorSwatch(name: "Dazzling Blue", pantoneCode: "18-3949 TCX", hex: "#38539D"),
                ColorSwatch(name: "Aged Copper", pantoneCode: "14-4434 TSX", hex: "#5BC5D0"),
                ColorSwatch(name: "Viridian Green", pantoneCode: "17-5126 TCX", hex: "#009697"),
                ColorSwatch(name: "Blue Blossom", pantoneCode: "15-4535 TSX", hex: "#2DA8D3"),
                ColorSwatch(name: "Blithe", pantoneCode: "17-4336 TCX", hex: "#0085B8"),
                ColorSwatch(name: "Turkish Tile", pantoneCode: "18-4432 TCX", hex: "#006C87"),
                ColorSwatch(name: "Black Iris", pantoneCode: "19-3921 TCX", hex: "#2C3043"),
                ColorSwatch(name: "Black Ink", pantoneCode: "19-0506 TCX", hex: "#45413D"),
                ColorSwatch(name: "Blackened Pearl", pantoneCode: "19-3917 TCX", hex: "#4E4B50"),
                ColorSwatch(name: "Pirate Black", pantoneCode: "19-4305 TCX", hex: "#343636"),
                ColorSwatch(name: "Anthracite", pantoneCode: "19-4007 TCX", hex: "#26262B")
            ]
        }
    }

    /// Representative sample swatches (5 primary accent colors) for UI accents and color wheels.
    public var sampleSwatches: [ColorSwatch] {
        switch self {
        case .brightSpring:
            return [
                ColorSwatch(name: "Snow White", pantoneCode: "11-0602 TCX", hex: "#F2F0EB"),
                ColorSwatch(name: "Aspen Gold", pantoneCode: "13-0850 TCX", hex: "#FFD662"),
                ColorSwatch(name: "Hot Pink", pantoneCode: "17-1937 TCX", hex: "#E55982"),
                ColorSwatch(name: "Tropical Green", pantoneCode: "18-4930 TCX", hex: "#008786"),
                ColorSwatch(name: "Imperial Blue", pantoneCode: "19-4245 TCX", hex: "#005A92")
            ]
        case .trueSpring:
            return [
                ColorSwatch(name: "Vanilla", pantoneCode: "12-0712 TCX", hex: "#F3E5C8"),
                ColorSwatch(name: "Sunshine", pantoneCode: "12-0727 TCX", hex: "#FAD055"),
                ColorSwatch(name: "Georgia Peach", pantoneCode: "16-1641 TCX", hex: "#F97272"),
                ColorSwatch(name: "Irish Green", pantoneCode: "15-6340 TCX", hex: "#3FAD67"),
                ColorSwatch(name: "Directoire Blue", pantoneCode: "18-4244 TCX", hex: "#0061A3")
            ]
        case .lightSpring:
            return [
                ColorSwatch(name: "Shortbread", pantoneCode: "12-0710 TCX", hex: "#F1DEC7"),
                ColorSwatch(name: "Lemon Drop", pantoneCode: "12-0736 TCX", hex: "#FDCE5B"),
                ColorSwatch(name: "Sun Kissed Coral", pantoneCode: "17-1736 TCX", hex: "#EA5C6B"),
                ColorSwatch(name: "Blue Curacao", pantoneCode: "15-4825 TCX", hex: "#33B1C5"),
                ColorSwatch(name: "Mint", pantoneCode: "16-5938 TCX", hex: "#009973")
            ]
        case .lightSummer:
            return [
                ColorSwatch(name: "Tofu", pantoneCode: "11-4801 TCX", hex: "#E7E5D9"),
                ColorSwatch(name: "Candy Pink", pantoneCode: "14-1911 TCX", hex: "#F4B0BD"),
                ColorSwatch(name: "Mint Leaf", pantoneCode: "15-5728 TCX", hex: "#02B694"),
                ColorSwatch(name: "River Blue", pantoneCode: "15-4720 TCX", hex: "#38AECC"),
                ColorSwatch(name: "Star Sapphire", pantoneCode: "18-4041 TCX", hex: "#35619E")
            ]
        case .trueSummer:
            return [
                ColorSwatch(name: "Light Gray", pantoneCode: "12-0404 TCX", hex: "#DAD9CB"),
                ColorSwatch(name: "Sea Pink", pantoneCode: "15-1912 TCX", hex: "#D994A7"),
                ColorSwatch(name: "Deep Periwinkle", pantoneCode: "17-3932 TCX", hex: "#7F86BD"),
                ColorSwatch(name: "Ming Green", pantoneCode: "16-5930 TCX", hex: "#39A17E"),
                ColorSwatch(name: "Major Brown", pantoneCode: "19-0810 TCX", hex: "#625955")
            ]
        case .softSummer:
            return [
                ColorSwatch(name: "Birch", pantoneCode: "13-0905 TCX", hex: "#DED6C8"),
                ColorSwatch(name: "English Rose", pantoneCode: "13-1310 TCX", hex: "#F3C6C3"),
                ColorSwatch(name: "Porcelain", pantoneCode: "16-4719 TCX", hex: "#5C9DA3"),
                ColorSwatch(name: "Meadow", pantoneCode: "14-6319 TCX", hex: "#8BBF9A"),
                ColorSwatch(name: "Mood Indigo", pantoneCode: "19-4025 TCX", hex: "#34394D")
            ]
        case .softAutumn:
            return [
                ColorSwatch(name: "Sweet Corn", pantoneCode: "11-0106 TCX", hex: "#F0ECD7"),
                ColorSwatch(name: "Coral Almond", pantoneCode: "16-1434 TCX", hex: "#E59B90"),
                ColorSwatch(name: "Sage Green", pantoneCode: "15-0318 TCX", hex: "#ACAD8A"),
                ColorSwatch(name: "Blue Jasper", pantoneCode: "18-4033 TCX", hex: "#507DA7"),
                ColorSwatch(name: "Carob Brown", pantoneCode: "18-1229 TCX", hex: "#865E4D")
            ]
        case .trueAutumn:
            return [
                ColorSwatch(name: "Seedpearl", pantoneCode: "12-0703 TCX", hex: "#E6DCC5"),
                ColorSwatch(name: "Amberglow", pantoneCode: "16-1350 TCX", hex: "#DF793D"),
                ColorSwatch(name: "Fern", pantoneCode: "16-0430 TCX", hex: "#9BA16A"),
                ColorSwatch(name: "Biscay Bay", pantoneCode: "18-4726 TCX", hex: "#087D87"),
                ColorSwatch(name: "Chicory Coffee", pantoneCode: "19-1419 TCX", hex: "#49312D")
            ]
        case .darkAutumn:
            return [
                ColorSwatch(name: "White Swan", pantoneCode: "12-0000 TCX", hex: "#E4D8C7"),
                ColorSwatch(name: "Mustard Gold", pantoneCode: "16-1133 TCX", hex: "#AD8E50"),
                ColorSwatch(name: "Burnt Sienna", pantoneCode: "17-1544 TCX", hex: "#C65D53"),
                ColorSwatch(name: "Evergreen", pantoneCode: "19-5420 TCX", hex: "#105448"),
                ColorSwatch(name: "Tarmac", pantoneCode: "19-0822 TCX", hex: "#5B5448")
            ]
        case .darkWinter:
            return [
                ColorSwatch(name: "Lucent White", pantoneCode: "11-0700 TCX", hex: "#F2F5FC"),
                ColorSwatch(name: "Fruit Dove", pantoneCode: "17-1926 TCX", hex: "#D05776"),
                ColorSwatch(name: "Lush Meadow", pantoneCode: "18-5845 TCX", hex: "#007257"),
                ColorSwatch(name: "Mediterranean Blue", pantoneCode: "18-4334 TCX", hex: "#147BA4"),
                ColorSwatch(name: "Tap Shoe", pantoneCode: "19-4004 TCX", hex: "#29292B")
            ]
        case .trueWinter:
            return [
                ColorSwatch(name: "Brilliant White", pantoneCode: "11-4001 TCX", hex: "#EEF1FF"),
                ColorSwatch(name: "Very Berry", pantoneCode: "18-2336 TCX", hex: "#B72F75"),
                ColorSwatch(name: "Spectra Green", pantoneCode: "17-5335 TCX", hex: "#009B8E"),
                ColorSwatch(name: "Amparo Blue", pantoneCode: "18-3945 TCX", hex: "#4B61A4"),
                ColorSwatch(name: "Medieval Blue", pantoneCode: "19-3933 TCX", hex: "#292F50")
            ]
        case .brightWinter:
            return [
                ColorSwatch(name: "Bright White", pantoneCode: "11-0601 TCX", hex: "#F3F8FF"),
                ColorSwatch(name: "Honeysuckle", pantoneCode: "18-2120 TCX", hex: "#D74770"),
                ColorSwatch(name: "Viridian Green", pantoneCode: "17-5126 TCX", hex: "#009697"),
                ColorSwatch(name: "Dazzling Blue", pantoneCode: "18-3949 TCX", hex: "#38539D"),
                ColorSwatch(name: "Black Iris", pantoneCode: "19-3921 TCX", hex: "#2C3043")
            ]
        }
    }

    // MARK: - LLM System Prompt & Context

    /// Generates structured prompt context for LLM recommendation prompts (aligned with StyleVision).
    public var systemPrompt: String {
        """
        Color Season: \(rawValue)
        Definition: \(definition)
        Act: \(act)
        Color Combination Rules: \(colorCombinationRules)
        Colors to Avoid: \(colorsToAvoid)
        Tonal Coordinates:
        - Hue: \(hue)
        - Value: \(value)
        - Chroma: \(chroma)
        Color Palette: \(palette.map { "\($0.name) (\($0.hex))" }.joined(separator: ", "))
        """
    }

    /// Generates structured prompt context for LLM recommendation prompts (matching StyleVision's `llmPromptContext`).
    public var llmPromptContext: String {
        systemPrompt
    }
}
