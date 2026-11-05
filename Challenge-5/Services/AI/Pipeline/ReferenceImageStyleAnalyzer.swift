//
//  ReferenceImageStyleAnalyzer.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 31/10/26.
//

import Foundation

/// Structured stylistic and visual profile extracted from reference images by the Vision-Language Model.
public struct ReferenceImageStyleProfile: Sendable, Codable, Equatable {
    /// Fashion Genre & Aesthetic Vibe (e.g. "Quiet Luxury", "Old Money", "Modern Streetwear", "Clean Minimalist")
    public var genreVibe: String

    /// Stylistic Persona (e.g. "Elevated Minimalist", "Chic Professional", "Relaxed Creative")
    public var persona: String

    /// Fit & Proportions (e.g. "Oversized / Boxy", "Relaxed Fit", "Tailored Regular", "Fitted / Slim")
    public var fit: String

    /// Garment Cuts & Silhouettes (e.g. "Structured blazer cut", "High-rise wide-leg trousers", "Cropped clean hem")
    public var cuts: [String]

    /// Materials & Tactile Fabrics (e.g. "Matte wool twill", "Crisp cotton poplin", "Ribbed knit", "Raw denim")
    public var materials: [String]

    /// Patterns & Surface Details (e.g. "Solid / Unpatterned", "Pinstripe weave", "Houndstooth", "Textured knit")
    public var patterns: [String]

    /// Color Mood & Palette Tone (e.g. "Warm camel and oatmeal neutrals with soft charcoal contrast")
    public var colors: String

    // MARK: - Backward Compatibility Properties
    public var aestheticVibes: [String] {
        [genreVibe, persona].filter { !$0.isEmpty }
    }
    public var silhouettes: [String] {
        cuts.isEmpty ? [fit] : cuts
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
        genreVibe: String = "",
        persona: String = "",
        fit: String = "",
        cuts: [String] = [],
        materials: [String] = [],
        patterns: [String] = [],
        colors: String = ""
    ) {
        self.genreVibe = genreVibe
        self.persona = persona
        self.fit = fit
        self.cuts = cuts
        self.materials = materials
        self.patterns = patterns
        self.colors = colors
    }

    enum CodingKeys: String, CodingKey {
        case genreVibe
        case persona
        case fit
        case cuts
        case materials
        case patterns
        case colors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.genreVibe = (try? container.decode(String.self, forKey: .genreVibe)) ?? ""
        self.persona = (try? container.decode(String.self, forKey: .persona)) ?? ""
        self.fit = (try? container.decode(String.self, forKey: .fit)) ?? ""

        // Flexible array or comma-separated string decoding for cuts
        if let cutsArray = try? container.decode([String].self, forKey: .cuts) {
            self.cuts = cutsArray
        } else if let cutsString = try? container.decode(String.self, forKey: .cuts) {
            self.cuts = cutsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else {
            self.cuts = []
        }

        // Flexible array or string for materials
        if let matsArray = try? container.decode([String].self, forKey: .materials) {
            self.materials = matsArray
        } else if let matsString = try? container.decode(String.self, forKey: .materials) {
            self.materials = matsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else {
            self.materials = []
        }

        // Flexible array or string for patterns
        if let patsArray = try? container.decode([String].self, forKey: .patterns) {
            self.patterns = patsArray
        } else if let patsString = try? container.decode(String.self, forKey: .patterns) {
            self.patterns = patsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else {
            self.patterns = []
        }

        // Flexible string or array for colors
        if let colorsString = try? container.decode(String.self, forKey: .colors) {
            self.colors = colorsString
        } else if let colorsArray = try? container.decode([String].self, forKey: .colors) {
            self.colors = colorsArray.joined(separator: ", ")
        } else {
            self.colors = ""
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(genreVibe, forKey: .genreVibe)
        try container.encode(persona, forKey: .persona)
        try container.encode(fit, forKey: .fit)
        try container.encode(cuts, forKey: .cuts)
        try container.encode(materials, forKey: .materials)
        try container.encode(patterns, forKey: .patterns)
        try container.encode(colors, forKey: .colors)
    }

    /// Formats the profile into a high-density structured context block for the Qwen 2.5 3B prompt.
    public var formattedPromptContext: String {
        var lines: [String] = []

        if !genreVibe.isEmpty {
            lines.append("• Genre & Aesthetic Vibe: \(genreVibe)")
        }
        if !persona.isEmpty {
            lines.append("• Stylistic Persona: \(persona)")
        }
        if !fit.isEmpty {
            lines.append("• Fit & Proportions: \(fit)")
        }
        if !cuts.isEmpty {
            lines.append("• Cut & Silhouettes: \(cuts.joined(separator: ", "))")
        }
        if !materials.isEmpty {
            lines.append("• Materials & Fabrics: \(materials.joined(separator: ", "))")
        }
        if !patterns.isEmpty {
            lines.append("• Pattern & Surface: \(patterns.joined(separator: ", "))")
        }
        if !colors.isEmpty {
            lines.append("• Color Mood & Tone: \(colors)")
        }

        return lines.joined(separator: "\n")
    }
}

/// Analyzes user reference photos to extract detailed fashion attributes and keywords
/// using the on-device Qwen 2.5 VL 3B Vision-Language Model exclusively.
///
/// All analysis is performed 100% on-device via `VLMEngine`. There is no Apple Vision,
/// CoreImage, or any network-based fallback. If the VLM fails for a given image, that
/// image simply returns `nil` — the caller decides whether to skip or surface an error.
public final class ReferenceImageStyleAnalyzer: Sendable {

    public static let shared = ReferenceImageStyleAnalyzer()

    private let cacheLock = NSLock()
    private var cachedProfile: (hash: Int, profile: ReferenceImageStyleProfile)? = nil

    private init() {}

    // MARK: - Primary Analysis API

    /// Analyzes an array of reference images in a single VLM session without reloading weights between images.
    ///
    /// - Returns: One optional `ReferenceImageStyleProfile` per input image. `nil` entries mean the
    ///   VLM failed for that image (e.g. JSON parse error). The caller should skip `nil` entries.
    public func analyzeIndividualProfiles(for imagesData: [Data]) async -> [ReferenceImageStyleProfile?] {
        guard !imagesData.isEmpty else { return [] }

        print("👁️ [ReferenceImageStyleAnalyzer] Starting single-session batch VLM analysis for \(imagesData.count) images...")

        // Pre-load VLM once for the entire batch
        do {
            try await VLMEngine.shared.loadIfNeeded()
        } catch {
            print("⚠️ [ReferenceImageStyleAnalyzer] Failed to pre-load VLM: \(error.localizedDescription)")
            // Return all nils — no fallback
            return Array(repeating: nil, count: imagesData.count)
        }

        var profiles: [ReferenceImageStyleProfile?] = []
        for (idx, data) in imagesData.enumerated() {
            do {
                let profile = try await VLMEngine.shared.analyzeImage(data: data)
                print("✅ [ReferenceImageStyleAnalyzer] Image \(idx) VLM succeeded: genre=\(profile.genreVibe), cuts=\(profile.cuts.joined(separator: ", "))")
                profiles.append(profile)
            } catch {
                print("⚠️ [ReferenceImageStyleAnalyzer] Image \(idx) VLM failed: \(error.localizedDescription)")
                profiles.append(nil)
            }
        }

        // Unload VLM weights once at the end of the entire batch to free ~2.6 GB VRAM
        await VLMEngine.shared.unload()
        return profiles
    }

    /// Analyzes reference photos and returns a merged `ReferenceImageStyleProfile` combining all images.
    public func analyzeStyleProfile(from imagesData: [Data]) async -> ReferenceImageStyleProfile? {
        guard !imagesData.isEmpty else { return nil }

        var hasher = Hasher()
        for data in imagesData {
            hasher.combine(data)
        }
        let dataHash = hasher.finalize()

        cacheLock.lock()
        if let cached = cachedProfile, cached.hash == dataHash {
            cacheLock.unlock()
            print("👁️ [ReferenceImageStyleAnalyzer] Returning cached reference style profile.")
            return cached.profile
        }
        cacheLock.unlock()

        let individualProfiles = await analyzeIndividualProfiles(for: imagesData)
        var gatheredCuts: [String] = []
        var gatheredMaterials: [String] = []
        var gatheredPatterns: [String] = []
        var gatheredColors: [String] = []
        var finalGenreVibe = ""
        var finalPersona = ""
        var finalFit = ""

        for maybeProfile in individualProfiles {
            guard let profile = maybeProfile else { continue }
            if finalGenreVibe.isEmpty && !profile.genreVibe.isEmpty { finalGenreVibe = profile.genreVibe }
            if finalPersona.isEmpty && !profile.persona.isEmpty { finalPersona = profile.persona }
            if finalFit.isEmpty && !profile.fit.isEmpty { finalFit = profile.fit }

            for cut in profile.cuts where !gatheredCuts.contains(cut) {
                gatheredCuts.append(cut)
            }
            for mat in profile.materials where !gatheredMaterials.contains(mat) {
                gatheredMaterials.append(mat)
            }
            for pat in profile.patterns where !gatheredPatterns.contains(pat) {
                gatheredPatterns.append(pat)
            }
            if !profile.colors.isEmpty && !gatheredColors.contains(profile.colors) {
                gatheredColors.append(profile.colors)
            }
        }

        guard !gatheredCuts.isEmpty || !gatheredMaterials.isEmpty || !gatheredPatterns.isEmpty || !gatheredColors.isEmpty else {
            return nil
        }

        let mergedProfile = ReferenceImageStyleProfile(
            genreVibe: finalGenreVibe,
            persona: finalPersona,
            fit: finalFit,
            cuts: gatheredCuts,
            materials: gatheredMaterials,
            patterns: gatheredPatterns,
            colors: gatheredColors.joined(separator: " • ")
        )
        cacheLock.lock()
        cachedProfile = (dataHash, mergedProfile)
        cacheLock.unlock()
        return mergedProfile
    }

    /// Analyzes reference photos and returns a formatted string descriptor ready for Qwen 2.5 3B prompt injection.
    public func analyzeStyle(from imagesData: [Data]) async -> String? {
        let profile = await analyzeStyleProfile(from: imagesData)
        guard let validProfile = profile, !validProfile.formattedPromptContext.isEmpty else {
            return nil
        }
        return validProfile.formattedPromptContext
    }
}
