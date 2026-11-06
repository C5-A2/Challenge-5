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
