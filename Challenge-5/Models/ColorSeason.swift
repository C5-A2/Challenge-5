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

        public init(name: String, pantoneCode: String = "", hex: String) {
            self.name = name
            self.pantoneCode = pantoneCode
            self.hex = hex
        }

        public init(name: String, hex: String) {
            self.name = name
            self.pantoneCode = ""
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


    /// Swatches of colors that do NOT suit this season (for the "Colors that don't suit you" UI).
    public var colorsToAvoidPalette: [ColorSwatch] {
        switch self {
        case .brightSpring:
            return [
                ColorSwatch(name: "#C1BEB7", hex: "#C1BEB7"),
                ColorSwatch(name: "#DBD8AD", hex: "#DBD8AD"),
                ColorSwatch(name: "#D1A8A3", hex: "#D1A8A3"),
                ColorSwatch(name: "#B8A7AF", hex: "#B8A7AF"),
                ColorSwatch(name: "#9FADB5", hex: "#9FADB5"),
                ColorSwatch(name: "#707871", hex: "#707871"),
                ColorSwatch(name: "#7D83B8", hex: "#7D83B8"),
                ColorSwatch(name: "#917B77", hex: "#917B77"),
                ColorSwatch(name: "#734D28", hex: "#734D28"),
                ColorSwatch(name: "#604E27", hex: "#604E27")
            ]
        case .trueSpring:
            return [
                ColorSwatch(name: "#F5F5F5", hex: "#F5F5F5"),
                ColorSwatch(name: "#E4AFCA", hex: "#E4AFCA"),
                ColorSwatch(name: "#7D3855", hex: "#7D3855"),
                ColorSwatch(name: "#A881AE", hex: "#A881AE"),
                ColorSwatch(name: "#616D88", hex: "#616D88"),
                ColorSwatch(name: "#253149", hex: "#253149"),
                ColorSwatch(name: "#9C9089", hex: "#9C9089"),
                ColorSwatch(name: "#949599", hex: "#949599"),
                ColorSwatch(name: "#40464D", hex: "#40464D"),
                ColorSwatch(name: "#000000", hex: "#000000")
            ]
        case .lightSpring:
            return [
                ColorSwatch(name: "#F5F5F5", hex: "#F5F5F5"),
                ColorSwatch(name: "#BE5C23", hex: "#BE5C23"),
                ColorSwatch(name: "#4F1512", hex: "#4F1512"),
                ColorSwatch(name: "#520F40", hex: "#520F40"),
                ColorSwatch(name: "#3D474E", hex: "#3D474E"),
                ColorSwatch(name: "#1A383D", hex: "#1A383D"),
                ColorSwatch(name: "#7D4729", hex: "#7D4729"),
                ColorSwatch(name: "#453526", hex: "#453526"),
                ColorSwatch(name: "#544C49", hex: "#544C49"),
                ColorSwatch(name: "#000000", hex: "#000000")
            ]
        case .lightSummer:
            return [
                ColorSwatch(name: "#F5F5F5", hex: "#F5F5F5"),
                ColorSwatch(name: "#F0C045", hex: "#F0C045"),
                ColorSwatch(name: "#E08F3E", hex: "#E08F3E"),
                ColorSwatch(name: "#BE4A36", hex: "#BE4A36"),
                ColorSwatch(name: "#8B7539", hex: "#8B7539"),
                ColorSwatch(name: "#844427", hex: "#844427"),
                ColorSwatch(name: "#3E171E", hex: "#3E171E"),
                ColorSwatch(name: "#2A152A", hex: "#2A152A"),
                ColorSwatch(name: "#162F1C", hex: "#162F1C"),
                ColorSwatch(name: "#000000", hex: "#000000")
            ]
        case .trueSummer:
            return [
                ColorSwatch(name: "#F5F5F5", hex: "#F5F5F5"),
                ColorSwatch(name: "#F0C145", hex: "#F0C145"),
                ColorSwatch(name: "#D1A544", hex: "#D1A544"),
                ColorSwatch(name: "#E0633B", hex: "#E0633B"),
                ColorSwatch(name: "#BB4933", hex: "#BB4933"),
                ColorSwatch(name: "#ECAB92", hex: "#ECAB92"),
                ColorSwatch(name: "#9B5A30", hex: "#9B5A30"),
                ColorSwatch(name: "#874529", hex: "#874529"),
                ColorSwatch(name: "#230263", hex: "#230263"),
                ColorSwatch(name: "#000000", hex: "#000000")
            ]
        case .softSummer:
            return [
                ColorSwatch(name: "#F5F5F5", hex: "#F5F5F5"),
                ColorSwatch(name: "#FBF250", hex: "#FBF250"),
                ColorSwatch(name: "#BCA145", hex: "#BCA145"),
                ColorSwatch(name: "#DF7047", hex: "#DF7047"),
                ColorSwatch(name: "#DA3731", hex: "#DA3731"),
                ColorSwatch(name: "#DB4696", hex: "#DB4696"),
                ColorSwatch(name: "#0513F5", hex: "#0513F5"),
                ColorSwatch(name: "#81BC56", hex: "#81BC56"),
                ColorSwatch(name: "#372415", hex: "#372415"),
                ColorSwatch(name: "#000000", hex: "#000000")
            ]
        case .softAutumn:
            return [
                ColorSwatch(name: "#F5F5F5", hex: "#F5F5F5"),
                ColorSwatch(name: "#F4ED5B", hex: "#F4ED5B"),
                ColorSwatch(name: "#E0633B", hex: "#E0633B"),
                ColorSwatch(name: "#DB3786", hex: "#DB3786"),
                ColorSwatch(name: "#2E318C", hex: "#2E318C"),
                ColorSwatch(name: "#D7DE52", hex: "#D7DE52"),
                ColorSwatch(name: "#98C454", hex: "#98C454"),
                ColorSwatch(name: "#57585A", hex: "#57585A"),
                ColorSwatch(name: "#240247", hex: "#240247"),
                ColorSwatch(name: "#000000", hex: "#000000")
            ]
        case .trueAutumn:
            return [
                ColorSwatch(name: "#EEF1FE", hex: "#EEF1FE"),
                ColorSwatch(name: "#F3D8E6", hex: "#F3D8E6"),
                ColorSwatch(name: "#D7C3DD", hex: "#D7C3DD"),
                ColorSwatch(name: "#BFDAEF", hex: "#BFDAEF"),
                ColorSwatch(name: "#9FADD3", hex: "#9FADD3"),
                ColorSwatch(name: "#D6E7C7", hex: "#D6E7C7"),
                ColorSwatch(name: "#A8A9AD", hex: "#A8A9AD"),
                ColorSwatch(name: "#DC478D", hex: "#DC478D"),
                ColorSwatch(name: "#1334F5", hex: "#1334F5"),
                ColorSwatch(name: "#000000", hex: "#000000")
            ]
        case .darkAutumn:
            return [
                ColorSwatch(name: "#F5F5F5", hex: "#F5F5F5"),
                ColorSwatch(name: "#F1D6E1", hex: "#F1D6E1"),
                ColorSwatch(name: "#E690AB", hex: "#E690AB"),
                ColorSwatch(name: "#B8A7B0", hex: "#B8A7B0"),
                ColorSwatch(name: "#976D7D", hex: "#976D7D"),
                ColorSwatch(name: "#A1AFB5", hex: "#A1AFB5"),
                ColorSwatch(name: "#5B6675", hex: "#5B6675"),
                ColorSwatch(name: "#454D55", hex: "#454D55"),
                ColorSwatch(name: "#808281", hex: "#808281"),
                ColorSwatch(name: "#000000", hex: "#000000")
            ]
        case .darkWinter:
            return [
                ColorSwatch(name: "#F8E2DE", hex: "#F8E2DE"),
                ColorSwatch(name: "#F5E5A6", hex: "#F5E5A6"),
                ColorSwatch(name: "#DBCA93", hex: "#DBCA93"),
                ColorSwatch(name: "#DEC773", hex: "#DEC773"),
                ColorSwatch(name: "#DDB97F", hex: "#DDB97F"),
                ColorSwatch(name: "#E39D41", hex: "#E39D41"),
                ColorSwatch(name: "#EE7D6D", hex: "#EE7D6D"),
                ColorSwatch(name: "#AB6C36", hex: "#AB6C36"),
                ColorSwatch(name: "#B05F34", hex: "#B05F34"),
                ColorSwatch(name: "#834628", hex: "#834628")
            ]
        case .trueWinter:
            return [
                ColorSwatch(name: "#FDF4DF", hex: "#FDF4DF"),
                ColorSwatch(name: "#D3B548", hex: "#D3B548"),
                ColorSwatch(name: "#EEB5A2", hex: "#EEB5A2"),
                ColorSwatch(name: "#E7A58E", hex: "#E7A58E"),
                ColorSwatch(name: "#9E5F5A", hex: "#9E5F5A"),
                ColorSwatch(name: "#B7DEFC", hex: "#B7DEFC"),
                ColorSwatch(name: "#ABAE8A", hex: "#ABAE8A"),
                ColorSwatch(name: "#A19D48", hex: "#A19D48"),
                ColorSwatch(name: "#9B774D", hex: "#9B774D"),
                ColorSwatch(name: "#995730", hex: "#995730")
            ]
        case .brightWinter:
            return [
                ColorSwatch(name: "#F1DFC9", hex: "#F1DFC9"),
                ColorSwatch(name: "#EEBF68", hex: "#EEBF68"),
                ColorSwatch(name: "#953E2C", hex: "#953E2C"),
                ColorSwatch(name: "#BEB6BE", hex: "#BEB6BE"),
                ColorSwatch(name: "#8FB5C0", hex: "#8FB5C0"),
                ColorSwatch(name: "#7C8B73", hex: "#7C8B73"),
                ColorSwatch(name: "#544424", hex: "#544424"),
                ColorSwatch(name: "#995A30", hex: "#995A30"),
                ColorSwatch(name: "#AF644F", hex: "#AF644F"),
                ColorSwatch(name: "#4B2513", hex: "#4B2513")
            ]
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

    /// Curated 35 color swatches for this season.
    public var palette: [ColorSwatch] {
        switch self {
        case .brightSpring:
            return [
                ColorSwatch(name: "Snow White", hex: "#F2F0EB"),
                ColorSwatch(name: "Vanilla Ice", hex: "#F0EADA"),
                ColorSwatch(name: "Rutabaga", hex: "#ECDDBE"),
                ColorSwatch(name: "Summer Sand", hex: "#D6CBBA"),
                ColorSwatch(name: "Oatmeal", hex: "#CBC3B4"),
                ColorSwatch(name: "Silver Lining", hex: "#BDB6AB"),
                ColorSwatch(name: "Brindle", hex: "#82776B"),
                ColorSwatch(name: "Chimera", hex: "#4D4C47"),
                ColorSwatch(name: "Imperial Blue", hex: "#005A92"),
                ColorSwatch(name: "Déja Vu Blue", hex: "#2E5283"),
                ColorSwatch(name: "Aspen Gold", hex: "#FFD662"),
                ColorSwatch(name: "Pale Marigold", hex: "#FFC66E"),
                ColorSwatch(name: "Artisan’s Gold", hex: "#F2AB46"),
                ColorSwatch(name: "Buckskin", hex: "#D18E54"),
                ColorSwatch(name: "Aurora Red", hex: "#B93A32"),
                ColorSwatch(name: "Orchid Pink", hex: "#F3BBCA"),
                ColorSwatch(name: "Geranium Pink", hex: "#F6909D"),
                ColorSwatch(name: "Hot Pink", hex: "#E55982"),
                ColorSwatch(name: "Pink Lemonade", hex: "#EE6D8A"),
                ColorSwatch(name: "Geranium", hex: "#DA3D58"),
                ColorSwatch(name: "Fuchsia Pink", hex: "#DF88B7"),
                ColorSwatch(name: "Raspberry Rose", hex: "#CC4385"),
                ColorSwatch(name: "Raspberry Radiance", hex: "#802A50"),
                ColorSwatch(name: "Nouveau Navy", hex: "#3A5589"),
                ColorSwatch(name: "Mazarine Blue", hex: "#273C76"),
                ColorSwatch(name: "Blue Radiance", hex: "#58C9D4"),
                ColorSwatch(name: "Peacock Blue", hex: "#00A0B0"),
                ColorSwatch(name: "Tropical Green", hex: "#008786"),
                ColorSwatch(name: "Bachelor Button", hex: "#4ABBD5"),
                ColorSwatch(name: "Mosaic Blue", hex: "#00758F"),
                ColorSwatch(name: "Sharp Green", hex: "#C6E67A"),
                ColorSwatch(name: "Macaw Green", hex: "#9BB53E"),
                ColorSwatch(name: "Online Lime", hex: "#44883C"),
                ColorSwatch(name: "Rolling Hills", hex: "#227949"),
                ColorSwatch(name: "Formal Garden", hex: "#1F5129")
            ]
        case .trueSpring:
            return [
                ColorSwatch(name: "Vanilla", hex: "#F3E5C8"),
                ColorSwatch(name: "Sun Kiss", hex: "#EBDBC3"),
                ColorSwatch(name: "Golden Fleece", hex: "#F2D1A0"),
                ColorSwatch(name: "Jojoba", hex: "#DDBF7E"),
                ColorSwatch(name: "Desert Mist", hex: "#E0B589"),
                ColorSwatch(name: "Golden Mist", hex: "#D5CD94"),
                ColorSwatch(name: "Moonstone", hex: "#BEA987"),
                ColorSwatch(name: "Pale Gold", hex: "#BD9865"),
                ColorSwatch(name: "Dachshund", hex: "#704F3B"),
                ColorSwatch(name: "Demitasse", hex: "#40342B"),
                ColorSwatch(name: "Impala", hex: "#F8CE97"),
                ColorSwatch(name: "Sunshine", hex: "#FAD055"),
                ColorSwatch(name: "Yarrow", hex: "#F6C345"),
                ColorSwatch(name: "Mimosa", hex: "#F0A83B"),
                ColorSwatch(name: "Amber", hex: "#ECA349"),
                ColorSwatch(name: "Burnt Coral", hex: "#E9897E"),
                ColorSwatch(name: "Emberglow", hex: "#EA6759"),
                ColorSwatch(name: "Cayenne", hex: "#E04951"),
                ColorSwatch(name: "Georgia Peach", hex: "#F97272"),
                ColorSwatch(name: "Hibiscus", hex: "#DD3848"),
                ColorSwatch(name: "Windsurfer", hex: "#99B9DD"),
                ColorSwatch(name: "Della Robbia Blue", hex: "#7DA3C6"),
                ColorSwatch(name: "Marina", hex: "#4F84C4"),
                ColorSwatch(name: "Directoire Blue", hex: "#0061A3"),
                ColorSwatch(name: "True Blue", hex: "#1E3F66"),
                ColorSwatch(name: "Spring Bouquet", hex: "#70C68E"),
                ColorSwatch(name: "Irish Green", hex: "#3FAD67"),
                ColorSwatch(name: "Biscay Green", hex: "#55C6A9"),
                ColorSwatch(name: "Holly Green", hex: "#199B65"),
                ColorSwatch(name: "Bosphorus", hex: "#007558"),
                ColorSwatch(name: "Daiquiri Green", hex: "#C9E37A"),
                ColorSwatch(name: "Bright Chartreuse", hex: "#B3CE50"),
                ColorSwatch(name: "Titanite", hex: "#9AA639"),
                ColorSwatch(name: "Salted Lime", hex: "#687C39"),
                ColorSwatch(name: "First Tee", hex: "#156D3F")
            ]
        case .lightSpring:
            return [
                ColorSwatch(name: "Shortbread", hex: "#F1DEC7"),
                ColorSwatch(name: "Whitecap Gray", hex: "#E3DACB"),
                ColorSwatch(name: "Alabaster Gleam", hex: "#F4E2C7"),
                ColorSwatch(name: "Lamb's Wool", hex: "#E8D0AE"),
                ColorSwatch(name: "Boulder", hex: "#D1BA9C"),
                ColorSwatch(name: "Ancient Scroll", hex: "#CBC3B7"),
                ColorSwatch(name: "Agate Gray", hex: "#B3B1A0"),
                ColorSwatch(name: "Driftwood", hex: "#887B75"),
                ColorSwatch(name: "Bungee Cord", hex: "#696256"),
                ColorSwatch(name: "Chocolate Chip", hex: "#5A4E44"),
                ColorSwatch(name: "Lemon Verbena", hex: "#F4E87C"),
                ColorSwatch(name: "Lemon Drop", hex: "#FDCE5B"),
                ColorSwatch(name: "Beach Ball", hex: "#F2B94A"),
                ColorSwatch(name: "Golden Haze", hex: "#F8D397"),
                ColorSwatch(name: "Sunset Gold", hex: "#F7BA5B"),
                ColorSwatch(name: "Strawberry Cream", hex: "#F4C4C2"),
                ColorSwatch(name: "Blossom", hex: "#F4B3B2"),
                ColorSwatch(name: "Candlelight Peach", hex: "#F89B93"),
                ColorSwatch(name: "Peach Blossom", hex: "#DE7879"),
                ColorSwatch(name: "Sun Kissed Coral", hex: "#EA5C6B"),
                ColorSwatch(name: "Lavender", hex: "#A99BC5"),
                ColorSwatch(name: "Bougainvillea", hex: "#987EA8"),
                ColorSwatch(name: "Deep Lavender", hex: "#734F82"),
                ColorSwatch(name: "Natural", hex: "#A8917F"),
                ColorSwatch(name: "Raw Umber", hex: "#926E5A"),
                ColorSwatch(name: "Atomizer", hex: "#99D1E9"),
                ColorSwatch(name: "Baltic Sea", hex: "#78B0D3"),
                ColorSwatch(name: "Blue Topaz", hex: "#73B4D3"),
                ColorSwatch(name: "Blue Curacao", hex: "#33B1C5"),
                ColorSwatch(name: "Blue Moon", hex: "#367D9C"),
                ColorSwatch(name: "Lettuce Green", hex: "#BED388"),
                ColorSwatch(name: "Jade Lime", hex: "#A1C66F"),
                ColorSwatch(name: "Bud Green", hex: "#73A75E"),
                ColorSwatch(name: "Poison Green", hex: "#4B9E5A"),
                ColorSwatch(name: "Mint", hex: "#009973")
            ]
        case .lightSummer:
            return [
                ColorSwatch(name: "Tofu", hex: "#E7E5D9"),
                ColorSwatch(name: "Bone White", hex: "#D7D1C1"),
                ColorSwatch(name: "Pelican", hex: "#C2BCAC"),
                ColorSwatch(name: "Atmosphere", hex: "#A99C94"),
                ColorSwatch(name: "Silent Storm", hex: "#827D77"),
                ColorSwatch(name: "Shadow Gray", hex: "#BAA5A0"),
                ColorSwatch(name: "Toadstool", hex: "#967C7F"),
                ColorSwatch(name: "Peppercorn", hex: "#6B5655"),
                ColorSwatch(name: "Plum Truffle", hex: "#665858"),
                ColorSwatch(name: "Catawba Grape", hex: "#5C3B42"),
                ColorSwatch(name: "Salmon Rose", hex: "#FF8E94"),
                ColorSwatch(name: "Dubarry", hex: "#F25F67"),
                ColorSwatch(name: "Sugar Coral", hex: "#F56C73"),
                ColorSwatch(name: "Paradise Pink", hex: "#E4445E"),
                ColorSwatch(name: "Winterberry", hex: "#BD3950"),
                ColorSwatch(name: "Candy Pink", hex: "#F4B0BD"),
                ColorSwatch(name: "Confetti", hex: "#E6798E"),
                ColorSwatch(name: "Sachet Pink", hex: "#F28AAD"),
                ColorSwatch(name: "Carmine Rose", hex: "#E45B8F"),
                ColorSwatch(name: "Lilac Rose", hex: "#BD4376"),
                ColorSwatch(name: "Open Air", hex: "#93B2E0"),
                ColorSwatch(name: "Vista Blue", hex: "#80A0D3"),
                ColorSwatch(name: "Granada Sky", hex: "#5D81BD"),
                ColorSwatch(name: "Star Sapphire", hex: "#35619E"),
                ColorSwatch(name: "Turkish Sea", hex: "#1A528F"),
                ColorSwatch(name: "Blue Elixir", hex: "#8ECBDD"),
                ColorSwatch(name: "River Blue", hex: "#38AECC"),
                ColorSwatch(name: "Capri", hex: "#44BAC8"),
                ColorSwatch(name: "Baltic", hex: "#269E9F"),
                ColorSwatch(name: "Pagoda Blue", hex: "#1B7F8E"),
                ColorSwatch(name: "Cabbage", hex: "#63DBBF"),
                ColorSwatch(name: "Mint Leaf", hex: "#02B694"),
                ColorSwatch(name: "Sea Green", hex: "#149B88"),
                ColorSwatch(name: "Simply Green", hex: "#179E75"),
                ColorSwatch(name: "Antique Green", hex: "#2A685D")
            ]
        case .trueSummer:
            return [
                ColorSwatch(name: "Light Gray", hex: "#DAD9CB"),
                ColorSwatch(name: "Perfectly Pale", hex: "#D2C9C0"),
                ColorSwatch(name: "Silver Cloud", hex: "#BDB7B2"),
                ColorSwatch(name: "Rock Ridge", hex: "#96918C"),
                ColorSwatch(name: "Major Brown", hex: "#625955"),
                ColorSwatch(name: "Lunar Rock", hex: "#C6C6C6"),
                ColorSwatch(name: "Ashes of Roses", hex: "#B7ADAD"),
                ColorSwatch(name: "Purple Dove", hex: "#A08D94"),
                ColorSwatch(name: "Moonscape", hex: "#76636C"),
                ColorSwatch(name: "Forged Iron", hex: "#454348"),
                ColorSwatch(name: "Dusty Blue", hex: "#8FA0B0"),
                ColorSwatch(name: "Troposphere", hex: "#7B8AA4"),
                ColorSwatch(name: "Gray Mist", hex: "#9EB5B3"),
                ColorSwatch(name: "Trooper", hex: "#6B7F80"),
                ColorSwatch(name: "Turbulence", hex: "#4E535A"),
                ColorSwatch(name: "Sea Pink", hex: "#D994A7"),
                ColorSwatch(name: "Chateau Rose", hex: "#CE7290"),
                ColorSwatch(name: "Bubblegum", hex: "#E96F8C"),
                ColorSwatch(name: "Carmine", hex: "#BA456B"),
                ColorSwatch(name: "Anemone", hex: "#812B49"),
                ColorSwatch(name: "Baby Lavender", hex: "#A4ACD4"),
                ColorSwatch(name: "Deep Periwinkle", hex: "#7F86BD"),
                ColorSwatch(name: "Corsican Blue", hex: "#625D91"),
                ColorSwatch(name: "Orient Blue", hex: "#494679"),
                ColorSwatch(name: "Blue Ribbon", hex: "#39385F"),
                ColorSwatch(name: "Crystal Seas", hex: "#5DB1C9"),
                ColorSwatch(name: "Wave Ride", hex: "#3084A6"),
                ColorSwatch(name: "Ipanema", hex: "#61B9C0"),
                ColorSwatch(name: "Larkspur", hex: "#3E7F90"),
                ColorSwatch(name: "Saxony Blue", hex: "#21667D"),
                ColorSwatch(name: "Neptune Green", hex: "#81BDA4"),
                ColorSwatch(name: "Ming Green", hex: "#39A17E"),
                ColorSwatch(name: "Ivy", hex: "#226B62"),
                ColorSwatch(name: "Teal", hex: "#4A8588"),
                ColorSwatch(name: "Chesapeake Bay", hex: "#15545C")
            ]
        case .softSummer:
            return [
                ColorSwatch(name: "Icicle", hex: "#D9DCD1"),
                ColorSwatch(name: "Birch", hex: "#DED6C8"),
                ColorSwatch(name: "Chateau Gray", hex: "#BDB3AB"),
                ColorSwatch(name: "Satellite", hex: "#9A908D"),
                ColorSwatch(name: "Iron", hex: "#766762"),
                ColorSwatch(name: "Mirage Gray", hex: "#AEB4B2"),
                ColorSwatch(name: "Sedona Sage", hex: "#696F6D"),
                ColorSwatch(name: "Gray Quill", hex: "#827E80"),
                ColorSwatch(name: "Thunderstorm", hex: "#5B585B"),
                ColorSwatch(name: "Raven", hex: "#3F3D3D"),
                ColorSwatch(name: "English Rose", hex: "#F3C6C3"),
                ColorSwatch(name: "Quartz Pink", hex: "#ECA1A7"),
                ColorSwatch(name: "Flowering Ginger", hex: "#E6878E"),
                ColorSwatch(name: "Slate Rose", hex: "#B45667"),
                ColorSwatch(name: "Earth Red", hex: "#93414F"),
                ColorSwatch(name: "Cameo Pink", hex: "#D9A7B5"),
                ColorSwatch(name: "Wild Rose", hex: "#C98095"),
                ColorSwatch(name: "Mesa Rose", hex: "#A96D7C"),
                ColorSwatch(name: "Hawthorn Rose", hex: "#854A5D"),
                ColorSwatch(name: "Blackberry Wine", hex: "#4C3044"),
                ColorSwatch(name: "Icelandic Blue", hex: "#A9ADC2"),
                ColorSwatch(name: "Purple Impression", hex: "#858FB1"),
                ColorSwatch(name: "Lavender Violet", hex: "#777CA6"),
                ColorSwatch(name: "Heron", hex: "#615F7C"),
                ColorSwatch(name: "Mood Indigo", hex: "#34394D"),
                ColorSwatch(name: "Leisure Time", hex: "#80BEC2"),
                ColorSwatch(name: "Porcelain", hex: "#5C9DA3"),
                ColorSwatch(name: "Hydro", hex: "#426B74"),
                ColorSwatch(name: "Arctic", hex: "#648589"),
                ColorSwatch(name: "Atlantic Deep", hex: "#244D53"),
                ColorSwatch(name: "Meadow", hex: "#8BBF9A"),
                ColorSwatch(name: "Beryl Green", hex: "#61948A"),
                ColorSwatch(name: "Hunter Green", hex: "#315548"),
                ColorSwatch(name: "Garden Glade", hex: "#DFDDAA"),
                ColorSwatch(name: "Shadow Green", hex: "#CEC68A")
            ]
        case .softAutumn:
            return [
                ColorSwatch(name: "Sweet Corn", hex: "#F0ECD7"),
                ColorSwatch(name: "White Asparagus", hex: "#E1DCCB"),
                ColorSwatch(name: "Turtledove", hex: "#DCD6C7"),
                ColorSwatch(name: "Overcast", hex: "#C3BEAC"),
                ColorSwatch(name: "Bog", hex: "#B9B69A"),
                ColorSwatch(name: "Sage Green", hex: "#ACAD8A"),
                ColorSwatch(name: "Aloe", hex: "#827D63"),
                ColorSwatch(name: "Olive Night", hex: "#514F3E"),
                ColorSwatch(name: "Sage", hex: "#969777"),
                ColorSwatch(name: "Beetle", hex: "#55574A"),
                ColorSwatch(name: "Burlwood", hex: "#9D736D"),
                ColorSwatch(name: "Russet", hex: "#936152"),
                ColorSwatch(name: "Carob Brown", hex: "#865E4D"),
                ColorSwatch(name: "Hot Chocolate", hex: "#673B3A"),
                ColorSwatch(name: "Rum Raisin", hex: "#573432"),
                ColorSwatch(name: "Coral Almond", hex: "#E59B90"),
                ColorSwatch(name: "Tea Rose", hex: "#D96F79"),
                ColorSwatch(name: "Holly Berry", hex: "#B44D60"),
                ColorSwatch(name: "Crabapple", hex: "#D77E70"),
                ColorSwatch(name: "Cardinal", hex: "#AD3D4A"),
                ColorSwatch(name: "Crystal Rose", hex: "#F9C1C5"),
                ColorSwatch(name: "Murex Shell", hex: "#F39DA2"),
                ColorSwatch(name: "Faded Rose", hex: "#BE6263"),
                ColorSwatch(name: "Baroque Rose", hex: "#AD5665"),
                ColorSwatch(name: "Tibetan Red", hex: "#762A3A"),
                ColorSwatch(name: "Dusk Blue", hex: "#7DA3C1"),
                ColorSwatch(name: "Blue Jasper", hex: "#507DA7"),
                ColorSwatch(name: "High Tide", hex: "#345D87"),
                ColorSwatch(name: "Deep Dive", hex: "#254655"),
                ColorSwatch(name: "Estate Blue", hex: "#233656"),
                ColorSwatch(name: "Ocean Wave", hex: "#8DC3B6"),
                ColorSwatch(name: "Dusty Jade Green", hex: "#7FB5A5"),
                ColorSwatch(name: "Bottle Green", hex: "#417D6D"),
                ColorSwatch(name: "Bristol Blue", hex: "#548D91"),
                ColorSwatch(name: "Mallard Green", hex: "#3D5B58")
            ]
        case .trueAutumn:
            return [
                ColorSwatch(name: "Seedpearl", hex: "#E6DCC5"),
                ColorSwatch(name: "Angora", hex: "#DFD0BB"),
                ColorSwatch(name: "Fog", hex: "#CEC5B2"),
                ColorSwatch(name: "Double Cream", hex: "#F4E1AD"),
                ColorSwatch(name: "Straw", hex: "#E1CA94"),
                ColorSwatch(name: "Tidal Foam", hex: "#C2BDA7"),
                ColorSwatch(name: "Oil Green", hex: "#838873"),
                ColorSwatch(name: "Lead Gray", hex: "#8F7D66"),
                ColorSwatch(name: "Stone Gray", hex: "#6B6151"),
                ColorSwatch(name: "Deep Depths", hex: "#414438"),
                ColorSwatch(name: "Peach Nougat", hex: "#E7AE91"),
                ColorSwatch(name: "Peach Bloom", hex: "#D99A7D"),
                ColorSwatch(name: "Cedar Wood", hex: "#A36A5E"),
                ColorSwatch(name: "Henna", hex: "#7D403A"),
                ColorSwatch(name: "Chicory Coffee", hex: "#49312D"),
                ColorSwatch(name: "Muskmelon", hex: "#ED9560"),
                ColorSwatch(name: "Amberglow", hex: "#DF793D"),
                ColorSwatch(name: "Orange Rust", hex: "#C35A3B"),
                ColorSwatch(name: "Summer Fig", hex: "#BF4C3A"),
                ColorSwatch(name: "Picante", hex: "#8C3D2C"),
                ColorSwatch(name: "Peach Amber", hex: "#F99F91"),
                ColorSwatch(name: "Porcelain Rose", hex: "#E9686A"),
                ColorSwatch(name: "American Beauty", hex: "#A82F40"),
                ColorSwatch(name: "Merlot", hex: "#76272E"),
                ColorSwatch(name: "Maroon Banner", hex: "#592A37"),
                ColorSwatch(name: "Sea Jet", hex: "#55B0BB"),
                ColorSwatch(name: "Bayou", hex: "#216D6B"),
                ColorSwatch(name: "Blue Mist", hex: "#5AAEC2"),
                ColorSwatch(name: "Biscay Bay", hex: "#087D87"),
                ColorSwatch(name: "Deep Teal", hex: "#19474A"),
                ColorSwatch(name: "Beechnut", hex: "#C3C294"),
                ColorSwatch(name: "Fern", hex: "#9BA16A"),
                ColorSwatch(name: "Split Pea", hex: "#9D9B3E"),
                ColorSwatch(name: "Fir Green", hex: "#6A592A"),
                ColorSwatch(name: "Forest Night", hex: "#414136")
            ]
        case .darkAutumn:
            return [
                ColorSwatch(name: "White Swan", hex: "#E4D8C7"),
                ColorSwatch(name: "Smoke Gray", hex: "#CDBBAA"),
                ColorSwatch(name: "Summer Melon", hex: "#EBD3AD"),
                ColorSwatch(name: "Autumn Blonde", hex: "#F0D0AE"),
                ColorSwatch(name: "Lattè", hex: "#C6A585"),
                ColorSwatch(name: "French Oak", hex: "#C9C0B4"),
                ColorSwatch(name: "Elephant Skin", hex: "#918B85"),
                ColorSwatch(name: "Tarmac", hex: "#5B5448"),
                ColorSwatch(name: "Savannah Tan", hex: "#AB9785"),
                ColorSwatch(name: "Pavement", hex: "#514C50"),
                ColorSwatch(name: "Ochre", hex: "#D7B066"),
                ColorSwatch(name: "Mustard Gold", hex: "#AD8E50"),
                ColorSwatch(name: "Cathay Spice", hex: "#99632D"),
                ColorSwatch(name: "Butternum", hex: "#C89169"),
                ColorSwatch(name: "Sunburn", hex: "#B5745B"),
                ColorSwatch(name: "Blooming Dahlia", hex: "#ED9588"),
                ColorSwatch(name: "Burnt Sienna", hex: "#C65D53"),
                ColorSwatch(name: "Cranberry", hex: "#B8474F"),
                ColorSwatch(name: "Burnt Russet", hex: "#7C3940"),
                ColorSwatch(name: "Pomegranate", hex: "#672830"),
                ColorSwatch(name: "Pastel Lavender", hex: "#D6A0C3"),
                ColorSwatch(name: "Spring Crocus", hex: "#B6659E"),
                ColorSwatch(name: "Rosé Sorbet", hex: "#A0467C"),
                ColorSwatch(name: "Plum Caspia", hex: "#5B2147"),
                ColorSwatch(name: "Titan", hex: "#283D53"),
                ColorSwatch(name: "Bermuda", hex: "#60C4B1"),
                ColorSwatch(name: "Lagoon", hex: "#4D9E9B"),
                ColorSwatch(name: "Frosty Spruce", hex: "#568271"),
                ColorSwatch(name: "Evergreen", hex: "#105448"),
                ColorSwatch(name: "Green Gables", hex: "#344343"),
                ColorSwatch(name: "Willow", hex: "#9C8F4F"),
                ColorSwatch(name: "Plantation", hex: "#79612F"),
                ColorSwatch(name: "Military Olive", hex: "#5F523B"),
                ColorSwatch(name: "Wren", hex: "#494039"),
                ColorSwatch(name: "Glamour Gold", hex: "#C3A06B")
            ]
        case .darkWinter:
            return [
                ColorSwatch(name: "Lucent White", hex: "#F2F5FC"),
                ColorSwatch(name: "Vaporous Gray", hex: "#DEDDD7"),
                ColorSwatch(name: "Pumice Stone", hex: "#C9C3BA"),
                ColorSwatch(name: "Ghost Gray", hex: "#9D9D9B"),
                ColorSwatch(name: "Charcoal Gray", hex: "#6D696A"),
                ColorSwatch(name: "Lemonade", hex: "#F0E69C"),
                ColorSwatch(name: "Ballet Slipper", hex: "#EBCDD4"),
                ColorSwatch(name: "Bay", hex: "#B7E4D6"),
                ColorSwatch(name: "Spun Sugar", hex: "#B3DDE8"),
                ColorSwatch(name: "Purple Heather", hex: "#B8B5D0"),
                ColorSwatch(name: "Plumeria", hex: "#F58DA1"),
                ColorSwatch(name: "Fruit Dove", hex: "#D05776"),
                ColorSwatch(name: "Bossy Pink", hex: "#CF3566"),
                ColorSwatch(name: "Innuendo", hex: "#C32F62"),
                ColorSwatch(name: "Red Bud", hex: "#922C4A"),
                ColorSwatch(name: "Lipstick Red", hex: "#B51D3D"),
                ColorSwatch(name: "Scarlet Smile", hex: "#9E253A"),
                ColorSwatch(name: "Rio Red", hex: "#862336"),
                ColorSwatch(name: "Rhubarb", hex: "#76212F"),
                ColorSwatch(name: "Zinfandel", hex: "#582833"),
                ColorSwatch(name: "African Violet", hex: "#B184B7"),
                ColorSwatch(name: "Bellflower", hex: "#94649D"),
                ColorSwatch(name: "Plum Jam", hex: "#633F78"),
                ColorSwatch(name: "Grape Royale", hex: "#512D52"),
                ColorSwatch(name: "Baritone Blue", hex: "#252633"),
                ColorSwatch(name: "Splish Splash", hex: "#67B9D8"),
                ColorSwatch(name: "Mediterranean Blue", hex: "#147BA4"),
                ColorSwatch(name: "Moroccan Blue", hex: "#104F67"),
                ColorSwatch(name: "Deep Water", hex: "#28688D"),
                ColorSwatch(name: "Pageant Blue", hex: "#202D46"),
                ColorSwatch(name: "Marine Green", hex: "#3EA38F"),
                ColorSwatch(name: "Lush Meadow", hex: "#007257"),
                ColorSwatch(name: "Forest Biome", hex: "#194C47"),
                ColorSwatch(name: "Ponderosa Pine", hex: "#1F3F3F"),
                ColorSwatch(name: "Tap Shoe", hex: "#29292B")
            ]
        case .trueWinter:
            return [
                ColorSwatch(name: "Brilliant White", hex: "#EEF1FF"),
                ColorSwatch(name: "Lily White", hex: "#E3E3DB"),
                ColorSwatch(name: "Silver Birch", hex: "#D1D0C5"),
                ColorSwatch(name: "Mourning Dove", hex: "#99948F"),
                ColorSwatch(name: "Brushed Nickel", hex: "#706E6D"),
                ColorSwatch(name: "Tender Touch", hex: "#F2D5DF"),
                ColorSwatch(name: "Elfin Yellow", hex: "#F0E99A"),
                ColorSwatch(name: "Misty Jade", hex: "#B8D8C8"),
                ColorSwatch(name: "Spa Retreat", hex: "#B1E4E9"),
                ColorSwatch(name: "Halogen Blue", hex: "#BBC5DC"),
                ColorSwatch(name: "Pirouette", hex: "#E9B9D9"),
                ColorSwatch(name: "Bonbon", hex: "#EDA0CC"),
                ColorSwatch(name: "Strawberry Moon", hex: "#D7659F"),
                ColorSwatch(name: "Very Berry", hex: "#B72F75"),
                ColorSwatch(name: "Wild Aster", hex: "#8F2E70"),
                ColorSwatch(name: "Lilac Chiffon", hex: "#D995C1"),
                ColorSwatch(name: "Violet", hex: "#BB80B7"),
                ColorSwatch(name: "Radiant Orchid", hex: "#A75A98"),
                ColorSwatch(name: "Hollyhock", hex: "#80336F"),
                ColorSwatch(name: "Charisma", hex: "#62295F"),
                ColorSwatch(name: "Persian Jewel", hex: "#7184C1"),
                ColorSwatch(name: "Amparo Blue", hex: "#4B61A4"),
                ColorSwatch(name: "Surf the Web", hex: "#233F7E"),
                ColorSwatch(name: "Bellwether Blue", hex: "#25345F"),
                ColorSwatch(name: "Ocean Cavern", hex: "#252940"),
                ColorSwatch(name: "Cyan Blue", hex: "#12A2C3"),
                ColorSwatch(name: "Faience", hex: "#2D6F8E"),
                ColorSwatch(name: "Spectra Green", hex: "#009B8E"),
                ColorSwatch(name: "Tidepool", hex: "#08736C"),
                ColorSwatch(name: "Green Heron", hex: "#285258"),
                ColorSwatch(name: "Gentian Violet", hex: "#514071"),
                ColorSwatch(name: "Navy Blue", hex: "#3D3D70"),
                ColorSwatch(name: "Medieval Blue", hex: "#292F50"),
                ColorSwatch(name: "Bracken", hex: "#4D3D39"),
                ColorSwatch(name: "Môle", hex: "#382B2A")
            ]
        case .brightWinter:
            return [
                ColorSwatch(name: "Bright White", hex: "#F3F8FF"),
                ColorSwatch(name: "Arctic Wolf", hex: "#E6DFCE"),
                ColorSwatch(name: "Abbey Stone", hex: "#ADA99B"),
                ColorSwatch(name: "Steeple Gray", hex: "#858180"),
                ColorSwatch(name: "Steel Gray", hex: "#747273"),
                ColorSwatch(name: "Pastel Yellow", hex: "#F2E7B0"),
                ColorSwatch(name: "Pink Dogwood", hex: "#F5D0D1"),
                ColorSwatch(name: "Fair Aqua", hex: "#B8E2DC"),
                ColorSwatch(name: "Festival Bloom", hex: "#F2D5E5"),
                ColorSwatch(name: "Pastel Lilac", hex: "#BFB3CA"),
                ColorSwatch(name: "Ranunculus", hex: "#EC898D"),
                ColorSwatch(name: "Honeysuckle", hex: "#D74770"),
                ColorSwatch(name: "Raspberry Sorbet", hex: "#D03168"),
                ColorSwatch(name: "Vivacious", hex: "#A32658"),
                ColorSwatch(name: "Red Plum", hex: "#762744"),
                ColorSwatch(name: "Fuchsia Purple", hex: "#D12F79"),
                ColorSwatch(name: "Fuchsia Fedora", hex: "#C63F87"),
                ColorSwatch(name: "Fuchsia Red", hex: "#A83276"),
                ColorSwatch(name: "Rose Violet", hex: "#BD428B"),
                ColorSwatch(name: "Purple Wine", hex: "#853675"),
                ColorSwatch(name: "Iolite", hex: "#737DB7"),
                ColorSwatch(name: "Blue Iris", hex: "#5B5B9B"),
                ColorSwatch(name: "Bluing", hex: "#303F82"),
                ColorSwatch(name: "Ultramarine", hex: "#5B7DBD"),
                ColorSwatch(name: "Dazzling Blue", hex: "#38539D"),
                ColorSwatch(name: "Aged Copper", hex: "#5BC5D0"),
                ColorSwatch(name: "Viridian Green", hex: "#009697"),
                ColorSwatch(name: "Blue Blossom", hex: "#2DA8D3"),
                ColorSwatch(name: "Blithe", hex: "#0085B8"),
                ColorSwatch(name: "Turkish Tile", hex: "#006C87"),
                ColorSwatch(name: "Black Iris", hex: "#2C3043"),
                ColorSwatch(name: "Black Ink", hex: "#45413D"),
                ColorSwatch(name: "Blackened Pearl", hex: "#4E4B50"),
                ColorSwatch(name: "Pirate Black", hex: "#343636"),
                ColorSwatch(name: "Anthracite", hex: "#26262B")
            ]
        }
    }

    /// Representative sample swatches (5 primary accent colors) for UI accents and color wheels.
    public var sampleSwatches: [ColorSwatch] {
        switch self {
        case .brightSpring:
            return [
                ColorSwatch(name: "Snow White", hex: "#F2F0EB"),
                ColorSwatch(name: "Aspen Gold", hex: "#FFD662"),
                ColorSwatch(name: "Hot Pink", hex: "#E55982"),
                ColorSwatch(name: "Tropical Green", hex: "#008786"),
                ColorSwatch(name: "Imperial Blue", hex: "#005A92")
            ]
        case .trueSpring:
            return [
                ColorSwatch(name: "Vanilla", hex: "#F3E5C8"),
                ColorSwatch(name: "Sunshine", hex: "#FAD055"),
                ColorSwatch(name: "Georgia Peach", hex: "#F97272"),
                ColorSwatch(name: "Irish Green", hex: "#3FAD67"),
                ColorSwatch(name: "Directoire Blue", hex: "#0061A3")
            ]
        case .lightSpring:
            return [
                ColorSwatch(name: "Shortbread", hex: "#F1DEC7"),
                ColorSwatch(name: "Lemon Drop", hex: "#FDCE5B"),
                ColorSwatch(name: "Sun Kissed Coral", hex: "#EA5C6B"),
                ColorSwatch(name: "Blue Curacao", hex: "#33B1C5"),
                ColorSwatch(name: "Mint", hex: "#009973")
            ]
        case .lightSummer:
            return [
                ColorSwatch(name: "Tofu", hex: "#E7E5D9"),
                ColorSwatch(name: "Candy Pink", hex: "#F4B0BD"),
                ColorSwatch(name: "Mint Leaf", hex: "#02B694"),
                ColorSwatch(name: "River Blue", hex: "#38AECC"),
                ColorSwatch(name: "Star Sapphire", hex: "#35619E")
            ]
        case .trueSummer:
            return [
                ColorSwatch(name: "Light Gray", hex: "#DAD9CB"),
                ColorSwatch(name: "Sea Pink", hex: "#D994A7"),
                ColorSwatch(name: "Deep Periwinkle", hex: "#7F86BD"),
                ColorSwatch(name: "Ming Green", hex: "#39A17E"),
                ColorSwatch(name: "Major Brown", hex: "#625955")
            ]
        case .softSummer:
            return [
                ColorSwatch(name: "Birch", hex: "#DED6C8"),
                ColorSwatch(name: "English Rose", hex: "#F3C6C3"),
                ColorSwatch(name: "Porcelain", hex: "#5C9DA3"),
                ColorSwatch(name: "Meadow", hex: "#8BBF9A"),
                ColorSwatch(name: "Mood Indigo", hex: "#34394D")
            ]
        case .softAutumn:
            return [
                ColorSwatch(name: "Sweet Corn", hex: "#F0ECD7"),
                ColorSwatch(name: "Coral Almond", hex: "#E59B90"),
                ColorSwatch(name: "Sage Green", hex: "#ACAD8A"),
                ColorSwatch(name: "Blue Jasper", hex: "#507DA7"),
                ColorSwatch(name: "Carob Brown", hex: "#865E4D")
            ]
        case .trueAutumn:
            return [
                ColorSwatch(name: "Seedpearl", hex: "#E6DCC5"),
                ColorSwatch(name: "Amberglow", hex: "#DF793D"),
                ColorSwatch(name: "Fern", hex: "#9BA16A"),
                ColorSwatch(name: "Biscay Bay", hex: "#087D87"),
                ColorSwatch(name: "Chicory Coffee", hex: "#49312D")
            ]
        case .darkAutumn:
            return [
                ColorSwatch(name: "White Swan", hex: "#E4D8C7"),
                ColorSwatch(name: "Mustard Gold", hex: "#AD8E50"),
                ColorSwatch(name: "Burnt Sienna", hex: "#C65D53"),
                ColorSwatch(name: "Evergreen", hex: "#105448"),
                ColorSwatch(name: "Tarmac", hex: "#5B5448")
            ]
        case .darkWinter:
            return [
                ColorSwatch(name: "Lucent White", hex: "#F2F5FC"),
                ColorSwatch(name: "Fruit Dove", hex: "#D05776"),
                ColorSwatch(name: "Lush Meadow", hex: "#007257"),
                ColorSwatch(name: "Mediterranean Blue", hex: "#147BA4"),
                ColorSwatch(name: "Tap Shoe", hex: "#29292B")
            ]
        case .trueWinter:
            return [
                ColorSwatch(name: "Brilliant White", hex: "#EEF1FF"),
                ColorSwatch(name: "Very Berry", hex: "#B72F75"),
                ColorSwatch(name: "Spectra Green", hex: "#009B8E"),
                ColorSwatch(name: "Amparo Blue", hex: "#4B61A4"),
                ColorSwatch(name: "Medieval Blue", hex: "#292F50")
            ]
        case .brightWinter:
            return [
                ColorSwatch(name: "Bright White", hex: "#F3F8FF"),
                ColorSwatch(name: "Honeysuckle", hex: "#D74770"),
                ColorSwatch(name: "Viridian Green", hex: "#009697"),
                ColorSwatch(name: "Dazzling Blue", hex: "#38539D"),
                ColorSwatch(name: "Black Iris", hex: "#2C3043")
            ]
        }
    }

    // MARK: - Color Season Wheel Palette

    /// 20 chromatic hex color wedges rendered clockwise from 12 o'clock on the ColorSeasonWheelView & ProfileSeasonRingAvatarView.
    public var wheelHexColors: [String] {
        switch self {
        case .brightSpring:
            return [
                "#F2F0EB", "#005A92", "#2E5283", "#3A5589", "#273C76",
                "#802A50", "#B93A32", "#CC4385", "#E55982", "#F2AB46",
                "#FFD662", "#C6E67A", "#008786", "#227949", "#1F5129",
                "#4D4C47", "#82776B", "#CBC3B4", "#ECDDBE", "#F0EADA"
            ]
        case .trueSpring:
            return [
                "#F3E5C8", "#C9E37A", "#9AA639", "#3FAD67", "#156D3F",
                "#1E3F66", "#0061A3", "#4F84C4", "#99B9DD", "#F97272",
                "#EA6759", "#F0A83B", "#FAD055", "#704F3B", "#40342B",
                "#8F7D66", "#BEA987", "#BD9865", "#E0B589", "#F2D1A0"
            ]
        case .lightSpring:
            return [
                "#F4E2C7", "#4B9E5A", "#33B1C5", "#009973", "#199B65",
                "#3D5B58", "#19474A", "#1A528F", "#5D81BD", "#93B2E0",
                "#F89B93", "#EA5C6B", "#E6798E", "#E55982", "#BD3950",
                "#967C7F", "#887B75", "#696256", "#F8D397", "#E3DACB"
            ]
        case .lightSummer:
            return [
                "#F4E2C7", "#2A685D", "#179E75", "#269E9F", "#38AECC",
                "#63DBBF", "#93B2E0", "#5D81BD", "#1A528F", "#BD3950",
                "#E45B8F", "#F56C73", "#FF8E94", "#F4B0BD", "#967C7F",
                "#827D77", "#6B5655", "#A99C94", "#C2BCAC", "#D7D1C1"
            ]
        case .trueSummer:
            return [
                "#DAD9CB", "#CE7290", "#BA456B", "#39385F", "#625D91",
                "#A4ACD4", "#8FA0B0", "#9EB5B3", "#81BDA4", "#3084A6",
                "#21667D", "#226B62", "#15545C", "#4E535A", "#625955",
                "#76636C", "#A08D94", "#B7ADAD", "#BDB7B2", "#D2C9C0"
            ]
        case .softSummer:
            return [
                "#D9DCD1", "#CEC68A", "#93414F", "#854A5D", "#E6878E",
                "#C98095", "#F3C6C3", "#A9ADC2", "#777CA6", "#34394D",
                "#315548", "#8BBF9A", "#5C9DA3", "#426B74", "#696F6D",
                "#5B585B", "#3F3D3D", "#766762", "#9A908D", "#BDB3AB"
            ]
        case .softAutumn:
            return [
                "#F0ECD7", "#F9C1C5", "#E59B90", "#D96F79", "#BE6263",
                "#762A3A", "#3D5B58", "#417D6D", "#8DC3B6", "#507DA7",
                "#254655", "#573432", "#865E4D", "#9D736D", "#827D63",
                "#969777", "#ACAD8A", "#C3BEAC", "#DCD6C7", "#E1DCCB"
            ]
        case .trueAutumn:
            return [
                "#E6DCC5", "#55B0BB", "#216D6B", "#19474A", "#6B6151",
                "#6A592A", "#838873", "#9BA16A", "#D99A7D", "#F99F91",
                "#DF793D", "#BF4C3A", "#A82F40", "#592A37", "#49312D",
                "#414438", "#A36A5E", "#E1CA94", "#CEC5B2", "#DFD0BB"
            ]
        case .darkAutumn:
            return [
                "#E4D8C7", "#283D53", "#105448", "#4D9E9B", "#9C8F4F",
                "#D6A0C3", "#A0467C", "#7C3940", "#C65D53", "#B5745B",
                "#D7B066", "#AD8E50", "#99632D", "#5F523B", "#5B5448",
                "#918B85", "#AB9785", "#C6A585", "#F0D0AE", "#EBD3AD"
            ]
        case .darkWinter:
            return [
                "#F2F5FC", "#B3DDE8", "#147BA4", "#28688D", "#3EA38F",
                "#194C47", "#862336", "#9E253A", "#B51D3D", "#CF3566",
                "#F58DA1", "#EBCDD4", "#B184B7", "#633F78", "#252633",
                "#29292B", "#6D696A", "#9D9D9B", "#C9C3BA", "#DEDDD7"
            ]
        case .trueWinter:
            return [
                "#EEF1FF", "#F0E99A", "#252940", "#514071", "#62295F",
                "#8F2E70", "#B72F75", "#D7659F", "#A75A98", "#EDA0CC",
                "#7184C1", "#B1E4E9", "#08736C", "#2D6F8E", "#233F7E",
                "#292F50", "#382B2A", "#706E6D", "#D1D0C5", "#E3E3DB"
            ]
        case .brightWinter:
            return [
                "#F3F8FF", "#F2D5E5", "#F5D0D1", "#EC898D", "#D74770",
                "#D03168", "#C63F87", "#762744", "#737DB7", "#009697",
                "#0085B8", "#38539D", "#303F82", "#2C3043", "#26262B",
                "#343636", "#4E4B50", "#747273", "#858180", "#ADA99B"
            ]
        }
    }

    // MARK: - Foundation / Neutral Palette Swatches

    /// 6 foundation / neutral swatches used to ground the seasonal palette.
    public var neutralSwatches: [ColorSwatch] {
        switch self {
        case .brightSpring:
            return [
                ColorSwatch(name: "Snow White", hex: "#F2F0EB"),
                ColorSwatch(name: "Rutabaga", hex: "#ECDDBE"),
                ColorSwatch(name: "Silver Lining", hex: "#BDB6AB"),
                ColorSwatch(name: "Dark Navy", hex: "#17406B"),
                ColorSwatch(name: "Chimera", hex: "#4D4C47"),
                ColorSwatch(name: "Dark Charcoal", hex: "#3B3739")
            ]
        case .trueSpring:
            return [
                ColorSwatch(name: "Vanilla", hex: "#F3E5C8"),
                ColorSwatch(name: "Warm Stone", hex: "#D3CAAF"),
                ColorSwatch(name: "Golden Mist", hex: "#D5CD94"),
                ColorSwatch(name: "Rich Warm Brown", hex: "#56352D"),
                ColorSwatch(name: "Demitasse", hex: "#40342B"),
                ColorSwatch(name: "Dark Olive Charcoal", hex: "#46483D")
            ]
        case .lightSpring:
            return [
                ColorSwatch(name: "Shortbread", hex: "#F1DEC7"),
                ColorSwatch(name: "Ancient Scroll", hex: "#CBC3B7"),
                ColorSwatch(name: "Light Warm Sand", hex: "#D2CBAF"),
                ColorSwatch(name: "Bungee Cord", hex: "#696256"),
                ColorSwatch(name: "Muted Olive Gray", hex: "#696B62"),
                ColorSwatch(name: "Soft Charcoal", hex: "#575358")
            ]
        case .lightSummer:
            return [
                ColorSwatch(name: "Tofu", hex: "#E7E5D9"),
                ColorSwatch(name: "Light Ash Gray", hex: "#AFB3B6"),
                ColorSwatch(name: "Shadow Gray", hex: "#BAA5A0"),
                ColorSwatch(name: "Slate Blue", hex: "#4F677B"),
                ColorSwatch(name: "Catawba Grape", hex: "#5C3B42"),
                ColorSwatch(name: "Cool Charcoal", hex: "#5C5657")
            ]
        case .trueSummer:
            return [
                ColorSwatch(name: "Light Gray", hex: "#DAD9CB"),
                ColorSwatch(name: "Lunar Rock", hex: "#C6C6C6"),
                ColorSwatch(name: "Soft Steel Blue", hex: "#A2B4C4"),
                ColorSwatch(name: "Cool Navy", hex: "#284972"),
                ColorSwatch(name: "Cool Plum Brown", hex: "#5F4B51"),
                ColorSwatch(name: "Forged Iron", hex: "#454348")
            ]
        case .softSummer:
            return [
                ColorSwatch(name: "Icicle", hex: "#D9DCD1"),
                ColorSwatch(name: "Chateau Gray", hex: "#BDB3AB"),
                ColorSwatch(name: "Mirage Gray", hex: "#AEB4B2"),
                ColorSwatch(name: "Iron", hex: "#766762"),
                ColorSwatch(name: "Muted Espresso", hex: "#493F41"),
                ColorSwatch(name: "Raven", hex: "#3F3D3D")
            ]
        case .softAutumn:
            return [
                ColorSwatch(name: "Sweet Corn", hex: "#F0ECD7"),
                ColorSwatch(name: "Overcast", hex: "#C3BEAC"),
                ColorSwatch(name: "Warm Camel", hex: "#CCA57F"),
                ColorSwatch(name: "Olive Night", hex: "#514F3E"),
                ColorSwatch(name: "Rum Raisin", hex: "#573432"),
                ColorSwatch(name: "Warm Charcoal", hex: "#494743")
            ]
        case .trueAutumn:
            return [
                ColorSwatch(name: "Seedpearl", hex: "#E6DCC5"),
                ColorSwatch(name: "Warm Bisque", hex: "#EECFB9"),
                ColorSwatch(name: "Tidal Foam", hex: "#C2BDA7"),
                ColorSwatch(name: "Deep Depths", hex: "#414438"),
                ColorSwatch(name: "Chicory Coffee", hex: "#49312D"),
                ColorSwatch(name: "Dark Earth Charcoal", hex: "#3C3B35")
            ]
        case .darkAutumn:
            return [
                ColorSwatch(name: "White Swan", hex: "#E4D8C7"),
                ColorSwatch(name: "Summer Melon", hex: "#EBD3AD"),
                ColorSwatch(name: "French Oak", hex: "#C9C0B4"),
                ColorSwatch(name: "Deep Midnight Navy", hex: "#263056"),
                ColorSwatch(name: "Dark Forest Slate", hex: "#24312D"),
                ColorSwatch(name: "Dark Charcoal Black", hex: "#2F2D30")
            ]
        case .darkWinter:
            return [
                ColorSwatch(name: "Lucent White", hex: "#F2F5FC"),
                ColorSwatch(name: "Vaporous Gray", hex: "#DEDDD7"),
                ColorSwatch(name: "Cool Pale Silver", hex: "#D1D5D0"),
                ColorSwatch(name: "Baritone Blue", hex: "#252633"),
                ColorSwatch(name: "Ponderosa Pine", hex: "#1F3F3F"),
                ColorSwatch(name: "Tap Shoe", hex: "#29292B")
            ]
        case .trueWinter:
            return [
                ColorSwatch(name: "Brilliant White", hex: "#EEF1FF"),
                ColorSwatch(name: "Lily White", hex: "#E3E3DB"),
                ColorSwatch(name: "Icy Silver Gray", hex: "#D9DBDE"),
                ColorSwatch(name: "Ocean Cavern", hex: "#252940"),
                ColorSwatch(name: "Môle", hex: "#382B2A"),
                ColorSwatch(name: "Jet Black", hex: "#26262A")
            ]
        case .brightWinter:
            return [
                ColorSwatch(name: "Bright White", hex: "#F3F8FF"),
                ColorSwatch(name: "Arctic Wolf", hex: "#E6DFCE"),
                ColorSwatch(name: "Icy Light Gray", hex: "#D5D5D8"),
                ColorSwatch(name: "Deep Indigo Navy", hex: "#302453"),
                ColorSwatch(name: "Slate Charcoal", hex: "#5D5B60"),
                ColorSwatch(name: "Carbon Black", hex: "#39373B")
            ]
        }
    }

    /// All valid swatches for this season, with foundation neutrals prioritized first followed by the seasonal palette.
    public var allSwatches: [ColorSwatch] {
        var seen = Set<String>()
        var result: [ColorSwatch] = []
        for swatch in neutralSwatches + palette {
            let key = swatch.hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
            if seen.insert(key).inserted {
                result.append(swatch)
            }
        }
        return result
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
        Neutral Colors (Prioritize First): \(neutralSwatches.map { "\($0.name) (\($0.hex))" }.joined(separator: ", "))
        Color Palette: \(palette.map { "\($0.name) (\($0.hex))" }.joined(separator: ", "))
        """
    }

    /// Generates structured prompt context for LLM recommendation prompts (matching StyleVision's `llmPromptContext`).
    public var llmPromptContext: String {
        systemPrompt
    }
}
