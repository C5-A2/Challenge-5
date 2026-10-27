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

    public struct ColorSwatch: Sendable, Hashable, Identifiable {
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

    // MARK: - Season Attributes

    /// Definition and prominent visual features.
    public var definition: String {
        switch self {
        case .brightSpring:
            return "Bright Spring is the combination of bright and warm. The most prominent characteristic is the clearness of features, giving a bright, luminous, and fresh appearance."
        case .trueSpring:
            return "True Spring is the combination of warm and bright. It is characterized by a sunny, glowing appearance with no trace of coolness."
        case .lightSpring:
            return "Light Spring is the combination of light and warm. Flowing from Spring into Summer, it combines Spring warmth with Summer delicacy."
        case .lightSummer:
            return "Light Summer is the combination of light and cool. Features neutral-cool, delicate, ice-cream-like colors with low contrast."
        case .trueSummer:
            return "True Summer is the combination of cool and muted. As the coolest season of the Summer family, features have a gentle, watery coolness."
        case .softSummer:
            return "Soft Summer is the combination of muted and cool. Flowing from Summer into Autumn, features are gently greyed out with an understated appearance."
        case .softAutumn:
            return "Soft Autumn is the combination of muted and warm. Flowing from Summer into Autumn, features are soft, walnut-tinted, and gentle."
        case .trueAutumn:
            return "True Autumn is the combination of warm and muted. Features comprise rich, earthy foliage-like colors with warm bronze undertones."
        case .darkAutumn:
            return "Dark Autumn is the combination of dark and warm. Flowing from Autumn into Winter, it combines deep bronzy warmth with dark depth."
        case .darkWinter:
            return "Dark Winter is the combination of dark and cool. Features prominent dark features set against lighter skin with frosty intensity."
        case .trueWinter:
            return "True Winter is the combination of cool and bright. Features have a frost-like coolness and striking, brilliant contrast."
        case .brightWinter:
            return "Bright Winter is the combination of bright and cool. Flowing from Winter into Spring, it features clear, striking saturation with frosted brilliance."
        }
    }

    /// Primary & secondary tonal aspects (Act).
    public var act: String {
        switch self {
        case .brightSpring:
            return "Primary aspect is Bright (highly saturated, clear), secondary aspect is Warm (neutral-warm). High contrast with vivid eyes."
        case .trueSpring:
            return "Primary aspect is Warm (pure warm golden undertones), secondary aspect is Bright (fresh, vibrant). Medium contrast."
        case .lightSpring:
            return "Primary aspect is Light (absence of dark depth), secondary aspect is Warm (neutral-warm). Low overall contrast."
        case .lightSummer:
            return "Primary aspect is Light (light features, low contrast), secondary aspect is Cool (neutral-cool). Low contrast."
        case .trueSummer:
            return "Primary aspect is Cool (pure cool undertones), secondary aspect is Muted (softened, greyed out). Gentle contrast."
        case .softSummer:
            return "Primary aspect is Muted (high grey pigments), secondary aspect is Cool (neutral-cool). Blended, low contrast."
        case .softAutumn:
            return "Primary aspect is Muted (low contrast, blended), secondary aspect is Warm (neutral-warm olive undertones)."
        case .trueAutumn:
            return "Primary aspect is Warm (pure warm golden/bronze undertones), secondary aspect is Muted (rich, non-vibrant). Medium contrast."
        case .darkAutumn:
            return "Primary aspect is Dark (deep hair/eyes, high contrast), secondary aspect is Warm (neutral-warm undertones)."
        case .darkWinter:
            return "Primary aspect is Dark (deep hair/eyes, high contrast), secondary aspect is Cool (neutral-cool undertones)."
        case .trueWinter:
            return "Primary aspect is Cool (pure cool blue undertones), secondary aspect is Bright (vibrant, icy contrast)."
        case .brightWinter:
            return "Primary aspect is Bright (extreme saturation and clarity), secondary aspect is Cool (neutral-cool). Maximum vibrancy."
        }
    }

    /// Color styling combination guidelines.
    public var colorCombinationRules: String {
        switch self {
        case .brightSpring:
            return "High hue contrast is key. Combine contrasting colors across the color wheel (e.g. pink and green) or pair dark neutrals with bright accents."
        case .trueSpring:
            return "Pair warm colors together in tonal mixes; combine bright warm shades with light warm neutrals (camel, warm ivory)."
        case .lightSpring:
            return "Low-to-medium contrast, delicate or tonal combinations; pair light colorful tints together or with light warm neutrals."
        case .lightSummer:
            return "Gentle, low-contrast combinations; pair light cool pastels together or combine with soft neutrals (ash grey, heather blue)."
        case .trueSummer:
            return "Cool, gentle, tonal combinations; pair cool medium tones with soft cool neutrals (slate, soft navy, cool white)."
        case .softSummer:
            return "Monochromatic, blended, low-contrast outfits; pair muted cool tones with soft neutrals (grey, taupe, soft rose)."
        case .softAutumn:
            return "Tone-on-tone, low-contrast earthy combinations; blend soft warm shades together (olive, wheat, dusty rose, terracotta)."
        case .trueAutumn:
            return "Warm earthy combinations; combine rich warm tones (mustard, rust, olive) with rich warm neutrals (chocolate, camel)."
        case .darkAutumn:
            return "Deep, high-value contrast combinations; pair rich dark shades with warm light neutrals (cream, warm bronze)."
        case .darkWinter:
            return "High-contrast combinations; pair deep dark neutrals (black, deep navy) with light icy accents or vivid cool jewels."
        case .trueWinter:
            return "Stark, high value & hue contrast; pair icy light shades directly with dark/vibrant cool shades (stark white & black, royal blue)."
        case .brightWinter:
            return "High-contrast combinations; pair bright cool colors with black, white, or dark navy, or combine vivid complementary colors."
        }
    }

    /// Colors that disharmonize with this season.
    public var colorsToAvoid: String {
        switch self {
        case .brightSpring:
            return "Muted, dusty, or desaturated colors (dusty blue, muddy brown) and very cool icy shades."
        case .trueSpring:
            return "Cool colors (fuchsia, icy blue, silver), muted/ashy tones (cool grey, taupe), and stark black or harsh cool white."
        case .lightSpring:
            return "Very dark colors (black, deep navy, dark chocolate), cool icy shades, and greyish muted tones."
        case .lightSummer:
            return "Dark colors (black, deep burgundy, dark chocolate), warm golden colors (orange, mustard), and heavy saturated shades."
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
            return "Muted, dusty, desaturated colors (dusty rose, sage green) and warm golden/earthy shades (orange, mustard)."
        }
    }

    // MARK: - Curated Primary Accent Hex Colors

    /// Representative palette swatches for UI accents and color wheels.
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
                ColorSwatch(name: "Vanilla", pantoneCode: "12-0712 TCX", hex: "#F3E5C8"),
                ColorSwatch(name: "Mimosa", pantoneCode: "14-0848 TCX", hex: "#F0A83B"),
                ColorSwatch(name: "Burnt Coral", pantoneCode: "16-1529 TCX", hex: "#E9897E"),
                ColorSwatch(name: "Biscay Green", pantoneCode: "15-5718 TCX", hex: "#55C6A9"),
                ColorSwatch(name: "Marina", pantoneCode: "17-4041 TCX", hex: "#4F84C4")
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

    // MARK: - Color Season Wheel Palette (12 Chromatic Hues)

    /// 12 representative chromatic colors for rendering the seasonal color wheel.
    public var wheelHexColors: [String] {
        switch self {
        case .brightSpring:
            return ["#F2F0EB", "#FFD662", "#F2AB46", "#B93A32", "#E55982", "#DA3D58", "#CC4385", "#005A92", "#58C9D4", "#008786", "#9BB53E", "#227949"]
        case .trueSpring:
            return ["#F3E5C8", "#FAD055", "#F6C345", "#ECA349", "#EA6759", "#DD3848", "#F97272", "#99B9DD", "#4F84C4", "#1E3F66", "#199B65", "#C9E37A"]
        case .lightSpring:
            return ["#F3E5C8", "#FAD055", "#ECA349", "#E9897E", "#F97272", "#DD3848", "#99B9DD", "#4F84C4", "#70C68E", "#3FAD67", "#B3CE50", "#55C6A9"]
        case .lightSummer:
            return ["#E7E5D9", "#F4B0BD", "#D994A7", "#02B694", "#38AECC", "#35619E", "#967C7F", "#FF8E94", "#8FA0B0", "#7B8AA4", "#B8D8C8", "#BBC5DC"]
        case .trueSummer:
            return ["#DAD9CB", "#D994A7", "#7F86BD", "#39A17E", "#625955", "#8FA0B0", "#7B8AA4", "#454348", "#A08D94", "#B7ADAD", "#C6C6C6", "#292F50"]
        case .softSummer:
            return ["#DED6C8", "#F3C6C3", "#5C9DA3", "#8BBF9A", "#34394D", "#9A908D", "#766762", "#AEB4B2", "#696F6D", "#827E80", "#ECA1A7", "#5B585B"]
        case .softAutumn:
            return ["#F0ECD7", "#E59B90", "#ACAD8A", "#507DA7", "#865E4D", "#C3BEAC", "#B9B69A", "#827D63", "#969777", "#9D736D", "#936152", "#55574A"]
        case .trueAutumn:
            return ["#E6DCC5", "#DF793D", "#9BA16A", "#087D87", "#49312D", "#F4E1AD", "#E1CA94", "#8F7D66", "#6B6151", "#E7AE91", "#D99A7D", "#414438"]
        case .darkAutumn:
            return ["#E4D8C7", "#AD8E50", "#C65D53", "#105448", "#5B5448", "#EBD3AD", "#F0D0AE", "#C6A585", "#918B85", "#AB9785", "#D7B066", "#514C50"]
        case .darkWinter:
            return ["#F2F5FC", "#D05776", "#007257", "#147BA4", "#29292B", "#F0E69C", "#EBCDD4", "#B7E4D6", "#B3DDE8", "#B8B5D0", "#F58DA1", "#6D696A"]
        case .trueWinter:
            return ["#EEF1FF", "#B72F75", "#009B8E", "#4B61A4", "#292F50", "#F2D5DF", "#F0E99A", "#B8D8C8", "#B1E4E9", "#BBC5DC", "#E9B9D9", "#EDA0CC"]
        case .brightWinter:
            return ["#F3F8FF", "#D74770", "#009697", "#38539D", "#2C3043", "#F2E7B0", "#F5D0D1", "#B8E2DC", "#F2D5E5", "#BFB3CA", "#EC898D", "#858180"]
        }
    }

    // MARK: - Foundation / Neutral Palette Swatches

    /// 5 foundation / neutral swatches used to ground the seasonal palette.
    public var neutralSwatches: [ColorSwatch] {
        switch self {
        case .brightSpring:
            return [
                ColorSwatch(name: "Snow White", pantoneCode: "11-0602 TCX", hex: "#F2F0EB"),
                ColorSwatch(name: "Vanilla Ice", pantoneCode: "11-0104 TCX", hex: "#F0EADA"),
                ColorSwatch(name: "Rutabaga", pantoneCode: "12-0806 TCX", hex: "#ECDDBE"),
                ColorSwatch(name: "Summer Sand", pantoneCode: "12-0908 TCX", hex: "#D6CBBA"),
                ColorSwatch(name: "Brindle", pantoneCode: "18-1110 TCX", hex: "#82776B")
            ]
        case .trueSpring:
            return [
                ColorSwatch(name: "Vanilla", pantoneCode: "12-0712 TCX", hex: "#F3E5C8"),
                ColorSwatch(name: "Sun Kiss", pantoneCode: "12-0807 TCX", hex: "#EBDBC3"),
                ColorSwatch(name: "Desert Mist", pantoneCode: "14-1127 TCX", hex: "#E0B589"),
                ColorSwatch(name: "Pale Gold", pantoneCode: "15-0927 TCX", hex: "#BD9865"),
                ColorSwatch(name: "Dachshund", pantoneCode: "18-1033 TCX", hex: "#704F3B")
            ]
        case .lightSpring:
            return [
                ColorSwatch(name: "Vanilla", pantoneCode: "12-0712 TCX", hex: "#F3E5C8"),
                ColorSwatch(name: "Golden Fleece", pantoneCode: "12-0822 TCX", hex: "#F2D1A0"),
                ColorSwatch(name: "Desert Mist", pantoneCode: "14-1127 TCX", hex: "#E0B589"),
                ColorSwatch(name: "Moonstone", pantoneCode: "14-1026 TCX", hex: "#BEA987"),
                ColorSwatch(name: "Dachshund", pantoneCode: "18-1033 TCX", hex: "#704F3B")
            ]
        case .lightSummer:
            return [
                ColorSwatch(name: "Tofu", pantoneCode: "11-4801 TCX", hex: "#E7E5D9"),
                ColorSwatch(name: "Bone White", pantoneCode: "12-0105 TCX", hex: "#D7D1C1"),
                ColorSwatch(name: "Pelican", pantoneCode: "14-6305 TCX", hex: "#C2BCAC"),
                ColorSwatch(name: "Atmosphere", pantoneCode: "16-1406 TCX", hex: "#A99C94"),
                ColorSwatch(name: "Silent Storm", pantoneCode: "17-1508 TCX", hex: "#827D77")
            ]
        case .trueSummer:
            return [
                ColorSwatch(name: "Light Gray", pantoneCode: "12-0404 TCX", hex: "#DAD9CB"),
                ColorSwatch(name: "Pale Mist", pantoneCode: "12-0906 TCX", hex: "#D2C9C0"),
                ColorSwatch(name: "Silver Cloud", pantoneCode: "15-4502 TCX", hex: "#BDB7B2"),
                ColorSwatch(name: "Castor Gray", pantoneCode: "18-5203 TCX", hex: "#96918C"),
                ColorSwatch(name: "Major Brown", pantoneCode: "19-0810 TCX", hex: "#625955")
            ]
        case .softSummer:
            return [
                ColorSwatch(name: "Birch", pantoneCode: "13-0905 TCX", hex: "#DED6C8"),
                ColorSwatch(name: "Fog", pantoneCode: "13-0401 TCX", hex: "#BDB3AB"),
                ColorSwatch(name: "Pavement", pantoneCode: "16-1407 TCX", hex: "#9A908D"),
                ColorSwatch(name: "French Roast", pantoneCode: "19-1012 TCX", hex: "#766762"),
                ColorSwatch(name: "Lead Gray", pantoneCode: "19-4015 TCX", hex: "#5B585B")
            ]
        case .softAutumn:
            return [
                ColorSwatch(name: "Sweet Corn", pantoneCode: "11-0106 TCX", hex: "#F0ECD7"),
                ColorSwatch(name: "Alabaster", pantoneCode: "12-0907 TCX", hex: "#E1DCCB"),
                ColorSwatch(name: "Doeskin", pantoneCode: "14-1110 TCX", hex: "#DCD6C7"),
                ColorSwatch(name: "Chinchilla", pantoneCode: "16-1108 TCX", hex: "#C3BEAC"),
                ColorSwatch(name: "Carob Brown", pantoneCode: "18-1229 TCX", hex: "#865E4D")
            ]
        case .trueAutumn:
            return [
                ColorSwatch(name: "Seedpearl", pantoneCode: "12-0703 TCX", hex: "#E6DCC5"),
                ColorSwatch(name: "Rugby Tan", pantoneCode: "13-1013 TCX", hex: "#DFD0BB"),
                ColorSwatch(name: "Nougat", pantoneCode: "14-1014 TCX", hex: "#CEC5B2"),
                ColorSwatch(name: "Apple Cinnamon", pantoneCode: "17-1028 TCX", hex: "#8F7D66"),
                ColorSwatch(name: "Chicory Coffee", pantoneCode: "19-1419 TCX", hex: "#49312D")
            ]
        case .darkAutumn:
            return [
                ColorSwatch(name: "White Swan", pantoneCode: "12-0000 TCX", hex: "#E4D8C7"),
                ColorSwatch(name: "Cornsilk", pantoneCode: "13-0917 TCX", hex: "#CDBBAA"),
                ColorSwatch(name: "Toasted Almond", pantoneCode: "14-1213 TCX", hex: "#C6A585"),
                ColorSwatch(name: "Bitter Chocolate", pantoneCode: "19-1317 TCX", hex: "#5B5448"),
                ColorSwatch(name: "Tarmac", pantoneCode: "19-0822 TCX", hex: "#5B5448")
            ]
        case .darkWinter:
            return [
                ColorSwatch(name: "Lucent White", pantoneCode: "11-0700 TCX", hex: "#F2F5FC"),
                ColorSwatch(name: "Vapor Blue", pantoneCode: "12-4306 TCX", hex: "#DEDDD7"),
                ColorSwatch(name: "Silver Birch", pantoneCode: "13-4403 TCX", hex: "#C9C3BA"),
                ColorSwatch(name: "Steel Gray", pantoneCode: "18-4005 TCX", hex: "#9D9D9B"),
                ColorSwatch(name: "Tap Shoe", pantoneCode: "19-4004 TCX", hex: "#29292B")
            ]
        case .trueWinter:
            return [
                ColorSwatch(name: "Brilliant White", pantoneCode: "11-4001 TCX", hex: "#EEF1FF"),
                ColorSwatch(name: "Bright White", pantoneCode: "11-0601 TCX", hex: "#E3E3DB"),
                ColorSwatch(name: "Glacier", pantoneCode: "14-4107 TCX", hex: "#D1D0C5"),
                ColorSwatch(name: "Castlerock", pantoneCode: "18-0201 TCX", hex: "#706E6D"),
                ColorSwatch(name: "Medieval Blue", pantoneCode: "19-3933 TCX", hex: "#292F50")
            ]
        case .brightWinter:
            return [
                ColorSwatch(name: "Bright White", pantoneCode: "11-0601 TCX", hex: "#F3F8FF"),
                ColorSwatch(name: "Star White", pantoneCode: "11-4202 TCX", hex: "#E6DFCE"),
                ColorSwatch(name: "Vapor", pantoneCode: "12-4304 TCX", hex: "#ADA99B"),
                ColorSwatch(name: "Steel", pantoneCode: "18-4006 TCX", hex: "#858180"),
                ColorSwatch(name: "Black Iris", pantoneCode: "19-3921 TCX", hex: "#2C3043")
            ]
        }
    }
}
