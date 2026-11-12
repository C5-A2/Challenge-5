//
//  OutfitGenerationPipeline.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation
import SwiftData
import UIKit

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

    /// Generates a single new tailored outfit look for an occasion, appending all previous looks and using higher temperature for diversity.
    func generateSingleLook(
        for occasion: OccasionItem,
        profile: UserProfile,
        lookIndex: Int,
        existingLooks: [OutfitLook],
        temperature: Float
    ) async throws -> OutfitLook

    /// Generates a single additional outfit look, taking into account all previously generated looks
    /// so the new look remains distinct and tailored.
    func generateSingleLook(
        for occasion: OccasionItem,
        profile: UserProfile,
        existingLooks: [OutfitLook]
    ) async throws -> OutfitLook
}

// MARK: - Default Outfit Generation Pipeline

/// Orchestrates the 5-look outfit recommendation pipeline.
///
/// **Strategy:** one LLM call per look. Each look has its own creative direction
/// (`OutfitArchetype`: reference match, personality, body shape, surprise me, look more),
/// its own pieces (`OutfitStructure`: separates or a dress, with an outer layer only when the model decides it fits),
/// and its own sampling temperature. Earlier looks are passed to the next prompt so the
/// looks differ in style and pieces, not only in color.
///
/// Reference photos are first described one by one by the on-device vision-language model
/// (Qwen 2.5 VL, `ReferenceImageStyleAnalyzer`), because the text model can't see images.
/// The descriptions are recapped into one paragraph and passed to every look's prompt.
@MainActor
final class OutfitGenerationPipeline: OutfitGenerationPipelineProtocol {

    static let shared = OutfitGenerationPipeline()

    /// Injected LLM output JSON string for testing prompts.
    /// When set, the generation pipeline directly decodes this JSON, ensuring the LLM completely decides
    /// every garment's color, hex code, material, name, and rationale.
    public static var injectedLLMResponseJSON: String? = nil

    private let promptBuilder: OutfitPromptBuilder

    /// Number of looks in one generation.
    private static let lookCount = 5
    /// One look is generated at most this many times when it repeats an earlier look or can't be parsed.
    private static let maximumAttemptsPerLook = 3
    /// Each new attempt gets this much more temperature, so it moves away from the repeated look.
    private static let retryTemperatureStep: Float = 0.15
    private static let maximumRetryTemperature: Float = 1.1
    /// Token limit for one look's JSON. One look is a few hundred tokens; the limit leaves room
    /// for the prompt inside the 4,096-token context.
    private static let maximumTokensPerLook = 1536

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
        try await generateLooks(for: occasion, profile: profile, onStageChange: nil)
    }

    /// - Parameter onStageChange: Loading overlay updates `(title, subtitle, VLM descriptions so far)`.
    func generateLooks(
        for occasion: OccasionItem,
        profile: UserProfile,
        onStageChange: (@MainActor @Sendable (_ title: String, _ subtitle: String, _ vlmDescriptions: [String]) -> Void)?
    ) async throws -> [OutfitLook] {
        // Validate the GGUF model file is present before attempting inference.
        try LLMResource.validateModelAvailability()

        // 1. Injected JSON short-circuit (prompt testing / UI previews).
        if let injectedJSON = OutfitGenerationPipeline.injectedLLMResponseJSON, !injectedJSON.isEmpty {
            if let looks = try? parseLooks(from: injectedJSON, colorSeason: profile.colorSeason), !looks.isEmpty {
                print("✅ [OutfitGenerationPipeline] Using \(looks.count) injected looks.")
                return looks
            }
        }

        // 2. Stage 1: describe the reference photos with the VLM (1 by 1, then the VLM is unloaded).
        let referenceDescriptions = await scanReferencePhotos(of: occasion, onStageChange: onStageChange)
        let referenceAnalysis = ReferenceStyleAnalysis(
            descriptions: referenceDescriptions,
            recap: await recapReferenceStyle(referenceDescriptions, occasionID: occasion.id)
        )

        // 3. Stage 2: one LLM call per look. Each look has its own direction, pieces and temperature,
        //    and gets the earlier looks so it doesn't repeat them.
        var generatedLooks: [OutfitLook] = []
        var previousSummaries: [GeneratedLookSummary] = []

        for lookIndex in 0..<Self.lookCount {
            let refStatusSuffix = referenceDescriptions.isEmpty
                ? ""
                : " (using Ref 1\(referenceDescriptions.count > 1 ? "–\(referenceDescriptions.count)" : ""))"
            onStageChange?(
                "Curating Your Looks",
                "Generating Look \(lookIndex + 1) of \(Self.lookCount)\(refStatusSuffix) tailored to \(occasion.title)...",
                referenceDescriptions
            )

            let parsedLook = try await generateLook(
                for: occasion,
                profile: profile,
                lookIndex: lookIndex,
                previousLooks: previousSummaries,
                referenceAnalysis: referenceAnalysis,
                minimumTemperature: nil
            )
            generatedLooks.append(parsedLook)
            previousSummaries.append(GeneratedLookSummary(from: parsedLook))
            print("✅ [OutfitGenerationPipeline] Look \(lookIndex) accepted. \(generatedLooks.count)/\(Self.lookCount) complete.")
        }

        return generatedLooks
    }

    /// Generates a single new tailored outfit look for an occasion, appending all previous looks and using high temperature (0.75) for diversity.
    func generateSingleLook(
        for occasion: OccasionItem,
        profile: UserProfile,
        lookIndex: Int,
        existingLooks: [OutfitLook],
        temperature: Float = 0.75
    ) async throws -> OutfitLook {
        // Validate the GGUF model file is present before attempting inference.
        try LLMResource.validateModelAvailability()

        // 1. Injected JSON short-circuit (prompt testing / UI previews).
        if let injectedJSON = OutfitGenerationPipeline.injectedLLMResponseJSON, !injectedJSON.isEmpty {
            if let looks = try? parseLooks(from: injectedJSON, colorSeason: profile.colorSeason), let first = looks.first {
                first.lookIndex = lookIndex
                return first
            }
        }

        // 2. Reuse the VLM descriptions saved for this occasion; scan again only when the photos changed.
        let allImageData = referenceImagesData(of: occasion)
        let persistedDescriptions = ReferenceImageStyleAnalyzer.shared.savedDescriptions(forOccasionID: occasion.id)
        let referenceDescriptions: [String]
        if !allImageData.isEmpty && persistedDescriptions.count == allImageData.count {
            referenceDescriptions = persistedDescriptions
        } else {
            referenceDescriptions = await ReferenceImageStyleAnalyzer.shared.analyzeIndividualImages(for: allImageData)
            if !referenceDescriptions.isEmpty {
                ReferenceImageStyleAnalyzer.shared.saveDescriptions(referenceDescriptions, forOccasionID: occasion.id)
            }
        }
        let referenceAnalysis = ReferenceStyleAnalysis(
            descriptions: referenceDescriptions,
            recap: await recapReferenceStyle(referenceDescriptions, occasionID: occasion.id)
        )
        let previousSummaries = existingLooks.map { GeneratedLookSummary(from: $0) }

        print("🔧 [OutfitGenerationPipeline] Generating extra look \(lookIndex) (previous looks appended: \(previousSummaries.count), refs: \(referenceDescriptions.count))…")

        // 3. Extra looks cycle through the 5 directions, at least as creative as `temperature`.
        return try await generateLook(
            for: occasion,
            profile: profile,
            lookIndex: lookIndex,
            previousLooks: previousSummaries,
            referenceAnalysis: referenceAnalysis,
            minimumTemperature: temperature
        )
    }

    /// Generates a single additional outfit look, taking into account all previously generated looks
    /// so the new look remains distinct and tailored.
    func generateSingleLook(
        for occasion: OccasionItem,
        profile: UserProfile,
        existingLooks: [OutfitLook]
    ) async throws -> OutfitLook {
        try await generateSingleLook(
            for: occasion,
            profile: profile,
            lookIndex: existingLooks.count,
            existingLooks: existingLooks,
            temperature: 0.75
        )
    }

    // MARK: - One Look

    /// Builds the prompt for one look (direction from its index), runs the model and parses the result.
    ///
    /// A look that repeats an earlier one (`repeatedLookIndex(of:in:)`) or can't be parsed is generated
    /// again at a higher temperature, up to `maximumAttemptsPerLook` times. After the last attempt a
    /// repeated look is kept (better than no look), but a parse failure is thrown.
    private func generateLook(
        for occasion: OccasionItem,
        profile: UserProfile,
        lookIndex: Int,
        previousLooks: [GeneratedLookSummary],
        referenceAnalysis: ReferenceStyleAnalysis?,
        minimumTemperature: Float?
    ) async throws -> OutfitLook {
        let archetype = OutfitArchetype(lookIndex: lookIndex)
        let structure = archetype.structure(
            referenceStructure: referenceAnalysis?.suggestedStructure,
            dresscodeStructure: OutfitStructure(dresscode: occasion.dresscode)
        )
        let baseTemperature = max(archetype.temperature, minimumTemperature ?? 0)

        // Colors: the dresscode's colors are enforced on every garment; otherwise the reference look
        // keeps the reference colors and the surprise look may add one accent outside her palette.
        let dresscodeColors = DresscodeColorRule.forOccasion(title: occasion.title, dresscode: occasion.dresscode, note: occasion.customNote, palette: profile.colorSeason?.outfitSwatches ?? [])
        let keepsReferenceColors = archetype == .referenceMatch && referenceAnalysis != nil
        let dresscodeRequirements = DresscodeRequirements(dresscode: occasion.dresscode)
        let excludedHexes = DresscodeColorRule.excludedHexes(dresscode: occasion.dresscode, palette: profile.colorSeason?.outfitSwatches ?? [])
        let allowsOffPalette = dresscodeColors == nil && keepsReferenceColors

        // Rejected repeats are added to the "previous looks" list, so the next attempt avoids them too.
        var avoidedLooks = previousLooks
        var lastRepeatedLook: OutfitLook?
        // Set when the prompt didn't fit the model's context: the next attempt uses the compact prompt.
        var forcesCompactPrompt = false

        for attempt in 0..<Self.maximumAttemptsPerLook {
            let temperature = min(baseTemperature + Float(attempt) * Self.retryTemperatureStep, Self.maximumRetryTemperature)
            let prompt = promptBuilder.buildFormattedPrompt(
                occasion: occasion,
                profile: profile,
                lookIndex: lookIndex,
                structure: structure,
                previousLooks: avoidedLooks,
                referenceAnalysis: referenceAnalysis,
                forcesCompact: forcesCompactPrompt
            )
            print("🔧 [OutfitGenerationPipeline] Look \(lookIndex) \(archetype) / \(structure.rawValue) (temp \(temperature), attempt \(attempt + 1)/\(Self.maximumAttemptsPerLook)). Prompt \(prompt.count) chars. Running \(LLMResource.activeModelFilename)…")

            let parsedLook: OutfitLook
            do {
                let rawOutput = try await LLMEngine.shared.generate(
                    prompt: prompt,
                    maxTokens: Self.maximumTokensPerLook,
                    temperature: temperature,
                    topP: archetype.topP
                )
                print("✅ [OutfitGenerationPipeline] Look \(lookIndex) raw output (\(rawOutput.count) chars):\n\(rawOutput)")

                let parsedLooks = try parseLooks(
                    from: rawOutput.trimmingCharacters(in: .whitespacesAndNewlines),
                    colorSeason: profile.colorSeason,
                    structure: structure,
                    allowsOffPaletteAccent: allowsOffPalette,
                    requiredSwatches: dresscodeColors?.swatches,
                    excludedHexes: excludedHexes
                )
                guard let first = parsedLooks.first else {
                    throw LLMError.invalidOutput("LLM returned 0 looks for look index \(lookIndex).")
                }
                // A look whose garments were all dropped (unknown categories) would show placeholder cards.
                guard !first.garments.isEmpty else {
                    throw LLMError.invalidOutput("Look index \(lookIndex) has no usable garments.")
                }
                parsedLook = first
            } catch {
                print("⚠️ [OutfitGenerationPipeline] Look \(lookIndex) attempt \(attempt + 1) failed: \(error.localizedDescription)")
                if let engineError = error as? LLMEngineError, case .promptTooLong = engineError {
                    forcesCompactPrompt = true
                }
                if attempt == Self.maximumAttemptsPerLook - 1 {
                    if let lastRepeatedLook { return lastRepeatedLook }
                    throw error
                }
                continue
            }
            // Enforce the intended index regardless of what the model output.
            parsedLook.lookIndex = lookIndex

            // The pieces must match the structure: a dress when the dresscode or reference asks for one,
            // separates otherwise. The parser keeps whatever came back when nothing matches, so check here.
            let pieceCategories = Set(parsedLook.garments.map(\.category))
            if !structure.categories.allSatisfy(pieceCategories.contains) {
                print("⚠️ [OutfitGenerationPipeline] Look \(lookIndex) has \(pieceCategories.map(\.rawValue).sorted()) instead of \(structure.categories.map(\.rawValue)). Generating it again.")
                if lastRepeatedLook == nil { lastRepeatedLook = parsedLook }
                continue
            }

            // A textile, fabric or pattern the dresscode requires ("batik") must appear in the look.
            if let missing = dresscodeRequirements.requiredTermGroups.first(where: { group in
                !parsedLook.garments.contains { garment in
                    let text = "\(garment.name) \(garment.material) \(garment.playgroundPrompt ?? "")".lowercased()
                    return group.contains { text.contains($0) }
                }
            }) {
                print("⚠️ [OutfitGenerationPipeline] Look \(lookIndex) misses the dresscode's \(missing.first ?? ""). Generating it again.")
                if lastRepeatedLook == nil { lastRepeatedLook = parsedLook }
                continue
            }

            // Without dresscode colors, a look mixing several bright colors is generated again (kept only as a last resort).
            if dresscodeColors == nil, !keepsReferenceColors, Self.isTooColorful(parsedLook) {
                print("⚠️ [OutfitGenerationPipeline] Look \(lookIndex) mixes several bright colors. Generating it again.")
                if lastRepeatedLook == nil { lastRepeatedLook = parsedLook }
                continue
            }

            guard let repeatedIndex = Self.repeatedLookIndex(of: parsedLook, in: avoidedLooks, comparesColors: dresscodeColors == nil) else {
                return parsedLook
            }
            print("⚠️ [OutfitGenerationPipeline] Look \(lookIndex) repeats look \(repeatedIndex + 1). Generating it again.")
            lastRepeatedLook = parsedLook
            avoidedLooks.append(GeneratedLookSummary(from: parsedLook))
        }

        // Every attempt repeated an earlier look: keep the last one rather than failing the whole set.
        guard let lastRepeatedLook else {
            throw LLMError.invalidOutput("Could not generate look index \(lookIndex).")
        }
        return lastRepeatedLook
    }

    // MARK: - Color Check

    /// A color at least this saturated and this bright counts as a "color", not a neutral.
    private static let colorfulMinimumSaturation = 0.35
    private static let colorfulMinimumBrightness = 0.35
    /// Hues within this many degrees count as one color (shades of the same color).
    private static let sameColorHueRange = 30.0

    /// Whether the look uses more than one non-neutral color, for example red with green and yellow.
    private static func isTooColorful(_ look: OutfitLook) -> Bool {
        let hues: [Double] = look.garments.compactMap { garment in
            let clean = garment.hexColor.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
            guard clean.count == 6, let value = UInt32(clean, radix: 16) else { return nil }
            let r = Double((value >> 16) & 0xFF) / 255, g = Double((value >> 8) & 0xFF) / 255, b = Double(value & 0xFF) / 255
            let maximum = max(r, g, b), delta = maximum - min(r, g, b)
            guard maximum >= colorfulMinimumBrightness, delta / maximum >= colorfulMinimumSaturation else { return nil }
            var hue: Double
            if maximum == r { hue = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
            else if maximum == g { hue = 60 * ((b - r) / delta + 2) }
            else { hue = 60 * ((r - g) / delta + 4) }
            return hue < 0 ? hue + 360 : hue
        }
        guard let first = hues.first else { return false }
        return hues.contains { hue in
            let difference = abs(hue - first)
            return min(difference, 360 - difference) > sameColorHueRange
        }
    }

    // MARK: - Repeat Check

    /// The index of the earlier look that `look` repeats, or `nil` when it's new.
    ///
    /// A look repeats an earlier one when a garment has the same category and name as one there,
    /// or when every garment matches one there in category and color (the same outfit, renamed).
    /// With dresscode colors every look shares the same few colors, so only names are compared (`comparesColors: false`).
    private static func repeatedLookIndex(of look: OutfitLook, in previousLooks: [GeneratedLookSummary], comparesColors: Bool = true) -> Int? {
        let garments = look.garments.map {
            (category: $0.category.rawValue, name: normalizedGarmentText($0.name), color: normalizedGarmentText($0.colorName))
        }
        guard !garments.isEmpty else { return nil }

        for previous in previousLooks {
            let previousGarments = previous.garments.map {
                (category: $0.category, name: normalizedGarmentText($0.name), color: normalizedGarmentText($0.colorName))
            }
            let repeatsGarment = garments.contains { garment in
                previousGarments.contains { $0.category == garment.category && $0.name == garment.name }
            }
            let repeatsOutfit = comparesColors && garments.count == previousGarments.count && garments.allSatisfy { garment in
                previousGarments.contains { $0.category == garment.category && $0.color == garment.color }
            }
            if repeatsGarment || repeatsOutfit {
                return previous.lookIndex
            }
        }
        return nil
    }

    /// Lowercased words only, so "High-Waisted Trousers" and "high waisted trousers" compare equal.
    private static func normalizedGarmentText(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Reference Photos (VLM)

    private func referenceImagesData(of occasion: OccasionItem) -> [Data] {
        occasion.referenceImagesData.isEmpty
            ? (occasion.referenceImageData.map { [$0] } ?? [])
            : occasion.referenceImagesData
    }

    /// Describes each reference photo with the on-device VLM and saves the descriptions for the occasion
    /// (shown in the Output's VLM debug). Reports progress through `onStageChange`.
    private func scanReferencePhotos(
        of occasion: OccasionItem,
        onStageChange: (@MainActor @Sendable (_ title: String, _ subtitle: String, _ vlmDescriptions: [String]) -> Void)?
    ) async -> [String] {
        let allImageData = referenceImagesData(of: occasion)
        guard !allImageData.isEmpty else {
            ReferenceImageStyleAnalyzer.shared.saveDescriptions([], forOccasionID: occasion.id)
            return []
        }

        let totalRefs = allImageData.count
        onStageChange?(
            "Analyzing References",
            "Scanning 1 of \(totalRefs) reference photo\(totalRefs == 1 ? "" : "s") with Qwen 2.5 VL...",
            []
        )
        let descriptions = await ReferenceImageStyleAnalyzer.shared.analyzeIndividualImages(
            for: allImageData
        ) { completed, total, descriptionsSoFar in
            if completed < total {
                onStageChange?(
                    "Analyzing References",
                    "Scanning \(completed + 1) of \(total) reference photos with Qwen 2.5 VL...",
                    descriptionsSoFar
                )
            } else {
                onStageChange?(
                    "Analyzing References",
                    "Scanned \(total) reference photo\(total == 1 ? "" : "s"). Preparing main LLM recommendation...",
                    descriptionsSoFar
                )
            }
        }
        ReferenceImageStyleAnalyzer.shared.saveDescriptions(descriptions, forOccasionID: occasion.id)

        print("\n====== [VLM DEBUG OUTPUT (\(occasion.title)) — ALL REFS → ALL LOOKS] ======")
        if descriptions.isEmpty {
            print("   (No VLM text descriptions returned)")
        } else {
            for (index, description) in descriptions.enumerated() {
                print("   Ref \(index + 1): \(description)")
            }
        }
        print("=========================================================================\n")
        return descriptions
    }

    /// Condenses all per-photo VLM descriptions (Ref 1–3) into ONE short paragraph so the per-look prompt stays small.
    /// A single description is used as-is. The recap is cached per occasion until descriptions change.
    private func recapReferenceStyle(_ descriptions: [String], occasionID: UUID) async -> String? {
        let cleaned = descriptions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return nil }
        if cleaned.count == 1 { return cleaned[0] }
        if let cached = ReferenceImageStyleAnalyzer.shared.savedRecap(forOccasionID: occasionID) { return cached }

        let numbered = cleaned.enumerated().map { "Photo \($0.offset + 1): \($0.element)" }.joined(separator: "\n")
        let system = """
        You condense outfit descriptions into one paragraph.
        Merge the photo descriptions below into ONE paragraph of 3 to 4 sentences.
        Keep every concrete garment name, cut, fabric, surface pattern and main color exactly as written. Only mention a pattern if a photo description states it. Do not invent anything. No lists, no JSON.
        """
        let prompt: String
        if LLMResource.isQwenActive {
            prompt = "<|im_start|>system\n\(system)<|im_end|>\n<|im_start|>user\n\(numbered)<|im_end|>\n<|im_start|>assistant\n"
        } else {
            prompt = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n\(system)<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n\(numbered)<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n"
        }

        do {
            let raw = try await LLMEngine.shared.generate(prompt: prompt, maxTokens: 220, temperature: 0.2)
            let recap = raw.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !recap.isEmpty {
                print("📝 [OutfitGenerationPipeline] Reference recap (\(cleaned.count) → 1 paragraph): \(recap)")
                ReferenceImageStyleAnalyzer.shared.saveRecap(recap, forOccasionID: occasionID)
                return recap
            }
        } catch {
            print("⚠️ [OutfitGenerationPipeline] Reference recap failed: \(error.localizedDescription). Using joined descriptions.")
        }
        return cleaned.joined(separator: " ")
    }

    /// Synchronous generation for seamless instant UI transitions upon form submit.
    ///
    /// > Note: Real LLM inference runs asynchronously via `generateLooks(for:profile:)` in `OccasionOutputViewModel`.
    /// > If no pre-injected test JSON is provided, this returns an empty array so the async task can run.
    func generateLooksSync(
        for occasion: OccasionItem,
        profile: UserProfile
    ) throws -> [OutfitLook] {
        // Validate that LLM can be used. Throws LLMError if model is missing or unreadable.
        try LLMResource.validateModelAvailability()

        // 1. If an injected LLM response JSON is available (prompt testing), decode directly:
        if let injectedJSON = OutfitGenerationPipeline.injectedLLMResponseJSON, !injectedJSON.isEmpty {
            if let looks = try? parseLooks(from: injectedJSON), !looks.isEmpty {
                print("✅ [OutfitGenerationPipeline] Using \(looks.count) looks with LLM-decided colors and garments.")
                return looks
            }
        }

        // Return empty so OccasionOutputViewModel asynchronously generates the looks on screen appear.
        return []
    }

    // MARK: - LLM Response JSON Parser

    /// Parses the raw JSON string generated by LLaMA or any LLM, allowing the LLM to completely
    /// decide garment names, materials, color names, and palette hex codes.
    ///
    /// Robust to mixed prose+JSON output or truncated tokens from on-device models:
    /// 1. Strips markdown fences.
    /// 2. Tries to decode the full string as JSON first (happy path).
    /// 3. Falls back to extracting the outermost `{ ... }` JSON blob from the raw text.
    /// 4. If the JSON is truncated (e.g. hit token limit on look 5), closes open brackets
    ///    so whatever looks were fully completed (e.g. 4 looks) parse cleanly without failing.
    ///
    /// - Parameters:
    ///   - structure: The pieces the look should have; garments outside it are dropped when possible.
    ///   - allowsOffPaletteAccent: The surprise look may keep one color outside the palette.
    func parseLooks(
        from jsonString: String,
        colorSeason: ColorSeason? = nil,
        structure: OutfitStructure? = nil,
        allowsOffPaletteAccent: Bool = false,
        requiredSwatches: [ColorSeason.ColorSwatch]? = nil,
        excludedHexes: Set<String> = []
    ) throws -> [OutfitLook] {
        let options = ParseOptions(
            colorSeason: colorSeason,
            structure: structure,
            allowsOffPaletteAccent: allowsOffPaletteAccent,
            requiredSwatches: requiredSwatches,
            excludedHexes: excludedHexes
        )
        var cleanJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip any <think>...</think> reasoning block (Qwen 3 / 3.5) and markdown code fences
        if let thinkRegex = try? NSRegularExpression(pattern: "<think>[\\s\\S]*?</think>", options: []) {
            let range = NSRange(cleanJSON.startIndex..<cleanJSON.endIndex, in: cleanJSON)
            cleanJSON = thinkRegex.stringByReplacingMatches(in: cleanJSON, options: [], range: range, withTemplate: "")
        }
        cleanJSON = cleanJSON
            .replacingOccurrences(of: "<think>", with: "")
            .replacingOccurrences(of: "</think>", with: "")
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Try to decode the cleaned string directly as-is (happy path)
        if let looks = try? decodeLooks(from: cleanJSON, options: options), !looks.isEmpty {
            return looks
        }

        // 2. Extract the first balanced { ... } block (cuts off trailing garbage like `}]` or extra tokens)
        if let balanced = extractFirstBalancedJSONObject(from: cleanJSON),
           let looks = try? decodeLooks(from: balanced, options: options), !looks.isEmpty {
            print("✅ [OutfitGenerationPipeline] Decoded look from balanced JSON block.")
            return looks
        }

        // 3. Extract the outermost { ... } blob from mixed prose+JSON output
        if let extracted = extractJSONObject(from: cleanJSON),
           let looks = try? decodeLooks(from: extracted, options: options), !looks.isEmpty {
            print("⚠️ [OutfitGenerationPipeline] Extracted JSON from mixed output.")
            return looks
        }

        // 4. Try wrapping with {"looks":[ ... ]} if it was an unnested look continuation
        if !cleanJSON.contains("\"looks\"") {
            let wrapped = "{\"looks\":[" + cleanJSON + "]}"
            if let looks = try? decodeLooks(from: wrapped, options: options), !looks.isEmpty {
                return looks
            }
            if let balancedWrapped = extractFirstBalancedJSONObject(from: wrapped),
               let looks = try? decodeLooks(from: balancedWrapped, options: options), !looks.isEmpty {
                return looks
            }
        }

        // 5. Auto-fix repeated `"garments": [` keys if present
        let sanitized = sanitizeMalformedLLMJSON(cleanJSON)
        if sanitized != cleanJSON {
            if let looks = try? decodeLooks(from: sanitized, options: options), !looks.isEmpty {
                return looks
            }
            if let balanced = extractFirstBalancedJSONObject(from: sanitized),
               let looks = try? decodeLooks(from: balanced, options: options), !looks.isEmpty {
                return looks
            }
        }

        // 6. JSON may be truncated (model hit maxTokens mid-generation). Try closing open
        //    brackets so the partial output becomes valid JSON with whatever looks were completed.
        let repaired = repairTruncatedJSON(sanitized)
        do {
            let looks = try decodeLooks(from: repaired, options: options)
            if !looks.isEmpty {
                print("⚠️ [OutfitGenerationPipeline] Decoded \(looks.count) looks from repaired truncated JSON.")
                return looks
            }
        } catch {
            print("⚠️ [OutfitGenerationPipeline] Repaired JSON decode failed: \(error.localizedDescription)")
        }

        // 7. Fallback: Parse individual garment objects directly if the wrapper was badly mangled
        if let fallbackLooks = extractLooksFromMalformedText(sanitized, options: options), !fallbackLooks.isEmpty {
            print("⚠️ [OutfitGenerationPipeline] Recovered \(fallbackLooks.count) looks using garment scanner fallback.")
            return fallbackLooks
        }

        // All strategies failed — throw with the raw output for debugging
        throw LLMError.invalidOutput("Could not parse JSON from LLM output (\(cleanJSON.count) chars):\n\(cleanJSON)")
    }

    /// How a parsed look is checked against the requested look.
    private struct ParseOptions {
        let colorSeason: ColorSeason?
        let structure: OutfitStructure?
        let allowsOffPaletteAccent: Bool
        /// Dresscode colors: when set, every garment color is snapped to one of these instead of the season palette.
        let requiredSwatches: [ColorSeason.ColorSwatch]?
        /// Palette colors the dresscode rules out ("no black").
        let excludedHexes: Set<String>

        /// The colors garments are matched to.
        var palette: [ColorSeason.ColorSwatch] {
            // Without dresscode colors, every color is snapped to her "suits you" colors and neutrals.
            (requiredSwatches ?? colorSeason?.outfitSwatches ?? []).filter { !excludedHexes.contains($0.hex.uppercased()) }
        }
    }

    // MARK: - LLM JSON Sanitization & Resilient Fallback

    /// Extracts the first balanced `{ ... }` JSON block from text, ignoring any trailing garbage (e.g. `}]` or extra tokens).
    private func extractFirstBalancedJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else { return nil }
        var depth = 0
        var inString = false
        var escaped = false
        var idx = start

        while idx < text.endIndex {
            let ch = text[idx]
            if escaped {
                escaped = false
            } else if ch == "\\" && inString {
                escaped = true
            } else if ch == "\"" {
                inString.toggle()
            } else if !inString {
                if ch == "{" {
                    depth += 1
                } else if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        return String(text[start...idx])
                    }
                }
            }
            idx = text.index(after: idx)
        }
        return nil
    }

    /// Fixes common small-LLM JSON malformations (e.g. repeated `"garments":[` keys per item).
    private func sanitizeMalformedLLMJSON(_ text: String) -> String {
        var result = text

        // Fix: `},\n "garments":[{"category"` -> `},\n {"category"`
        // or `}],\n "garments":[{"category"` -> `},\n {"category"`
        let pattern1 = #"(?:\}\s*\]|\})\s*,\s*\"garments\"\s*:\s*\[\s*\{"#
        if let regex = try? NSRegularExpression(pattern: pattern1, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "}, {")
        }

        // Fix a dropped key: `"colorName":"Sage","#9CAF88"` -> `"colorName":"Sage","hexColor":"#9CAF88"`
        let missingHexKeyPattern = ##"(\"colorName\"\s*:\s*\"[^\"]*\"\s*,\s*)(\"#[0-9A-Fa-f]{3,8}\")"##
        if let regex = try? NSRegularExpression(pattern: missingHexKeyPattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1\"hexColor\":$2")
        }

        return result
    }

    /// Scans text for individual `{ "category": ... }` garment JSON objects if outer wrapper is broken.
    private func extractLooksFromMalformedText(_ text: String, options: ParseOptions) -> [OutfitLook]? {
        // Find fitRationale if present
        let fitRationale: String
        let rationalePattern = #"\"fitRationale\"\s*:\s*\"([^\"]+)\""#
        if let regex = try? NSRegularExpression(pattern: rationalePattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)),
           let range = Range(match.range(at: 1), in: text) {
            fitRationale = String(text[range])
        } else {
            fitRationale = "Harmonious ensemble tailored to your silhouette and seasonal palette."
        }

        // Find all garment-like objects: { ... "category" ... }
        var garments: [GarmentItem] = []
        let palette = options.palette

        var depth = 0
        var objStart: String.Index? = nil
        var inString = false
        var escaped = false

        var idx = text.startIndex
        while idx < text.endIndex {
            let ch = text[idx]
            if escaped {
                escaped = false
            } else if ch == "\\" && inString {
                escaped = true
            } else if ch == "\"" {
                inString.toggle()
            } else if !inString {
                if ch == "{" {
                    if depth == 0 || (depth == 1 && objStart == nil) {
                        objStart = idx
                    }
                    depth += 1
                } else if ch == "}" {
                    depth = max(0, depth - 1)
                    if let start = objStart, text[start...idx].contains("\"category\"") {
                        let candidate = String(text[start...idx])
                        if let data = candidate.data(using: .utf8),
                           let dto = try? JSONDecoder().decode(LLMOutfitGenerationResponse.GarmentDTO.self, from: data) {
                            // Pieces outside Outer / Top / Bottom (shoes, accessories) are skipped.
                            if let cat = GarmentCategory(generatedLabel: dto.category)
                                ?? GarmentCategory(generatedLabel: dto.name) {
                                let color = resolveSeasonalColor(rawName: dto.colorName, rawHex: dto.hexColor, palette: palette,
                                                                 allowsOffPalette: options.allowsOffPaletteAccent)
                                let garment = GarmentItem(
                                    category: cat,
                                    name: dto.name,
                                    material: dto.material,
                                    colorName: color.name,
                                    hexColor: color.hex,
                                    rationale: dto.rationale,
                                    playgroundPrompt: normalizePlaygroundPrompt(
                                        dto.playgroundPrompt,
                                        rawColorName: dto.colorName,
                                        resolvedColorName: color.name
                                    )
                                )
                                garments.append(garment)
                            }
                        }
                        objStart = nil
                    } else if depth <= 1 {
                        objStart = nil
                    }
                }
            }
            idx = text.index(after: idx)
        }

        guard !garments.isEmpty else { return nil }

        let look = OutfitLook(
            lookIndex: 0,
            fitRationale: fitRationale,
            isBookmarked: false,
            lookImageData: nil
        )
        let trimmedGarments = makeOutfitGarments(from: garments, structure: options.structure)
        for g in trimmedGarments {
            g.outfitLook = look
        }
        look.garments = trimmedGarments
        return [look]
    }

    // MARK: - JSON Parsing Helpers

    /// Keeps one garment per category, ordered like the Output cards.
    /// - A dress replaces a separate top and bottom, so they are dropped when a dress is present.
    /// - With a requested `structure`, garments outside it are dropped, unless that would leave
    ///   nothing (the model's own valid outfit is kept instead of an empty look).
    private func makeOutfitGarments(from garments: [GarmentItem], structure: OutfitStructure?) -> [GarmentItem] {
        var seenCategories: Set<GarmentCategory> = []
        var outfit = garments.filter { seenCategories.insert($0.category).inserted }
        if seenCategories.contains(.dress) {
            outfit.removeAll { $0.category == .top || $0.category == .bottom }
        }
        if let structure {
            let requested = outfit.filter { structure.allowedCategories.contains($0.category) }
            if !requested.isEmpty {
                outfit = requested
            }
        }
        return outfit.sortedForOutfitDisplay()
    }

    /// Syncs `playgroundPrompt` with the resolved swatch name and ensures the word "color" follows
    /// the color name so Image Playground treats literal swatch names (e.g. "Sweet Corn") as colors.
    private func normalizePlaygroundPrompt(_ rawPrompt: String?, rawColorName: String, resolvedColorName: String) -> String? {
        guard var prompt = rawPrompt?.trimmingCharacters(in: .whitespacesAndNewlines), !prompt.isEmpty else {
            return nil
        }
        let cleanRaw = rawColorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanResolved = resolvedColorName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanRaw.isEmpty, !cleanResolved.isEmpty,
           cleanRaw.caseInsensitiveCompare(cleanResolved) != .orderedSame,
           let range = prompt.range(of: cleanRaw, options: .caseInsensitive) {
            prompt.replaceSubrange(range, with: cleanResolved.lowercased())
        }
        let lowerWords = prompt.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        if !lowerWords.contains("color") && !lowerWords.contains("colored") {
            if !cleanResolved.isEmpty, let range = prompt.range(of: cleanResolved, options: .caseInsensitive) {
                let matched = String(prompt[range])
                prompt.replaceSubrange(range, with: "\(matched) color")
            } else if !cleanRaw.isEmpty, let range = prompt.range(of: cleanRaw, options: .caseInsensitive) {
                let matched = String(prompt[range])
                prompt.replaceSubrange(range, with: "\(matched) color")
            } else if !cleanResolved.isEmpty {
                prompt = "\(cleanResolved.lowercased()) color \(prompt)"
            }
        }
        return prompt
    }

    private func decodeLooks(from jsonString: String, options: ParseOptions) throws -> [OutfitLook] {
        guard let data = jsonString.data(using: .utf8) else {
            throw LLMError.invalidOutput("Unable to convert JSON string to UTF-8 data")
        }
        
        // Flexible decoding: handle {"looks": [...]}, single look {...}, or array [...]
        let lookDTOs: [LLMOutfitGenerationResponse.LookDTO]
        if let decoded = try? JSONDecoder().decode(LLMOutfitGenerationResponse.self, from: data) {
            lookDTOs = decoded.looks
        } else if let singleLook = try? JSONDecoder().decode(LLMOutfitGenerationResponse.LookDTO.self, from: data) {
            lookDTOs = [singleLook]
        } else if let lookArray = try? JSONDecoder().decode([LLMOutfitGenerationResponse.LookDTO].self, from: data) {
            lookDTOs = lookArray
        } else {
            throw LLMError.invalidOutput("Unable to decode looks from JSON")
        }

        let palette = options.palette
        var looks: [OutfitLook] = []
        for lookDTO in lookDTOs {
            let look = OutfitLook(
                lookIndex: lookDTO.lookIndex,
                fitRationale: lookDTO.fitRationale,
                isBookmarked: false,
                lookImageData: nil
            )
            var garments: [GarmentItem] = []
            // Pieces outside Outer / Top / Bottom (shoes, accessories) are skipped instead of becoming a top.
            for gDTO in lookDTO.garments {
                guard let cat = GarmentCategory(generatedLabel: gDTO.category)
                        ?? GarmentCategory(generatedLabel: gDTO.name) else { continue }

                // Harmonize / snap color to the closest valid seasonal swatch if palette is available
                let resolvedColor = resolveSeasonalColor(
                    rawName: gDTO.colorName,
                    rawHex: gDTO.hexColor,
                    palette: palette,
                    allowsOffPalette: options.allowsOffPaletteAccent
                )

                let garment = GarmentItem(
                    category: cat,
                    name: gDTO.name,
                    material: gDTO.material,
                    colorName: resolvedColor.name,
                    hexColor: resolvedColor.hex,
                    rationale: gDTO.rationale,
                    playgroundPrompt: normalizePlaygroundPrompt(
                        gDTO.playgroundPrompt,
                        rawColorName: gDTO.colorName,
                        resolvedColorName: resolvedColor.name
                    )
                )
                garments.append(garment)
            }
            // At most one garment per category, ordered inner top, outer, bottom.
            let outfitGarments = makeOutfitGarments(from: garments, structure: options.structure)
            for garment in outfitGarments {
                garment.outfitLook = look
            }
            look.garments = outfitGarments
            looks.append(look)
        }
        return looks
    }

    /// Snaps the model's color to the seasonal palette.
    /// 1. Same hex as a swatch, 2. same or contained name, 3. with `allowsOffPalette` (surprise look)
    /// a valid hex is kept as it is, 4. otherwise the closest swatch by RGB distance, so the result
    /// is stable and close to what the model meant (the old `hashValue` pick changed on every launch).
    private func resolveSeasonalColor(
        rawName: String,
        rawHex: String,
        palette: [ColorSeason.ColorSwatch],
        allowsOffPalette: Bool = false
    ) -> (name: String, hex: String) {
        let cleanHex = rawHex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
        guard !palette.isEmpty else {
            return (rawName, "#\(cleanHex)")
        }

        if let match = palette.first(where: {
            $0.hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased() == cleanHex
        }) {
            return (match.name, match.hex)
        }

        let lowerName = rawName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !lowerName.isEmpty, let exactNameMatch = palette.first(where: { $0.name.lowercased() == lowerName }) {
            return (exactNameMatch.name, exactNameMatch.hex)
        }

        // The reference look keeps the reference color itself. Checked before the partial name match,
        // which would otherwise turn "white" into a palette swatch named "Whitecap Gray".
        if allowsOffPalette, rgbComponents(fromHex: cleanHex) != nil {
            return (rawName, "#\(cleanHex)")
        }

        let rawColor = rgbComponents(fromHex: cleanHex)
        if !lowerName.isEmpty {
            let partialMatches = palette.filter {
                let palName = $0.name.lowercased()
                return palName.contains(lowerName) || lowerName.contains(palName)
            }
            if let rawColor, let closestPartial = partialMatches.min(by: { first, second in
                colorDistance(rawColor, rgbComponents(fromHex: first.hex)) < colorDistance(rawColor, rgbComponents(fromHex: second.hex))
            }) {
                return (closestPartial.name, closestPartial.hex)
            } else if let firstPartial = partialMatches.first {
                return (firstPartial.name, firstPartial.hex)
            }
        }

        if allowsOffPalette, rawColor != nil {
            return (rawName, "#\(cleanHex)")
        }

        if let rawColor, let closest = palette.min(by: { first, second in
            colorDistance(rawColor, rgbComponents(fromHex: first.hex)) < colorDistance(rawColor, rgbComponents(fromHex: second.hex))
        }) {
            return (closest.name, closest.hex)
        }

        // No usable hex: a stable pick from the name (same name, same swatch on every launch).
        let stableIndex = rawName.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % palette.count }
        let fallback = palette[stableIndex]
        return (fallback.name, fallback.hex)
    }

    private func rgbComponents(fromHex hex: String) -> (red: Double, green: Double, blue: Double)? {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return (Double((value >> 16) & 0xFF), Double((value >> 8) & 0xFF), Double(value & 0xFF))
    }

    /// RGB distance; a swatch with an unreadable hex counts as infinitely far.
    private func colorDistance(_ color: (red: Double, green: Double, blue: Double),
                               _ other: (red: Double, green: Double, blue: Double)?) -> Double {
        guard let other else { return .infinity }
        let redDelta = color.red - other.red
        let greenDelta = color.green - other.green
        let blueDelta = color.blue - other.blue
        return (redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta).squareRoot()
    }

    /// Scans the string for the first `{` and the last `}` and returns the substring between them.
    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") ,
              start <= end else { return nil }
        return String(text[start...end])
    }

    /// Closes any unclosed `[` and `{` brackets so a truncated JSON becomes parseable.
    /// Strips the last incomplete look object before closing brackets.
    ///
    /// JSON structure: `{"looks":[{look0},{look1},…]}`
    /// When `{"looks":[` is present:
    /// - `{` opens `looks` root object -> depth 1
    /// - `[` opens `looks` array -> depth 2
    /// - `{` opens an outfit look object -> depth 3
    /// - `[` opens `garments` array -> depth 4
    /// - `{` opens each garment -> depth 5
    /// - `}` closes each garment -> depth 4
    /// - `]` closes `garments` array -> depth 3
    /// - `}` closes the outfit look object -> depth 2!
    /// Therefore, a complete look object finishes exactly when `}` brings depth from 3 to 2.
    private func repairTruncatedJSON(_ json: String) -> String {
        // Ensure the string has a proper {"looks":[ start
        var base = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.contains("\"looks\"") {
            if let extracted = extractJSONObject(from: base) {
                base = extracted
            }
        }
        if !base.hasPrefix("{\"looks\":[") {
            if let looksIndex = base.range(of: "{\"looks\":[")?.lowerBound {
                base = String(base[looksIndex...])
            } else {
                base = "{\"looks\":[" + base
            }
        }

        var stack: [Character] = []
        var inString = false
        var escaped = false
        var lastCompleteLookEnd: String.Index? = nil
        var depth = 0
        var idx = base.startIndex

        while idx < base.endIndex {
            let ch = base[idx]
            if escaped {
                escaped = false
            } else if ch == "\\" && inString {
                escaped = true
            } else if ch == "\"" {
                inString.toggle()
            } else if !inString {
                if ch == "{" {
                    stack.append("}")
                    depth += 1
                } else if ch == "[" {
                    stack.append("]")
                    depth += 1
                } else if ch == "}" || ch == "]" {
                    if let last = stack.last, last == ch {
                        stack.removeLast()
                    }
                    // When closing at depth 3, a complete look object finished
                    if ch == "}" && depth == 3 {
                        lastCompleteLookEnd = idx
                    }
                    depth = max(0, depth - 1)
                }
            }
            idx = base.index(after: idx)
        }

        // 1. If at least one complete look was finished, truncate cleanly after it:
        if let cutoff = lastCompleteLookEnd {
            let trimmed = String(base[base.startIndex...cutoff])
            return trimmed + "]}"
        }

        // 2. Otherwise, repair the in-flight look by closing unclosed strings & brackets:
        var repaired = base
        if inString {
            repaired.append("\"")
        }
        // Remove any dangling trailing comma before closing brackets
        var trimmedRepaired = repaired.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmedRepaired.hasSuffix(",") {
            trimmedRepaired.removeLast()
            trimmedRepaired = trimmedRepaired.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Append all remaining closing brackets
        for closeChar in stack.reversed() {
            trimmedRepaired.append(closeChar)
        }
        return trimmedRepaired
    }
}

// MARK: - LLM Response Decodable DTOs

public struct LLMOutfitGenerationResponse: Codable, Sendable {
    public struct LookDTO: Codable, Sendable {
        public let lookIndex: Int
        public let fitRationale: String
        public let garments: [GarmentDTO]

        enum CodingKeys: String, CodingKey {
            case lookIndex
            case fitRationale
            case rationale
            case description
            case garments
            case items
            case outfit
        }

        public init(lookIndex: Int, fitRationale: String, garments: [GarmentDTO]) {
            self.lookIndex = lookIndex
            self.fitRationale = fitRationale
            self.garments = garments
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Flexible lookIndex: accepts Int, String ("0"), or defaults to 0
            if let intVal = try? container.decode(Int.self, forKey: .lookIndex) {
                self.lookIndex = intVal
            } else if let strVal = try? container.decode(String.self, forKey: .lookIndex), let parsed = Int(strVal) {
                self.lookIndex = parsed
            } else {
                self.lookIndex = 0
            }

            // Flexible fitRationale: tries fitRationale, then rationale, description, or default
            if let r = try? container.decode(String.self, forKey: .fitRationale) {
                self.fitRationale = r
            } else if let r = try? container.decode(String.self, forKey: .rationale) {
                self.fitRationale = r
            } else if let r = try? container.decode(String.self, forKey: .description) {
                self.fitRationale = r
            } else {
                self.fitRationale = "Harmonious ensemble tailored to your silhouette and seasonal palette."
            }

            // Flexible garments array: tries garments, items, outfit, or defaults to empty
            if let g = try? container.decode([GarmentDTO].self, forKey: .garments) {
                self.garments = g
            } else if let g = try? container.decode([GarmentDTO].self, forKey: .items) {
                self.garments = g
            } else if let g = try? container.decode([GarmentDTO].self, forKey: .outfit) {
                self.garments = g
            } else {
                self.garments = []
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(lookIndex, forKey: .lookIndex)
            try container.encode(fitRationale, forKey: .fitRationale)
            try container.encode(garments, forKey: .garments)
        }
    }

    public struct GarmentDTO: Codable, Sendable {
        public let category: String
        public let name: String
        public let material: String
        public let colorName: String
        public let hexColor: String
        public let rationale: String
        public let playgroundPrompt: String?

        enum CodingKeys: String, CodingKey {
            case category, type, garmentType
            case name, itemName, garment
            case material, fabric
            case colorName, color, color_name
            case hexColor, hex, hex_color
            case rationale, bodyFitRationale, fitRationale, reason
            case playgroundPrompt, visualPrompt, visual_prompt, playground_prompt
        }

        public init(
            category: String,
            name: String,
            material: String,
            colorName: String,
            hexColor: String,
            rationale: String,
            playgroundPrompt: String? = nil
        ) {
            self.category = category
            self.name = name
            self.material = material
            self.colorName = colorName
            self.hexColor = hexColor
            self.rationale = rationale
            self.playgroundPrompt = playgroundPrompt
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // category
            if let c = try? container.decode(String.self, forKey: .category) {
                self.category = c
            } else if let c = try? container.decode(String.self, forKey: .type) {
                self.category = c
            } else if let c = try? container.decode(String.self, forKey: .garmentType) {
                self.category = c
            } else {
                self.category = "Top"
            }

            // name
            if let n = try? container.decode(String.self, forKey: .name) {
                self.name = n
            } else if let n = try? container.decode(String.self, forKey: .itemName) {
                self.name = n
            } else if let n = try? container.decode(String.self, forKey: .garment) {
                self.name = n
            } else {
                self.name = "Classic Piece"
            }

            // material
            if let m = try? container.decode(String.self, forKey: .material) {
                self.material = m
            } else if let m = try? container.decode(String.self, forKey: .fabric) {
                self.material = m
            } else {
                self.material = "Tailored Blend"
            }

            // colorName
            if let cn = try? container.decode(String.self, forKey: .colorName) {
                self.colorName = cn
            } else if let cn = try? container.decode(String.self, forKey: .color) {
                self.colorName = cn
            } else if let cn = try? container.decode(String.self, forKey: .color_name) {
                self.colorName = cn
            } else {
                self.colorName = "Neutral"
            }

            // hexColor
            if let h = try? container.decode(String.self, forKey: .hexColor) {
                self.hexColor = h
            } else if let h = try? container.decode(String.self, forKey: .hex) {
                self.hexColor = h
            } else if let h = try? container.decode(String.self, forKey: .hex_color) {
                self.hexColor = h
            } else {
                self.hexColor = "#1A1A1A"
            }

            // rationale
            if let r = try? container.decode(String.self, forKey: .rationale) {
                self.rationale = r
            } else if let r = try? container.decode(String.self, forKey: .bodyFitRationale) {
                self.rationale = r
            } else if let r = try? container.decode(String.self, forKey: .fitRationale) {
                self.rationale = r
            } else if let r = try? container.decode(String.self, forKey: .reason) {
                self.rationale = r
            } else {
                self.rationale = "Flattering cut tailored to your natural body line."
            }

            // playgroundPrompt (optional AI-provided visual prompt)
            self.playgroundPrompt = (try? container.decode(String.self, forKey: .playgroundPrompt))
                ?? (try? container.decode(String.self, forKey: .visualPrompt))
                ?? (try? container.decode(String.self, forKey: .visual_prompt))
                ?? (try? container.decode(String.self, forKey: .playground_prompt))
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(category, forKey: .category)
            try container.encode(name, forKey: .name)
            try container.encode(material, forKey: .material)
            try container.encode(colorName, forKey: .colorName)
            try container.encode(hexColor, forKey: .hexColor)
            try container.encode(rationale, forKey: .rationale)
            try container.encodeIfPresent(playgroundPrompt, forKey: .playgroundPrompt)
        }
    }

    public let looks: [LookDTO]

    public init(looks: [LookDTO]) {
        self.looks = looks
    }
}
