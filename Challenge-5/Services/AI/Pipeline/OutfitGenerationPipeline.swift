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

    /// Injected LLM output JSON string for testing prompts.
    /// When set, the generation pipeline directly decodes this JSON, ensuring the LLM completely decides
    /// every garment's color, hex code, material, name, and rationale.
    public static var injectedLLMResponseJSON: String? = nil

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
        // Validate the GGUF model file is present before attempting inference.
        try LLaMAResource.validateModelAvailability()

        // 1. Injected JSON short-circuit (prompt testing / UI previews).
        if let injectedJSON = OutfitGenerationPipeline.injectedLLMResponseJSON, !injectedJSON.isEmpty {
            if let looks = try? parseLooks(from: injectedJSON, colorSeason: profile.colorSeason), !looks.isEmpty {
                print("✅ [OutfitGenerationPipeline] Using \(looks.count) injected looks.")
                return looks
            }
        }

        // 2. Sequential generation: one LLM call = one look.
        //    After each look is parsed, its garment summary is appended to the next call's
        //    system prompt so the model aims for variety across looks.
        let totalLooks = 5

        // Escalating temperature per look: Look 0 is grounded/safe; each subsequent look gets
        // progressively more creative, ensuring the 5 looks feel meaningfully distinct.
        let temperatures: [Float] = [0.30, 0.45, 0.55, 0.65, 0.72]

        var generatedLooks: [OutfitLook] = []
        var previousSummaries: [GeneratedLookSummary] = []

        for lookIndex in 0..<totalLooks {
            let temperature = temperatures[lookIndex]
            print("🔧 [OutfitGenerationPipeline] Building prompt for look \(lookIndex)/\(totalLooks - 1) (temp: \(temperature))…")

            // Build a single-look prompt, injecting summaries of all previously generated looks.
            let prompt = promptBuilder.buildLlamaFormattedPrompt(
                occasion: occasion,
                profile: profile,
                lookIndex: lookIndex,
                previousLooks: previousSummaries
            )
            print("🔧 [OutfitGenerationPipeline] Look \(lookIndex) prompt built (\(prompt.count) chars). Running LLaMA…")

            // One LLM call — generates exactly one look's JSON.
            // maxTokens = 4096: the model tends to be verbose (~2100 tokens observed for one look),
            // so 4096 gives a safe ceiling with no truncation risk.
            // The model stops naturally at its EOG token well before this limit.
            let rawOutput = try await LLaMAEngine.shared.generate(
                prompt: prompt,
                maxTokens: 4096,
                temperature: temperature
            )

            print("✅ [OutfitGenerationPipeline] Look \(lookIndex) raw output (\(rawOutput.count) chars):\n\(rawOutput)")

            // Parse the single look and fix its index to match the intended lookIndex.
            let rawClean = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            let parsedLooks = try parseLooks(from: rawClean, colorSeason: profile.colorSeason)
            guard let parsedLook = parsedLooks.first else {
                throw LLaMAError.invalidOutput("LLaMA returned 0 looks for look index \(lookIndex).")
            }

            // Enforce the correct lookIndex regardless of what the model output.
            parsedLook.lookIndex = lookIndex

            generatedLooks.append(parsedLook)

            // Build a summary of this look and feed it into the next prompt.
            previousSummaries.append(GeneratedLookSummary(from: parsedLook))
            print("✅ [OutfitGenerationPipeline] Look \(lookIndex) accepted. \(generatedLooks.count)/\(totalLooks) complete.")
        }

        return generatedLooks
    }

    /// Synchronous generation for seamless instant UI transitions upon form submit.
    ///
    /// > Note: This path is only used when LLaMA cannot be called synchronously (e.g. from `init`).
    /// > The primary async path via `generateLooks(for:profile:)` runs real LLaMA inference.
    func generateLooksSync(
        for occasion: OccasionItem,
        profile: UserProfile
    ) throws -> [OutfitLook] {
        // Validate that LLaMA can be used. Throws LLaMAError if model is missing or unreadable.
        try LLaMAResource.validateModelAvailability()

        // 1. If an injected LLM response JSON is available (prompt testing), decode directly:
        if let injectedJSON = OutfitGenerationPipeline.injectedLLMResponseJSON, !injectedJSON.isEmpty {
            if let looks = try? parseLooks(from: injectedJSON), !looks.isEmpty {
                print("✅ [OutfitGenerationPipeline] Using \(looks.count) looks with LLM-decided colors and garments.")
                return looks
            }
        }

        // LLaMA cannot run synchronously from an init context — throw so the caller shows an error
        // instead of silently producing identical static looks.
        throw LLaMAError.modelNotFound("LLaMA inference requires the async generateLooks(for:profile:) call path.")
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
    public func parseLooks(from jsonString: String, colorSeason: ColorSeason? = nil) throws -> [OutfitLook] {
        var cleanJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip markdown code fences the model may have wrapped the JSON in
        cleanJSON = cleanJSON
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Try to decode the cleaned string directly as-is (happy path)
        if let looks = try? decodeLooks(from: cleanJSON, colorSeason: colorSeason), !looks.isEmpty {
            return looks
        }

        // 2. Extract the first balanced { ... } block (cuts off trailing garbage like `}]` or extra tokens)
        if let balanced = extractFirstBalancedJSONObject(from: cleanJSON),
           let looks = try? decodeLooks(from: balanced, colorSeason: colorSeason), !looks.isEmpty {
            print("✅ [OutfitGenerationPipeline] Decoded look from balanced JSON block.")
            return looks
        }

        // 3. Extract the outermost { ... } blob from mixed prose+JSON output
        if let extracted = extractJSONObject(from: cleanJSON),
           let looks = try? decodeLooks(from: extracted, colorSeason: colorSeason), !looks.isEmpty {
            print("⚠️ [OutfitGenerationPipeline] Extracted JSON from mixed output.")
            return looks
        }

        // 4. Try wrapping with {"looks":[ ... ]} if it was an unnested look continuation
        if !cleanJSON.contains("\"looks\"") {
            let wrapped = "{\"looks\":[" + cleanJSON + "]}"
            if let looks = try? decodeLooks(from: wrapped, colorSeason: colorSeason), !looks.isEmpty {
                return looks
            }
            if let balancedWrapped = extractFirstBalancedJSONObject(from: wrapped),
               let looks = try? decodeLooks(from: balancedWrapped, colorSeason: colorSeason), !looks.isEmpty {
                return looks
            }
        }

        // 5. Auto-fix repeated `"garments": [` keys if present
        let sanitized = sanitizeMalformedLLMJSON(cleanJSON)
        if sanitized != cleanJSON {
            if let looks = try? decodeLooks(from: sanitized, colorSeason: colorSeason), !looks.isEmpty {
                return looks
            }
            if let balanced = extractFirstBalancedJSONObject(from: sanitized),
               let looks = try? decodeLooks(from: balanced, colorSeason: colorSeason), !looks.isEmpty {
                return looks
            }
        }

        // 6. JSON may be truncated (model hit maxTokens mid-generation). Try closing open
        //    brackets so the partial output becomes valid JSON with whatever looks were completed.
        let repaired = repairTruncatedJSON(cleanJSON)
        do {
            let looks = try decodeLooks(from: repaired, colorSeason: colorSeason)
            if !looks.isEmpty {
                print("⚠️ [OutfitGenerationPipeline] Decoded \(looks.count) looks from repaired truncated JSON.")
                return looks
            }
        } catch {
            print("⚠️ [OutfitGenerationPipeline] Repaired JSON decode failed: \(error.localizedDescription)")
        }

        // 7. Fallback: Parse individual garment objects directly if the wrapper was badly mangled
        if let fallbackLooks = extractLooksFromMalformedText(cleanJSON, colorSeason: colorSeason), !fallbackLooks.isEmpty {
            print("⚠️ [OutfitGenerationPipeline] Recovered \(fallbackLooks.count) looks using garment scanner fallback.")
            return fallbackLooks
        }

        // All strategies failed — throw with the raw output for debugging
        throw LLaMAError.invalidOutput("Could not parse JSON from LLaMA output (\(cleanJSON.count) chars):\n\(cleanJSON)")
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
    private func extractLooksFromMalformedText(_ text: String, colorSeason: ColorSeason?) -> [OutfitLook]? {
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
        let palette = colorSeason?.palette ?? []

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
                            let cat = GarmentCategory(rawValue: dto.category.capitalized) ?? .top
                            let color = resolveSeasonalColor(rawName: dto.colorName, rawHex: dto.hexColor, palette: palette)
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
        let trimmedGarments = Array(garments.prefix(3))
        for g in trimmedGarments {
            g.outfitLook = look
        }
        look.garments = trimmedGarments
        return [look]
    }

    // MARK: - JSON Parsing Helpers

    private func decodeLooks(from jsonString: String, colorSeason: ColorSeason? = nil) throws -> [OutfitLook] {
        guard let data = jsonString.data(using: .utf8) else {
            throw LLaMAError.invalidOutput("Unable to convert JSON string to UTF-8 data")
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
            throw LLaMAError.invalidOutput("Unable to decode looks from JSON")
        }

        let palette = colorSeason?.palette ?? []
        var looks: [OutfitLook] = []
        for lookDTO in lookDTOs {
            let look = OutfitLook(
                lookIndex: lookDTO.lookIndex,
                fitRationale: lookDTO.fitRationale,
                isBookmarked: false,
                lookImageData: nil
            )
            var garments: [GarmentItem] = []
            // Limit to at most 3 garments per look (Outer, Top, Bottom)
            let trimmedGarments = Array(lookDTO.garments.prefix(3))
            for gDTO in trimmedGarments {
                let cat = GarmentCategory(rawValue: gDTO.category.capitalized) ?? .top

                // Harmonize / snap color to the closest valid seasonal swatch if palette is available
                let resolvedColor = resolveSeasonalColor(
                    rawName: gDTO.colorName,
                    rawHex: gDTO.hexColor,
                    palette: palette
                )

                let garment = GarmentItem(
                    category: cat,
                    name: gDTO.name,
                    material: gDTO.material,
                    colorName: resolvedColor.name,
                    hexColor: resolvedColor.hex,
                    rationale: gDTO.rationale
                )
                garment.outfitLook = look
                garments.append(garment)
            }
            look.garments = garments
            looks.append(look)
        }
        return looks
    }

    /// Snaps the model's generated color name/hex code to the verified seasonal palette swatch.
    /// If the model outputs a hallucinated name/hex, this finds the best matching seasonal color.
    private func resolveSeasonalColor(
        rawName: String,
        rawHex: String,
        palette: [ColorSeason.ColorSwatch]
    ) -> (name: String, hex: String) {
        guard !palette.isEmpty else {
            return (rawName, rawHex.hasPrefix("#") ? rawHex : "#\(rawHex)")
        }

        // 1. Exact or normalized hex match in palette
        let cleanHex = rawHex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
        if let match = palette.first(where: {
            $0.hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased() == cleanHex
        }) {
            return (match.name, match.hex)
        }

        // 2. Exact or substring name match in palette
        let lowerName = rawName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = palette.first(where: {
            let palName = $0.name.lowercased()
            return palName == lowerName || palName.contains(lowerName) || lowerName.contains(palName)
        }) {
            return (match.name, match.hex)
        }

        // 3. If the model hallucinated a completely unknown color, fallback to a harmonious palette swatch
        // based on hash consistency so it's stable and strictly adheres to the user's season.
        let stableIndex = abs(rawName.hashValue) % palette.count
        let fallback = palette[stableIndex]
        return (fallback.name, fallback.hex)
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
        // Partition swatches into stylist tonal roles for harmonic outfit coordination
        let neutralCount = min(8, swatches.count)
        let neutrals = Array(swatches[0..<neutralCount])
        let accents = Array(swatches[neutralCount..<min(20, swatches.count)])
        let statements = Array(swatches[min(20, swatches.count)..<swatches.count])

        // Harmonic Color Selection across the 35 swatches:
        // 1. Outerwear: grounding neutral or deep tonal statement layer
        let c1: ColorSeason.ColorSwatch = (index % 2 == 0)
            ? (neutrals.indices.contains(index) ? neutrals[index] : swatches[0])
            : (statements.isEmpty ? swatches[(index + 15) % swatches.count] : statements[(index * 2) % statements.count])

        // 2. Top: flattering, vivid seasonal accent near the face
        let c2: ColorSeason.ColorSwatch = accents.isEmpty
            ? swatches[(index * 4 + 7) % swatches.count]
            : accents[(index * 2 + 1) % accents.count]

        // 3. Bottom: foundational grounding neutral trousers/skirt
        let c3: ColorSeason.ColorSwatch = neutrals.isEmpty
            ? swatches[(index + 4) % swatches.count]
            : neutrals[(index + 3) % neutrals.count]

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
