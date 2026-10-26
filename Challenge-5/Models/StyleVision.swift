//
//  StyleVision.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 24/10/26.
//

import Foundation

/// Represents the user's desired emotional impression, mood, and visual presence for an occasion.
///
/// Each vision defines color palettes, pattern details, materials & silhouettes, and recommended outfit items
/// used by the AI recommendation engine and UI styling.
public enum StyleVision: String, Codable, CaseIterable, Identifiable, Sendable {
    case approachable = "Approachable"
    case calm = "Calm"
    case competent = "Competent"
    case confident = "Confident"
    case creative = "Creative"
    case elegant = "Elegant"
    case energetic = "Energetic"
    case happy = "Happy"
    case mysterious = "Mysterious"
    case playful = "Playful"
    case powerful = "Powerful"
    case romantic = "Romantic"

    public var id: String { rawValue }

    // MARK: - Vision Details Model

    public struct VisionDetails: Sendable, Hashable {
        /// The formal dual/single adjective title (e.g. "Happy / Joyful", "Confident").
        public let adjective: String
        
        /// What the user aims to project with their look.
        public let visionDescription: String
        
        /// Recommended colors.
        public let colors: String
        
        /// Recommended patterns and styling details.
        public let patternsAndDetails: String
        
        /// Recommended materials, fabrics, and silhouette guidelines.
        public let materialsAndSilhouettes: String
        
        /// Specific clothing and accessory item recommendations.
        public let recommendedOutfitItems: String

        public init(
            adjective: String,
            visionDescription: String,
            colors: String,
            patternsAndDetails: String,
            materialsAndSilhouettes: String,
            recommendedOutfitItems: String
        ) {
            self.adjective = adjective
            self.visionDescription = visionDescription
            self.colors = colors
            self.patternsAndDetails = patternsAndDetails
            self.materialsAndSilhouettes = materialsAndSilhouettes
            self.recommendedOutfitItems = recommendedOutfitItems
        }
    }

    // MARK: - Properties

    /// Full metadata bundle for the vision.
    public var details: VisionDetails {
        switch self {
        case .approachable:
            return VisionDetails(
                adjective: "Approachable / Friendly",
                visionDescription: "Aims to look welcoming, accessible, warm, and easy to interact with.",
                colors: "Beige, cream, light blue, peach, soft warm tones.",
                patternsAndDetails: "Simple patterns, fine stripes, semi-formal details.",
                materialsAndSilhouettes: "Cotton, lightweight knits; relaxed or semi-structured silhouettes.",
                recommendedOutfitItems: "Simple blouse, cardigan, polo shirt, straight-leg jeans, chinos, clean loafers or sneakers."
            )

        case .calm:
            return VisionDetails(
                adjective: "Calm / Peaceful",
                visionDescription: "Aims to appear serene, peaceful, grounded, and understated.",
                colors: "Blue, green, white, soft tones.",
                patternsAndDetails: "Solid colors, micro-patterns, simple designs.",
                materialsAndSilhouettes: "Linen, soft cotton, knitwear; relaxed and clean silhouettes.",
                recommendedOutfitItems: "Light blue shirt, white blouse, straight-cut trousers, soft cardigan, simple flats or loafers."
            )

        case .competent:
            return VisionDetails(
                adjective: "Competent / Professional",
                visionDescription: "Aims to appear capable, trustworthy, work-ready, and professional.",
                colors: "Navy, charcoal, white, beige.",
                patternsAndDetails: "Solid colors, pinstripes, minimal patterns.",
                materialsAndSilhouettes: "Suiting fabrics, cotton, wool blends; neat and structured.",
                recommendedOutfitItems: "Blazer, button-up shirt, tailored trousers, formal skirt, loafers, structured work bag."
            )

        case .confident:
            return VisionDetails(
                adjective: "Confident",
                visionDescription: "Aims to look self-assured, poised, composed, and decisive.",
                colors: "Red, navy, black, contrasting colors.",
                patternsAndDetails: "Minimal or sharp patterns; controlled details.",
                materialsAndSilhouettes: "Tailoring, structured silhouettes, well-fitted cuts.",
                recommendedOutfitItems: "Blazer, structured shirt, tailored trousers, jumpsuit, structured shoes, structured bag."
            )

        case .creative:
            return VisionDetails(
                adjective: "Creative / Artistic",
                visionDescription: "Aims to appear imaginative, expressive, inventive, with distinct personal character.",
                colors: "Unconventional color combinations, purple, high-contrast tones.",
                patternsAndDetails: "Abstract, geometric, artistic motifs, layered textures.",
                materialsAndSilhouettes: "Mixed fabrics; asymmetrical, oversized, or experimental cuts.",
                recommendedOutfitItems: "Statement blouse, printed trousers, unique outerwear, asymmetrical skirt, statement shoes, artistic accessories."
            )

        case .elegant:
            return VisionDetails(
                adjective: "Elegant / Refined",
                visionDescription: "Aims to appear graceful, sophisticated, polished, and composed.",
                colors: "Black, ivory, navy, champagne, jewel tones.",
                patternsAndDetails: "Solid colors, delicate motifs, minimal details.",
                materialsAndSilhouettes: "Satin, crepe, drapey fabrics; clean and proportional cuts.",
                recommendedOutfitItems: "Midi dress, understated blouse, tailored trousers, pointed-toe shoes, clutch, minimalist jewelry."
            )

        case .energetic:
            return VisionDetails(
                adjective: "Energetic / Dynamic",
                visionDescription: "Aims to appear active, enthusiastic, mobile, and high-energy.",
                colors: "Orange, red, yellow, high-contrast pairings.",
                patternsAndDetails: "Stripes, color-blocking, dynamic graphics.",
                materialsAndSilhouettes: "Jersey, cotton, stretch fabrics; sporty or structured-casual cuts.",
                recommendedOutfitItems: "Track jacket, polo shirt, joggers, tapered pants, sneakers, utilitarian bag."
            )

        case .happy:
            return VisionDetails(
                adjective: "Happy / Joyful",
                visionDescription: "Aims to appear cheerful, optimistic, delightful, and radiate positive energy.",
                colors: "Yellow, orange, coral, pink, bright colors.",
                patternsAndDetails: "Cheerful florals, playful patterns, color-blocking.",
                materialsAndSilhouettes: "Cotton, lightweight linen; relaxed or flared silhouettes.",
                recommendedOutfitItems: "Yellow blouse, bright shirt, white trousers, A-line skirt, sneakers or flats in contrasting colors."
            )

        case .mysterious:
            return VisionDetails(
                adjective: "Mysterious / Dramatic",
                visionDescription: "Aims to look enigmatic, intense, dramatic, and project a commanding visual presence.",
                colors: "Black, deep purple, burgundy, midnight navy.",
                patternsAndDetails: "High contrast, prominent textures, dramatic accents.",
                materialsAndSilhouettes: "Velvet, satin, textured fabrics; sharp or dramatically flowing silhouettes.",
                recommendedOutfitItems: "Black blouse, dark tailored trousers, dramatic dress, boots, structured bag, metallic accessories."
            )

        case .playful:
            return VisionDetails(
                adjective: "Playful / Fun",
                visionDescription: "Aims to appear expressive, spontaneous, entertaining, and lighthearted.",
                colors: "Orange, yellow, pink, contrasting color combinations.",
                patternsAndDetails: "Polka dots, graphic prints, geometric motifs, color-blocking.",
                materialsAndSilhouettes: "Cotton, denim, knitwear; casual silhouettes with engaging details.",
                recommendedOutfitItems: "Graphic tee, colorful blouse, patterned skirt, jeans, sneakers, contrast-colored bag."
            )

        case .powerful:
            return VisionDetails(
                adjective: "Powerful / Authoritative",
                visionDescription: "Aims to project decisiveness, authority, influence, and leadership presence.",
                colors: "Navy, black, burgundy, red accents.",
                patternsAndDetails: "Solid colors, sharp lines, minimal details.",
                materialsAndSilhouettes: "Structured tailoring, defined shoulders, clean silhouettes.",
                recommendedOutfitItems: "Sharp blazer, monochrome suit, tailored trousers, collared shirt, formal shoes, structured bag."
            )

        case .romantic:
            return VisionDetails(
                adjective: "Romantic / Gentle",
                visionDescription: "Aims to appear delicate, sweet, emotionally warm, or romantic.",
                colors: "Pink, rose, cream, lavender, pastels.",
                patternsAndDetails: "Florals, lace, ditsy prints, soft decorative details.",
                materialsAndSilhouettes: "Chiffon, lace, lightweight satin; draped fabrics and A-line silhouettes.",
                recommendedOutfitItems: "Soft blouse, wrap dress, midi skirt, cardigan, ballet flats, compact handbag."
            )
        }
    }

    // MARK: - Direct Convenience Accessors

    /// The dual or single vision adjective title (e.g. "Happy / Joyful").
    public var adjective: String {
        details.adjective
    }

    /// User-facing display title for UI representation.
    public var displayName: String {
        details.adjective
    }

    /// Short title corresponding to the rawValue (e.g. "Happy").
    public var shortTitle: String {
        rawValue
    }

    /// What the user wants their look to represent.
    public var visionDescription: String {
        details.visionDescription
    }

    /// Recommended colors string.
    public var colors: String {
        details.colors
    }

    /// Recommended patterns and styling details string.
    public var patternsAndDetails: String {
        details.patternsAndDetails
    }

    /// Recommended materials and silhouettes string.
    public var materialsAndSilhouettes: String {
        details.materialsAndSilhouettes
    }

    /// Recommended garments and outfit items string.
    public var recommendedOutfitItems: String {
        details.recommendedOutfitItems
    }

    // MARK: - Initializer & Lookup Helpers

    /// Flexible lookup initializer that matches either the short rawValue ("Happy"),
    /// the full adjective ("Happy / Joyful"), or case-insensitive variants.
    public init?(flexibleName: String) {
        let cleaned = flexibleName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let match = StyleVision.allCases.first(where: {
            $0.rawValue.lowercased() == cleaned ||
            $0.adjective.lowercased() == cleaned ||
            $0.adjective.lowercased().components(separatedBy: " / ").contains(cleaned)
        }) {
            self = match
        } else {
            return nil
        }
    }

    /// Generates structured prompt context for LLM recommendation prompts.
    public var llmPromptContext: String {
        """
        Vision: \(adjective)
        Description: \(visionDescription)
        Colors: \(colors)
        Patterns & Details: \(patternsAndDetails)
        Materials & Silhouettes: \(materialsAndSilhouettes)
        Recommended Outfit Items: \(recommendedOutfitItems)
        """
    }
}
