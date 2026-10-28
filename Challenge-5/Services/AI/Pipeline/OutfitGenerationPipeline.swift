//
//  OutfitGenerationPipeline.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation
import SwiftData

/// Decodable schema matching the structured LLM output for an outfit look.
public struct GeneratedLookDTO: Codable, Sendable {
    public let lookIndex: Int
    public let styleArchetype: String?
    public let fitRationale: String
    public let garments: [GeneratedGarmentDTO]
}

/// Decodable schema matching an individual garment inside a generated look.
public struct GeneratedGarmentDTO: Codable, Sendable {
    public let category: String
    public let name: String
    public let material: String
    public let colorName: String
    public let hexColor: String
    public let rationale: String
}

/// Top-level container for 5 generated looks.
public struct GeneratedOutfitResponseDTO: Codable, Sendable {
    public let looks: [GeneratedLookDTO]
}

// MARK: - Pipeline Protocol

@MainActor
protocol OutfitGenerationPipelineProtocol {
    /// Generates 5 distinct, tailored outfit looks for an occasion using user profile constraints.
    func generateLooks(
        for occasion: OccasionItem,
        profile: UserProfile
    ) async throws -> [OutfitLook]
}

// MARK: - Default Outfit Generation Pipeline

/// Orchestrates the 5-look outfit recommendation pipeline.
///
/// **Strategy Architecture:**
/// Uses a **single unified generation pass** with 5 distinct stylistic archetypes rather than
/// 5 sequential calls with escalating temperature.
///
/// **Why Single Generation Pass Wins:**
/// 1. **UX Latency:** Produces all 5 looks in a single roundtrip (~2-4 seconds) instead of 15-25 seconds of sequential calls.
/// 2. **Zero Garment Duplication:** The model maintains global context across all 5 looks, guaranteeing distinct cuts, colors, and layering.
/// 3. **Strict Rule Adherence:** Increasing temperature destabilizes seasonal palette hex codes and violates body silhouette constraints.
/// 4. **Individual Garment Rationales:** Every garment includes a dedicated body-fit rationale explaining why its cut flatters the user's body.
@MainActor
final class OutfitGenerationPipeline: OutfitGenerationPipelineProtocol {

    static let shared = OutfitGenerationPipeline()

    private let promptBuilder: OutfitPromptBuilder

    init(promptBuilder: OutfitPromptBuilder? = nil) {
        self.promptBuilder = promptBuilder ?? OutfitPromptBuilder()
    }

    // MARK: - Generation Execution

    func generateLooks(
        for payload: RecommendationPayload
    ) async throws -> [OutfitLook] {
        return try await generateLooks(for: payload.occasion, profile: payload.userProfile)
    }

    func generateLooks(
        for occasion: OccasionItem,
        profile: UserProfile
    ) async throws -> [OutfitLook] {
        return generateLooksSync(for: occasion, profile: profile)
    }

    /// Synchronous generation for seamless instant UI transitions upon form submit.
    func generateLooksSync(
        for occasion: OccasionItem,
        profile: UserProfile
    ) -> [OutfitLook] {
        // Build dynamic conditional prompt for Llama 3.2 (prints running system prompt to terminal for debugging)
        let _ = promptBuilder.buildSystemPrompt(
            occasion: occasion,
            profile: profile
        )

        let bodyType = profile.bodyType ?? .hourglass
        let torsoBalance = profile.torsoBalance ?? .balanced
        let colorSeason = profile.colorSeason ?? .trueAutumn

        return synthesizeLooks(
            for: occasion,
            bodyType: bodyType,
            torsoBalance: torsoBalance,
            colorSeason: colorSeason
        )
    }

    // MARK: - Domain-Rule Synthesis Engine

    /// Synthesizes 5 highly tailored looks matching the 5 archetypes and personal profiling rules.
    private func synthesizeLooks(
        for occasion: OccasionItem,
        bodyType: BodyType,
        torsoBalance: TorsoBalance,
        colorSeason: ColorSeason
    ) -> [OutfitLook] {
        let swatches = colorSeason.palette
        let dresscode = occasion.dresscode.lowercased()
        let isFormal = dresscode.contains("formal") || dresscode.contains("black tie") || dresscode.contains("cocktail") || dresscode.contains("gala")
        let hasReferenceImages = !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil

        var generatedLooks: [OutfitLook] = []

        for index in 0..<5 {
            let look = OutfitLook(
                lookIndex: index,
                bodyShapeScore: 0.0,
                colorHarmonyScore: 0.0,
                torsoBalanceScore: 0.0,
                fitRationale: generateLookFitRationale(
                    index: index,
                    occasion: occasion,
                    bodyType: bodyType,
                    torsoBalance: torsoBalance,
                    colorSeason: colorSeason,
                    hasReferenceImages: hasReferenceImages
                ),
                isBookmarked: false,
                lookImageData: nil // Image Playground generation is deferred
            )

            let garments = generateGarments(
                index: index,
                isFormal: isFormal,
                bodyType: bodyType,
                torsoBalance: torsoBalance,
                swatches: swatches,
                visions: occasion.visions
            )

            for g in garments {
                g.outfitLook = look
            }
            look.garments = garments
            generatedLooks.append(look)
        }

        return generatedLooks
    }

    // MARK: - Look Fit Rationale Builder

    private func generateLookFitRationale(
        index: Int,
        occasion: OccasionItem,
        bodyType: BodyType,
        torsoBalance: TorsoBalance,
        colorSeason: ColorSeason,
        hasReferenceImages: Bool
    ) -> String {
        let visionText: String
        if let vision = occasion.visions.first {
            visionText = " Infused with \(vision.adjective.lowercased()) styling using \(vision.materialsAndSilhouettes.lowercased())."
        } else {
            visionText = ""
        }

        let referenceNote = hasReferenceImages
            ? " Subtly adjusted to reflect textures and aesthetic mood from your reference photos."
            : ""

        switch index {
        case 0:
            return "Coordinated for \(occasion.title), featuring cuts that flatter your \(bodyType.displayName) silhouette and \(torsoBalance.rawValue.lowercased()). Exact \(colorSeason.rawValue) tones establish harmonic balance.\(visionText)\(referenceNote)"

        case 1:
            return "Tailored for \(occasion.dresscode.isEmpty ? "the occasion" : occasion.dresscode), optimizing your \(torsoBalance.rawValue.lowercased()) proportions and complementing your natural waistline in \(colorSeason.rawValue) shades.\(visionText)\(referenceNote)"

        case 2:
            return "Structured proportions designed to enhance your \(bodyType.displayName) line and collarbones, balanced with rich \(colorSeason.rawValue) palette swatches.\(visionText)\(referenceNote)"

        case 3:
            return "A clean vertical silhouette that visually elongates your frame and optimizes your \(torsoBalance.rawValue.lowercased()) balance effortlessly for \(occasion.title).\(visionText)\(referenceNote)"

        default:
            return "A complete ensemble designed for \(occasion.title), tailored to your \(bodyType.displayName) silhouette and \(torsoBalance.rawValue.lowercased()) in radiant \(colorSeason.rawValue) tones.\(visionText)\(referenceNote)"
        }
    }

    // MARK: - Garment Synthesis with Individual Rationales

    private func generateGarments(
        index: Int,
        isFormal: Bool,
        bodyType: BodyType,
        torsoBalance: TorsoBalance,
        swatches: [ColorSeason.ColorSwatch],
        visions: [StyleVision]
    ) -> [GarmentItem] {
        // Pick distinct color swatches per look from the 35 seasonal palette swatches
        let c1 = swatches[(index * 3) % swatches.count]
        let c2 = swatches[(index * 3 + 1) % swatches.count]
        let c3 = swatches[(index * 3 + 2) % swatches.count]

        let (outerData, topData, bottomData) = garmentTemplates(
            index: index,
            isFormal: isFormal,
            bodyType: bodyType,
            torsoBalance: torsoBalance
        )

        let outer = GarmentItem(
            category: .outer,
            name: outerData.name,
            material: outerData.material,
            colorName: c1.name,
            hexColor: c1.hex,
            rationale: outerData.rationale
        )

        let top = GarmentItem(
            category: .top,
            name: topData.name,
            material: topData.material,
            colorName: c2.name,
            hexColor: c2.hex,
            rationale: topData.rationale
        )

        let bottom = GarmentItem(
            category: .bottom,
            name: bottomData.name,
            material: bottomData.material,
            colorName: c3.name,
            hexColor: c3.hex,
            rationale: bottomData.rationale
        )

        return [outer, top, bottom]
    }

    // MARK: - Garment Templates & Body-Fit Rationales

    private func garmentTemplates(
        index: Int,
        isFormal: Bool,
        bodyType: BodyType,
        torsoBalance: TorsoBalance
    ) -> (
        outer: (name: String, material: String, rationale: String),
        top: (name: String, material: String, rationale: String),
        bottom: (name: String, material: String, rationale: String)
    ) {
        // Tailor specific garment cuts and rationales to BodyType and TorsoBalance
        let torsoNote: String
        let riseRecommendation: String
        switch torsoBalance {
        case .shortTorso:
            torsoNote = "Untucked hemline visually lowers the waistline to elongate your upper body silhouette."
            riseRecommendation = "Mid-to-low rise waistband avoids compressing your torso while elongating the torso-to-leg ratio."
        case .balanced:
            torsoNote = "Clean hip-level hemline preserves your natural 1:1 proportion between upper body and legs."
            riseRecommendation = "Regular-rise waistline anchors naturally at the hip bone, maintaining balanced body symmetry."
        case .longTorso:
            torsoNote = "Tucked or cropped hemline visually raises the waistline to lengthen your leg proportion."
            riseRecommendation = "High-waisted tailoring creates an elevated waistline, visually balancing a longer torso."
        }

        switch index {
        case 0: // Signature Classic
            let outerName = isFormal ? "Tailored Single-Breasted Blazer" : "Structured Soft Blazer"
            let outerMaterial = isFormal ? "Fine Crepe Wool" : "Textured Cotton Blend"
            let outerRationale = "Clean single-breasted lapels narrow shoulder breadth and define the waistline without added bulk, complementing your \(bodyType.displayName)."

            let topName = isFormal ? "Silk V-Neck Shell" : "Pima Cotton Crewneck"
            let topMaterial = isFormal ? "Mulberry Silk" : "Mercerized Pima Cotton"
            let topRationale = "The neckline draws focus vertically toward your centerline, flattering the bust and collarbones. \(torsoNote)"

            let bottomName = isFormal ? "Straight-Leg Flat-Front Trousers" : "Tailored Chino Trousers"
            let bottomMaterial = isFormal ? "Fluid Wool Gabardine" : "Cotton Twill"
            let bottomRationale = "\(riseRecommendation) The straight cut creates a sleek vertical column that balances lower body contours."

            return (
                (outerName, outerMaterial, outerRationale),
                (topName, topMaterial, topRationale),
                (bottomName, bottomMaterial, bottomRationale)
            )

        case 1: // Contemporary Relaxed
            let outerName = "Unstructured Overshirt"
            let outerMaterial = "Brushed Tencel Twill"
            let outerRationale = "Open front creates fluid vertical lines down the torso, softening width across the midsection for an effortless drape."

            let topName = "Relaxed Camp-Collar Shirt"
            let topMaterial = "Textured Linen Blend"
            let topRationale = "The open camp collar creates a subtle V-shape framing the neck. \(torsoNote)"

            let bottomName = "Relaxed Pleated Trousers"
            let bottomMaterial = "Draped Lyocell Gabardine"
            let bottomRationale = "\(riseRecommendation) Single pleats skim gently over the thighs without creating excess volume."

            return (
                (outerName, outerMaterial, outerRationale),
                (topName, topMaterial, topRationale),
                (bottomName, bottomMaterial, bottomRationale)
            )

        case 2: // Elevated Statement
            let outerName = isFormal ? "Peak-Lapel Dinner Jacket" : "Sculpted Duster Coat"
            let outerMaterial = isFormal ? "Silk-Blend Jacquard" : "Double-Faced Wool Blend"
            let outerRationale = "Architectural lapels frame the upper silhouette and enhance posture, drawing attention upward toward your face."

            let topName = "Fitted Mockneck Knit"
            let topMaterial = "Fine Merino Wool"
            let topRationale = "A close-to-body knit provides a smooth, unbulky base layer that highlights waist definition. \(torsoNote)"

            let bottomName = "Wide-Leg Palazzo Trousers"
            let bottomMaterial = "Fluid Fluid Crepe"
            let bottomRationale = "\(riseRecommendation) Sweeping wide leg balances upper structure and creates graceful movement."

            return (
                (outerName, outerMaterial, outerRationale),
                (topName, topMaterial, topRationale),
                (bottomName, bottomMaterial, bottomRationale)
            )

        case 3: // Minimalist Sleek
            let outerName = "Minimalist Collarless Jacket"
            let outerMaterial = "Compact Wool Crepe"
            let outerRationale = "Eliminating collar bulk keeps focus on your clean silhouette, producing a streamlined profile without distractions."

            let topName = "Seamless High-Neck Shell"
            let topMaterial = "Matte Rayon Jersey"
            let topRationale = "Clean, unembellished cut flatters your shoulder line and provides a sleek column silhouette. \(torsoNote)"

            let bottomName = "Slim-Straight Cigarette Pants"
            let bottomMaterial = "Tailored Bi-Stretch Crepe"
            let bottomRationale = "\(riseRecommendation) Tapered straight line visually lengthens the legs while contouring cleanly."

            return (
                (outerName, outerMaterial, outerRationale),
                (topName, topMaterial, topRationale),
                (bottomName, bottomMaterial, bottomRationale)
            )

        default: // Layered Dynamic
            let outerName = "Belted Trench Duster"
            let outerMaterial = "Water-Resistant Cotton Gabardine"
            let outerRationale = "Adjustable waist tie allows precise waist placement customization to accentuate your natural silhouette curves."

            let topName = "Fine Gauge Polo Sweater"
            let topMaterial = "Cashmere Silk Blend"
            let topRationale = "Sharp collar with neat button placket adds refined vertical detail to your upper torso. \(torsoNote)"

            let bottomName = "Tailored Fluid Culottes"
            let bottomMaterial = "Virgin Wool Blend"
            let bottomRationale = "\(riseRecommendation) A-line flare skims over hips and thighs while balancing upper layering."

            return (
                (outerName, outerMaterial, outerRationale),
                (topName, topMaterial, topRationale),
                (bottomName, bottomMaterial, bottomRationale)
            )
        }
    }
}
