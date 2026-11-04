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
}

// MARK: - Default Outfit Generation Pipeline

/// Orchestrates the 5-look outfit recommendation pipeline.
///
/// **Strategy:** one LLM call per look. Each look has its own creative direction
/// (`OutfitArchetype`: reference match, personality, body shape, surprise me, look more),
/// its own pieces (`OutfitStructure`: outer + top + bottom, top + bottom, dress, dress + outer),
/// and its own sampling temperature. Earlier looks are passed to the next prompt so the
/// looks differ in style and pieces, not only in color.
///
/// Reference photos are read on device (`ReferenceImageStyleAnalyzer`) and described in text,
/// because the language model can't see images.
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
        // Validate the GGUF model file is present before attempting inference.
        try LLMResource.validateModelAvailability()

        // 1. Injected JSON short-circuit (prompt testing / UI previews).
        if let injectedJSON = OutfitGenerationPipeline.injectedLLMResponseJSON, !injectedJSON.isEmpty {
            if let looks = try? parseLooks(from: injectedJSON, colorSeason: profile.colorSeason), !looks.isEmpty {
                print("✅ [OutfitGenerationPipeline] Using \(looks.count) injected looks.")
                return looks
            }
        }

        // 2. Read the reference photos on device (pieces, layering, colors mapped to the palette).
        let referenceAnalysis = await analyzeReferencePhotos(of: occasion, profile: profile)

        // 3. One LLM call per look. Each look has its own direction, pieces and temperature,
        //    and gets the earlier looks so it doesn't repeat them.
        var generatedLooks: [OutfitLook] = []
        var previousSummaries: [GeneratedLookSummary] = []

        for lookIndex in 0..<Self.lookCount {
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

        // 2. Read the reference photos and summarize every look generated so far.
        let referenceAnalysis = await analyzeReferencePhotos(of: occasion, profile: profile)
        let previousSummaries = existingLooks.map { GeneratedLookSummary(from: $0) }

        print("🔧 [OutfitGenerationPipeline] Generating extra look \(lookIndex) (previous looks appended: \(previousSummaries.count))…")

        // 3. Extra looks cycle through the 5 directions, at least as creative as `temperature`.
        //    The look image is left empty: the Output fills a placeholder until image generation exists.
        let parsedLook = try await generateLook(
            for: occasion,
            profile: profile,
            lookIndex: lookIndex,
            previousLooks: previousSummaries,
            referenceAnalysis: referenceAnalysis,
            minimumTemperature: temperature
        )
        return parsedLook
    }

    // MARK: - One Look

    /// Builds the prompt for one look (direction from its index), runs the model and parses the result.
    private func generateLook(
        for occasion: OccasionItem,
        profile: UserProfile,
        lookIndex: Int,
        previousLooks: [GeneratedLookSummary],
        referenceAnalysis: ReferenceStyleAnalysis?,
        minimumTemperature: Float?
    ) async throws -> OutfitLook {
        let archetype = OutfitArchetype(lookIndex: lookIndex)
        let structure = archetype.structure(referenceStructure: referenceAnalysis?.suggestedStructure)
        let temperature = max(archetype.temperature, minimumTemperature ?? 0)

        let prompt = promptBuilder.buildFormattedPrompt(
            occasion: occasion,
            profile: profile,
            lookIndex: lookIndex,
            structure: structure,
            previousLooks: previousLooks,
            referenceAnalysis: referenceAnalysis
        )
        print("🔧 [OutfitGenerationPipeline] Look \(lookIndex) \(archetype) / \(structure.rawValue) (temp \(temperature)). Prompt \(prompt.count) chars. Running \(LLMResource.activeModelFilename)…")

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
            allowsOffPaletteAccent: archetype.allowsOffPaletteAccent
        )
        guard let parsedLook = parsedLooks.first else {
            throw LLMError.invalidOutput("LLM returned 0 looks for look index \(lookIndex).")
        }
        // Enforce the intended index regardless of what the model output.
        parsedLook.lookIndex = lookIndex
        return parsedLook
    }

    /// Reads the occasion's reference photos, `nil` when there are none or nothing could be read.
    private func analyzeReferencePhotos(of occasion: OccasionItem, profile: UserProfile) async -> ReferenceStyleAnalysis? {
        let imagesData = occasion.referenceImagesData.isEmpty
            ? (occasion.referenceImageData.map { [$0] } ?? [])
            : occasion.referenceImagesData
        guard !imagesData.isEmpty else { return nil }
        let analysis = await ReferenceImageStyleAnalyzer.shared.analyzeOutfits(
            from: imagesData,
            palette: profile.colorSeason?.palette ?? []
        )
        if let analysis {
            print("👁️ [OutfitGenerationPipeline] Reference photos (\(analysis.suggestedStructure?.rawValue ?? "unknown structure")):\n\(analysis.promptDescription)")
        }
        return analysis
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
        allowsOffPaletteAccent: Bool = false
    ) throws -> [OutfitLook] {
        let options = ParseOptions(colorSeason: colorSeason, structure: structure, allowsOffPaletteAccent: allowsOffPaletteAccent)
        var cleanJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip markdown code fences the model may have wrapped the JSON in
        cleanJSON = cleanJSON
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
        let repaired = repairTruncatedJSON(cleanJSON)
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
        if let fallbackLooks = extractLooksFromMalformedText(cleanJSON, options: options), !fallbackLooks.isEmpty {
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
        let palette = options.colorSeason?.palette ?? []

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
                                    rationale: dto.rationale
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
            let requested = outfit.filter { structure.categories.contains($0.category) }
            if !requested.isEmpty {
                outfit = requested
            }
        }
        return outfit.sortedForOutfitDisplay()
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

        let palette = options.colorSeason?.palette ?? []
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
                    rationale: gDTO.rationale
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
        if !lowerName.isEmpty, let match = palette.first(where: {
            let palName = $0.name.lowercased()
            return palName == lowerName || palName.contains(lowerName) || lowerName.contains(palName)
        }) {
            return (match.name, match.hex)
        }

        let rawColor = rgbComponents(fromHex: cleanHex)
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

        enum CodingKeys: String, CodingKey {
            case category, type, garmentType
            case name, itemName, garment
            case material, fabric
            case colorName, color, color_name
            case hexColor, hex, hex_color
            case rationale, bodyFitRationale, fitRationale, reason
        }

        public init(category: String, name: String, material: String, colorName: String, hexColor: String, rationale: String) {
            self.category = category
            self.name = name
            self.material = material
            self.colorName = colorName
            self.hexColor = hexColor
            self.rationale = rationale
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
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(category, forKey: .category)
            try container.encode(name, forKey: .name)
            try container.encode(material, forKey: .material)
            try container.encode(colorName, forKey: .colorName)
            try container.encode(hexColor, forKey: .hexColor)
            try container.encode(rationale, forKey: .rationale)
        }
    }

    public let looks: [LookDTO]

    public init(looks: [LookDTO]) {
        self.looks = looks
    }
}
