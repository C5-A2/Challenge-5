//
//  ReferenceImageStyleAnalyzer.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 31/10/26.
//

import Foundation

/// Structured stylistic and visual profile extracted from reference images by the Vision-Language Model.
public struct ReferenceImageStyleProfile: Sendable, Codable, Equatable {
    /// Natural language description of the outfit styling.
    public var textDescription: String

    public var genreVibe: String
    public var persona: String
    public var fit: String
    public var cuts: [String]
    public var materials: [String]
    public var patterns: [String]
    public var colors: String

    // MARK: - Backward Compatibility Properties
    public var aestheticVibes: [String] {
        [genreVibe, persona].filter { !$0.isEmpty }
    }
    public var silhouettes: [String] {
        cuts.isEmpty ? (fit.isEmpty ? [] : [fit]) : cuts
    }
    public var texturesAndFabrics: [String] {
        materials + patterns
    }
    public var stylingCues: [String] {
        [fit].filter { !$0.isEmpty }
    }
    public var colorHarmony: String? {
        colors.isEmpty ? nil : colors
    }

    public init(
        textDescription: String = "",
        genreVibe: String = "",
        persona: String = "",
        fit: String = "",
        cuts: [String] = [],
        materials: [String] = [],
        patterns: [String] = [],
        colors: String = ""
    ) {
        self.textDescription = textDescription
        self.genreVibe = genreVibe
        self.persona = persona
        self.fit = fit
        self.cuts = cuts
        self.materials = materials
        self.patterns = patterns
        self.colors = colors
    }

    /// Formats the profile into a high-density structured context block for the Qwen 2.5 3B prompt.
    public var formattedPromptContext: String {
        if !textDescription.isEmpty {
            return textDescription
        }
        var lines: [String] = []
        if !genreVibe.isEmpty { lines.append("• Aesthetic: \(genreVibe)") }
        if !cuts.isEmpty { lines.append("• Cuts: \(cuts.joined(separator: ", "))") }
        if !materials.isEmpty { lines.append("• Materials: \(materials.joined(separator: ", "))") }
        if !patterns.isEmpty { lines.append("• Pattern: \(patterns.joined(separator: ", "))") }
        if !colors.isEmpty { lines.append("• Color Mood: \(colors)") }
        return lines.joined(separator: "\n")
    }
}

/// Analyzes user reference photos to extract detailed fashion styling descriptions
/// using the on-device Qwen 2.5 VL 3B Vision-Language Model exclusively.
///
/// Features:
/// - Post-submit 1-by-1 image scanning: Runs in the loading state right after form submission before main LLM generation.
/// - Safe VRAM handoff: Releases any resident text LLM weights before loading VLM, and unloads VLM (~2.6 GB) immediately after scanning.
/// - Debug persistence: Stores extracted VLM descriptions per occasion so `OccasionOutputView` can display them for developer inspection.
public final class ReferenceImageStyleAnalyzer: Sendable {

    public static let shared = ReferenceImageStyleAnalyzer()

    private let cacheLock = NSLock()
    private var imageCache: [Int: String] = [:]

    private init() {}

    // MARK: - Debug Persistence Helpers

    private static func debugStorageKey(for occasionID: UUID) -> String {
        "vlm_debug_descriptions_\(occasionID.uuidString)"
    }

    private static func recapStorageKey(for occasionID: UUID) -> String {
        "vlm_recap_\(occasionID.uuidString)"
    }

    /// Persists the single-paragraph recap of all reference descriptions for an occasion.
    public func saveRecap(_ recap: String, forOccasionID occasionID: UUID) {
        UserDefaults.standard.set(recap, forKey: Self.recapStorageKey(for: occasionID))
    }

    /// Retrieves the cached single-paragraph recap for an occasion, if any.
    public func savedRecap(forOccasionID occasionID: UUID) -> String? {
        let value = UserDefaults.standard.string(forKey: Self.recapStorageKey(for: occasionID))
        return (value?.isEmpty == false) ? value : nil
    }

    /// Persists extracted 1-by-1 VLM descriptions for an occasion so `OccasionOutputView` can display them.
    public func saveDescriptions(_ descriptions: [String], forOccasionID occasionID: UUID) {
        let key = Self.debugStorageKey(for: occasionID)
        // New/changed descriptions invalidate any previously recapped paragraph.
        UserDefaults.standard.removeObject(forKey: Self.recapStorageKey(for: occasionID))
        if descriptions.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set(descriptions, forKey: key)
        }
    }

    /// Retrieves previously extracted VLM descriptions for an occasion, if any.
    public func savedDescriptions(forOccasionID occasionID: UUID) -> [String] {
        let key = Self.debugStorageKey(for: occasionID)
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    // MARK: - Primary 1-by-1 Analysis API

    /// Analyzes an array of reference images 1-by-1 in a single VLM session without reloading weights between images.
    ///
    /// - Parameters:
    ///   - imagesData: Raw JPEG/PNG data buffers of user reference photos (up to 3).
    ///   - onProgress: Optional `@MainActor` progress callback invoked with `(completedCount, totalCount, descriptionsSoFar)`.
    /// - Returns: An array of natural text styling descriptions, one corresponding to each input image.
    public func analyzeIndividualImages(
        for imagesData: [Data],
        onProgress: (@MainActor @Sendable (Int, Int, [String]) -> Void)? = nil
    ) async -> [String] {
        guard !imagesData.isEmpty else { return [] }

        // Check cache for already analyzed images
        var results: [String] = []
        var uncachedIndices: [Int] = []
        var uncachedData: [Data] = []

        cacheLock.lock()
        for (index, data) in imagesData.enumerated() {
            var hasher = Hasher()
            hasher.combine(data)
            let hash = hasher.finalize()
            if let cached = imageCache[hash] {
                results.append(cached)
            } else {
                results.append("") // Placeholder to be filled
                uncachedIndices.append(index)
                uncachedData.append(data)
            }
        }
        cacheLock.unlock()

        if uncachedIndices.isEmpty {
            print("👁️ [ReferenceImageStyleAnalyzer] All \(imagesData.count) reference images retrieved from cache.")
            let finalResults = results.filter { !$0.isEmpty }
            await onProgress?(finalResults.count, imagesData.count, finalResults)
            return finalResults
        }

        // Notify progress for any already-cached photos first
        let initialCached = results.filter { !$0.isEmpty }
        if !initialCached.isEmpty {
            await onProgress?(initialCached.count, imagesData.count, initialCached)
        }

        print("👁️ [ReferenceImageStyleAnalyzer] Scanning \(uncachedIndices.count)/\(imagesData.count) reference images on-device via VLM (1-by-1)...")

        // Ensure text LLM weights are released before loading VLM into Metal GPU memory
        await LLMEngine.shared.releaseModelWeights()

        // Pre-load VLM once for the entire batch
        do {
            try await VLMEngine.shared.loadIfNeeded()
        } catch {
            print("⚠️ [ReferenceImageStyleAnalyzer] Failed to pre-load VLM: \(error.localizedDescription)")
            return results.filter { !$0.isEmpty }
        }

        for (uIdx, data) in uncachedData.enumerated() {
            let originalIndex = uncachedIndices[uIdx]
            do {
                let description = try await VLMEngine.shared.analyzeImage(data: data)
                print("✅ [ReferenceImageStyleAnalyzer] Reference Photo \(originalIndex + 1) VLM description: \(description)")
                results[originalIndex] = description

                // Store in cache
                var hasher = Hasher()
                hasher.combine(data)
                let hash = hasher.finalize()
                cacheLock.lock()
                imageCache[hash] = description
                cacheLock.unlock()

                let snapshot = results.filter { !$0.isEmpty }
                await onProgress?(snapshot.count, imagesData.count, snapshot)
            } catch {
                print("⚠️ [ReferenceImageStyleAnalyzer] Reference Photo \(originalIndex + 1) VLM failed: \(error.localizedDescription)")
            }
        }

        // Unload VLM weights once at the end of the entire batch to free ~2.6 GB VRAM before main LLM runs
        await VLMEngine.shared.unload()
        return results.filter { !$0.isEmpty }
    }

    /// Analyzes reference photos and returns a formatted string descriptor combining all individual images.
    public func analyzeStyle(from imagesData: [Data]) async -> String? {
        let descriptions = await analyzeIndividualImages(for: imagesData)
        guard !descriptions.isEmpty else { return nil }
        return descriptions.enumerated().map { index, desc in
            "Reference Photo \(index + 1): \(desc)"
        }.joined(separator: "\n\n")
    }

    /// Formats an already-extracted array of individual descriptions into a combined context string.
    public static func formatCombinedStyle(from descriptions: [String]) -> String? {
        guard !descriptions.isEmpty else { return nil }
        return descriptions.enumerated().map { index, desc in
            "Reference Photo \(index + 1): \(desc)"
        }.joined(separator: "\n\n")
    }

    /// Backward compatibility method returning structured profiles.
    public func analyzeIndividualProfiles(for imagesData: [Data]) async -> [ReferenceImageStyleProfile?] {
        let descriptions = await analyzeIndividualImages(for: imagesData)
        return descriptions.map { desc in
            ReferenceImageStyleProfile(textDescription: desc)
        }
    }

    /// Backward compatibility method returning a single merged profile.
    public func analyzeStyleProfile(from imagesData: [Data]) async -> ReferenceImageStyleProfile? {
        guard let combined = await analyzeStyle(from: imagesData) else { return nil }
        return ReferenceImageStyleProfile(textDescription: combined)
    }
}

// MARK: - Reference Analysis for the Outfit Prompt

/// The VLM's reference descriptions, prepared for the per-look outfit prompt.
nonisolated struct ReferenceStyleAnalysis: Sendable {
    /// The reference outfits as text: the recap paragraph, or the per-photo descriptions.
    let promptDescription: String
    /// Every per-photo description, unshortened. The reference look copies from this,
    /// because the one-paragraph recap drops details (necklines, lengths, exact colors).
    let fullDescription: String
    /// The outfit structure the descriptions mention most, so the reference look keeps the same pieces.
    /// `nil` when the text doesn't make it clear.
    let suggestedStructure: OutfitStructure?

    /// Words in a VLM description that point to a one-piece outfit or an outer layer.
    private static let onePieceKeywords = ["dress", "gown", "jumpsuit", "romper", "playsuit"]
    private static let outerKeywords = ["jacket", "blazer", "coat", "cardigan", "outer", "kimono", "trench", "bomber"]

    /// - Parameters:
    ///   - descriptions: One VLM description per reference photo.
    ///   - recap: The single-paragraph recap of all descriptions, used as the prompt text when present.
    init?(descriptions: [String], recap: String?) {
        let cleaned = descriptions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return nil }

        fullDescription = cleaned.count == 1
            ? cleaned[0]
            : cleaned.enumerated()
                .map { "Photo \($0.offset + 1): \($0.element)" }
                .joined(separator: "\n")
        if let recap, !recap.isEmpty {
            promptDescription = recap
        } else {
            promptDescription = fullDescription
        }

        let structures = cleaned.map(Self.structure(in:))
        suggestedStructure = Dictionary(grouping: structures, by: { $0 })
            .max { $0.value.count < $1.value.count }?
            .key
    }

    /// The pieces one description mentions: a dress or jumpsuit (with or without an outer layer),
    /// or separates (with or without an outer layer).
    private static func structure(in description: String) -> OutfitStructure {
        // Whole words only: "dressed" or "petticoat" must not count as a dress or a coat.
        let words = Set(description.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty })
        func mentions(_ keyword: String) -> Bool {
            words.contains(keyword) || words.contains(keyword + "s") || words.contains(keyword + "es")
        }
        let hasOnePiece = onePieceKeywords.contains(where: mentions)
        let hasOuter = outerKeywords.contains(where: mentions)
        switch (hasOnePiece, hasOuter) {
        case (true, true): return .dressWithOuter
        case (true, false): return .dress
        case (false, true): return .outerTopBottom
        case (false, false): return .topBottom
        }
    }

    // MARK: - Reference Color Matching (within Seasonal Color Rules)

    /// A color mentioned in the reference photo description mapped to the user's seasonal palette.
    struct ReferenceColorMatch: Sendable {
        let referenceColor: String
        let swatch: ColorSeason.ColorSwatch
        /// `true` when the reference color is compatible with the user's `ColorSeason` rules
        /// (either a neutral mapped to `neutralSwatches`, or a chromatic color not in `colorsToAvoid`
        /// with a close swatch in `allSwatches`).
        let isWithinColorRules: Bool
    }

    /// Maximum RGB distance (`0...441.67`) for a chromatic reference color to be considered
    /// "not too far away" from the seasonal palette rules.
    private static let maximumAllowedChromaticDistance: Double = 95.0

    /// Known fashion color terms ordered from multi-word specific phrases to single words.
    private static let knownReferenceColors: [(term: String, hex: String, isNeutral: Bool)] = [
        // Multi-word neutrals
        ("off-white", "#F5F2EB", true),
        ("off white", "#F5F2EB", true),
        ("warm white", "#F3EFE6", true),
        ("light beige", "#E6DEC8", true),
        ("warm beige", "#DCC9AF", true),
        ("light grey", "#D0D2D1", true),
        ("light gray", "#D0D2D1", true),
        ("ash grey", "#B2B5B7", true),
        ("ash gray", "#B2B5B7", true),
        ("cool grey", "#A6ACB0", true),
        ("cool gray", "#A6ACB0", true),
        ("dark grey", "#4E5052", true),
        ("dark gray", "#4E5052", true),
        ("charcoal grey", "#424144", true),
        ("charcoal gray", "#424144", true),
        ("dark brown", "#4A342B", true),
        ("chocolate brown", "#4E342E", true),
        ("dark navy", "#1D2F52", true),
        ("navy blue", "#223A64", true),
        ("midnight blue", "#232B4A", true),
        ("jet black", "#222225", true),
        // Multi-word chromatic colors
        ("baby blue", "#A4C6E5", false),
        ("sky blue", "#8CC0DE", false),
        ("light blue", "#A8C5DA", false),
        ("powder blue", "#B0C4DE", false),
        ("pastel blue", "#B5CFE0", false),
        ("icy blue", "#CFE6F3", false),
        ("dusty blue", "#7C98AD", false),
        ("steel blue", "#5A7D9A", false),
        ("slate blue", "#53687E", false),
        ("royal blue", "#1D4E9E", false),
        ("cobalt blue", "#134798", false),
        ("electric blue", "#0066CC", false),
        ("denim blue", "#4E6E8E", false),
        ("sage green", "#9CAF88", false),
        ("mint green", "#A6DEC4", false),
        ("olive green", "#6B6E40", false),
        ("moss green", "#737A4C", false),
        ("forest green", "#254E3A", false),
        ("emerald green", "#146B48", false),
        ("lime green", "#89C93E", false),
        ("neon green", "#39FF14", false),
        ("deep burgundy", "#541E27", false),
        ("brick red", "#A63A2E", false),
        ("cherry red", "#B51D29", false),
        ("dusty rose", "#BA868E", false),
        ("dusty pink", "#C99AA2", false),
        ("blush pink", "#E8BFC3", false),
        ("baby pink", "#F2C9D0", false),
        ("pastel pink", "#F4CFD6", false),
        ("light pink", "#F2C6CE", false),
        ("hot pink", "#E33B7E", false),
        ("electric pink", "#F52887", false),
        ("butter yellow", "#F6E39F", false),
        ("pastel yellow", "#F7E8AA", false),
        ("light yellow", "#F7E7A4", false),
        ("mustard yellow", "#C89628", false),
        ("golden yellow", "#E6B432", false),
        ("burnt orange", "#C45626", false),
        // Single-word neutrals
        ("white", "#F2F2EE", true),
        ("ivory", "#F3ECD8", true),
        ("cream", "#EFE5CE", true),
        ("vanilla", "#F3E5C8", true),
        ("ecru", "#E6DEC8", true),
        ("beige", "#D8CBB8", true),
        ("oatmeal", "#CBC3B4", true),
        ("sand", "#D6C6B2", true),
        ("stone", "#C9C2B5", true),
        ("khaki", "#B8A98E", true),
        ("tan", "#C8A987", true),
        ("camel", "#C69C6D", true),
        ("taupe", "#9E9186", true),
        ("grey", "#9E9E9E", true),
        ("gray", "#9E9E9E", true),
        ("silver", "#C8CACA", true),
        ("charcoal", "#444245", true),
        ("espresso", "#45332E", true),
        ("chocolate", "#52372E", true),
        ("coffee", "#5A3D34", true),
        ("mocha", "#6E5246", true),
        ("brown", "#6A4A3A", true),
        ("navy", "#22385E", true),
        ("black", "#262629", true),
        // Single-word chromatic colors
        ("burgundy", "#6B212E", false),
        ("maroon", "#69222A", false),
        ("wine", "#6E2332", false),
        ("crimson", "#A81C2E", false),
        ("scarlet", "#C92A2A", false),
        ("red", "#BF2C34", false),
        ("terracotta", "#C46243", false),
        ("rust", "#B55233", false),
        ("coral", "#EB715E", false),
        ("peach", "#F4B499", false),
        ("apricot", "#F2AE82", false),
        ("salmon", "#EA8A78", false),
        ("orange", "#E3732F", false),
        ("tangerine", "#EC7A30", false),
        ("copper", "#B8653B", false),
        ("bronze", "#8E633B", false),
        ("mustard", "#C89628", false),
        ("marigold", "#EAA838", false),
        ("gold", "#D1A64A", false),
        ("amber", "#D8912E", false),
        ("yellow", "#F0CA4D", false),
        ("mint", "#A8DFC6", false),
        ("sage", "#9CAF88", false),
        ("pistachio", "#A9C98E", false),
        ("olive", "#6E7043", false),
        ("moss", "#757C4E", false),
        ("emerald", "#17724D", false),
        ("jade", "#2B8A68", false),
        ("green", "#3B7E52", false),
        ("teal", "#1E6F78", false),
        ("turquoise", "#2EB5B8", false),
        ("aqua", "#5DCAD0", false),
        ("periwinkle", "#8FA2D4", false),
        ("cornflower", "#6488C4", false),
        ("chambray", "#6A89A8", false),
        ("denim", "#4E6E8E", false),
        ("cobalt", "#164A9A", false),
        ("indigo", "#2D386C", false),
        ("blue", "#34689E", false),
        ("lavender", "#B8A4D4", false),
        ("lilac", "#C6AED8", false),
        ("mauve", "#A67B94", false),
        ("plum", "#6A365A", false),
        ("violet", "#744896", false),
        ("purple", "#6B3F8A", false),
        ("magenta", "#C82874", false),
        ("fuchsia", "#CA2C78", false),
        ("berry", "#9B2959", false),
        ("blush", "#E6B8BE", false),
        ("rose", "#C96A7B", false),
        ("pink", "#E2849B", false)
    ]

    /// Extracts colors mentioned in the reference photo description and maps each to the closest
    /// swatch in `colorSeason`, indicating whether it stays within the season's color rules.
    func colorMatches(for colorSeason: ColorSeason) -> [ReferenceColorMatch] {
        let lowerText = " " + promptDescription.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ") + " "
        let avoidText = " " + colorSeason.colorsToAvoid.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ") + " "

        let neutrals = colorSeason.neutralSwatches
        let allSwatches = colorSeason.allSwatches
        guard !allSwatches.isEmpty else { return [] }

        var remainingText = lowerText
        var matches: [(position: Int, match: ReferenceColorMatch)] = []

        for entry in Self.knownReferenceColors {
            let normalizedTerm = entry.term.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            let needle = " \(normalizedTerm) "
            guard let range = remainingText.range(of: needle),
                  let targetRGB = Self.rgb(fromHex: entry.hex) else { continue }

            let position = remainingText.distance(from: remainingText.startIndex, to: range.lowerBound)
            // Mask matched words so "light blue" doesn't also trigger single-word "blue"
            let mask = String(repeating: " ", count: needle.count)
            remainingText.replaceSubrange(range, with: mask)

            if entry.isNeutral, !neutrals.isEmpty {
                // Neutral colors map to the season's curated foundation neutrals (or a closer neutral in allSwatches)
                if let closestNeutral = neutrals.min(by: {
                    Self.distance(targetRGB, Self.rgb(fromHex: $0.hex)) < Self.distance(targetRGB, Self.rgb(fromHex: $1.hex))
                }) {
                    matches.append((position, ReferenceColorMatch(
                        referenceColor: entry.term,
                        swatch: closestNeutral,
                        isWithinColorRules: true
                    )))
                }
            } else {
                // Chromatic color: check whether the season explicitly avoids it and how close the nearest palette swatch is
                let explicitlyAvoided = avoidText.contains(needle)
                if let closestSwatch = allSwatches.min(by: {
                    Self.distance(targetRGB, Self.rgb(fromHex: $0.hex)) < Self.distance(targetRGB, Self.rgb(fromHex: $1.hex))
                }) {
                    let dist = Self.distance(targetRGB, Self.rgb(fromHex: closestSwatch.hex))
                    let withinRules = !explicitlyAvoided && dist <= Self.maximumAllowedChromaticDistance
                    matches.append((position, ReferenceColorMatch(
                        referenceColor: entry.term,
                        swatch: closestSwatch,
                        isWithinColorRules: withinRules
                    )))
                }
            }
        }

        return matches
            .sorted { $0.position < $1.position }
            .map(\.match)
    }

    private static func rgb(fromHex hex: String) -> (r: Double, g: Double, b: Double)? {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return (Double((value >> 16) & 0xFF), Double((value >> 8) & 0xFF), Double(value & 0xFF))
    }

    private static func distance(_ a: (r: Double, g: Double, b: Double), _ b: (r: Double, g: Double, b: Double)?) -> Double {
        guard let b else { return .infinity }
        let dr = a.r - b.r
        let dg = a.g - b.g
        let db = a.b - b.b
        return (dr * dr + dg * dg + db * db).squareRoot()
    }
}
