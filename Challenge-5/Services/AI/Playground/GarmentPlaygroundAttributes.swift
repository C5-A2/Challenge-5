//
//  GarmentPlaygroundAttributes.swift
//  Challenge-5
//
//  Created by Michael David Sin on 28/10/26.⁄
//

import Foundation

/// Structured specification of an individual garment extracted for the visual generation pipeline (C5-46).
struct GarmentPlaygroundAttributes: Codable, Sendable, Identifiable, Hashable {
    
    // MARK: - Properties
    
    let id: UUID
    let category: GarmentCategory
    let name: String                        // e.g. "Polo Shirt"
    let clothingType: String                // e.g. "Slim-fit collared polo shirt"
    let colorHex: String                    // e.g. "#1A1A1A"
    let colorName: String                   // e.g. "Charcoal Black"
    let fabricMaterial: String              // e.g. "French Terry Cotton"
    let fitSilhouette: String               // e.g. "Structured slim fit with tapered waist"
    let stylingDetails: String?             // e.g. "Open quarter placket with clean collar"
    let playgroundPrompt: String?           // Clean AI visual prompt from LLM
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        category: GarmentCategory,
        name: String,
        clothingType: String? = nil,
        colorHex: String,
        colorName: String,
        fabricMaterial: String,
        fitSilhouette: String? = nil,
        stylingDetails: String? = nil,
        playgroundPrompt: String? = nil
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.clothingType = clothingType ?? name
        self.colorHex = colorHex
        self.colorName = colorName
        self.fabricMaterial = fabricMaterial
        self.fitSilhouette = fitSilhouette ?? "Tailored fit"
        self.stylingDetails = stylingDetails
        self.playgroundPrompt = playgroundPrompt
    }
}

/// Full package combining structured garment attributes and human body descriptors
/// ready to feed into Apple Image Playground or on-device visual generation models (C5-46).
struct OutfitPlaygroundPackage: Codable, Sendable, Identifiable {
    
    // MARK: - Properties
    
    let id: UUID
    let lookIndex: Int
    let occasionTitle: String
    let dresscode: String
    
    // Physical Person / Model Persona Descriptor
    let bodyTypeName: String                // e.g. "Inverted Triangle"
    let torsoBalanceName: String            // e.g. "Balanced Torso"
    let colorSeasonName: String             // e.g. "Deep Winter"
    let modelGenderPose: String             // e.g. "Full-body standing model, front facing"
    
    // Structured Garments
    let garments: [GarmentPlaygroundAttributes]
    
    // Synthesized Composite Prompt for Image Playground
    let compositeVisualPrompt: String
    
    // High-resolution negative prompt to prevent artifacts
    let negativePrompt: String
    
    // Variation level (0 = primary full phrase, incremented on Regenerate for alternate wording)
    let variationIndex: Int

    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        lookIndex: Int,
        occasionTitle: String,
        dresscode: String,
        bodyTypeName: String,
        torsoBalanceName: String,
        colorSeasonName: String,
        modelGenderPose: String = "Full-body studio photograph, elegant standing model facing front against neutral background with soft floor shadow",
        garments: [GarmentPlaygroundAttributes],
        compositeVisualPrompt: String,
        negativePrompt: String = "deformed limbs, extra arms, missing legs, distorted face, blurry fabric, low resolution, multiple people",
        variationIndex: Int = 0
    ) {
        self.id = id
        self.lookIndex = lookIndex
        self.occasionTitle = occasionTitle
        self.dresscode = dresscode
        self.bodyTypeName = bodyTypeName
        self.torsoBalanceName = torsoBalanceName
        self.colorSeasonName = colorSeasonName
        self.modelGenderPose = modelGenderPose
        self.garments = garments
        self.compositeVisualPrompt = compositeVisualPrompt
        self.negativePrompt = negativePrompt
        self.variationIndex = variationIndex
    }
}

extension OutfitPlaygroundPackage {
    enum UpperSleeveCoverage: Sendable {
        case long
        case short
        case sleeveless
    }

    private static let sleevelessMarkers = [
        "sleeveless", "halter", "strapless", "off-shoulder", "off shoulder",
        "tank", "spaghetti", "tube", "camisole", "one-shoulder", "one shoulder", "bustier"
    ]

    private static let shortSleeveMarkers = [
        "short-sleeve", "short sleeve", "cap-sleeve", "cap sleeve",
        "flutter sleeve", "puff sleeve", "t-shirt", "tee", "polo"
    ]

    /// Detects whether the recommended outfit exposes arms so `sourceImage` and prompt cues
    /// can suppress lingering long-sleeve silhouettes from the user's photo.
    var upperSleeveCoverage: UpperSleeveCoverage {
        if garments.contains(where: { $0.category == .outer }) { return .long }
        let upperText = garments
            .filter { $0.category == .top || $0.category == .dress }
            .map { "\($0.name) \($0.playgroundPrompt ?? "")".lowercased() }
            .joined(separator: " ")
        if Self.sleevelessMarkers.contains(where: { upperText.contains($0) }) { return .sleeveless }
        if Self.shortSleeveMarkers.contains(where: { upperText.contains($0) }) { return .short }
        return .long
    }
}

// MARK: - Native Apple ImagePlayground Integration (iOS 18.2+)

#if canImport(ImagePlayground)
import ImagePlayground

extension OutfitPlaygroundPackage {
    
    // MARK: - Safety Seatbelt (Sanitizer for Image Playground)
    
    /// Words that trigger Apple Image Playground's sensitive content or safety filter.
    private static let blockedWords: Set<String> = [
        "sheer", "translucent", "transparent", "mesh", "see-through", "fishnet",
        "revealing", "sexy", "naked", "nude", "skin", "flesh", "cutout", "cut-out",
        "slit", "plunging", "deep-v", "low-cut", "cleavage", "waist", "swallowtail",
        "corset", "boning", "mini", "micro", "bodycon", "bralette", "lingerie"
    ]

    /// Neutral garment-noun replacements for sensitive terms so the silhouette stays coherent.
    private static let tokenReplacements: [String: String] = [
        "bustier": "top",
        "camisole": "top",
        "cami": "top",
        "bodysuit": "top",
        "bikini": "top"
    ]

    /// Dangling trailing words trimmed after filtered tokens are removed.
    private static let trailingConnectors: Set<String> = [
        "with", "and", "or", "in", "on", "at", "of", "for", "to", "by", "from",
        "over", "under", "featuring", "detail", "details", "a", "an", "the"
    ]
    
    /// Sanitizes garment text, stripping guardrail-triggering words and ensuring proper outer sleeves.
    private static func sanitizePrompt(_ text: String, category: GarmentCategory, hasOuter: Bool) -> String {
        let tokens = text.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        var cleanTokens: [String] = []
        for token in tokens {
            let lower = token.lowercased()
            guard !blockedWords.contains(lower) else { continue }
            let mapped = tokenReplacements[lower] ?? token
            if cleanTokens.last?.lowercased() != mapped.lowercased() {
                cleanTokens.append(mapped)
            }
        }
        while let last = cleanTokens.last, trailingConnectors.contains(last.lowercased()) {
            cleanTokens.removeLast()
        }
        var cleaned = cleanTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            cleaned = "\(category.rawValue.lowercased())"
        }
        
        if category == .outer {
            // Strip sleeve-shortening words and enforce full-length sleeves
            cleaned = cleaned
                .replacingOccurrences(of: "short-sleeve", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "short sleeve", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "sleeveless", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "cropped", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.localizedCaseInsensitiveContains("long-sleeve") &&
               !cleaned.localizedCaseInsensitiveContains("long sleeve") &&
               !cleaned.localizedCaseInsensitiveContains("vest") {
                cleaned = "long-sleeve \(cleaned)"
            }
        } else if hasOuter && (category == .top || category == .dress) {
            // When worn under an outer layer, remove conflicting sleeve/shoulder descriptors
            cleaned = cleaned
                .replacingOccurrences(of: "sleeveless", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "spaghetti-strap", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "tank top", with: "top", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
    
    /// Ensures the word "color" follows the garment's color name so literal swatch names
    /// (e.g. "Sweet Corn", "Peach", "Tofu", "Lemonade") are interpreted as colors rather than printed motifs.
    private static func ensureColorWord(in prompt: String, colorName: String) -> String {
        let trimmedColor = colorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedColor.isEmpty else { return prompt }

        let lowerWords = prompt.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        if lowerWords.contains("color") || lowerWords.contains("colored") {
            return prompt
        }

        if let range = prompt.range(of: trimmedColor, options: .caseInsensitive) {
            let matchedColor = String(prompt[range])
            return prompt.replacingCharacters(in: range, with: "\(matchedColor) color")
        }

        return "\(trimmedColor.lowercased()) color \(prompt)"
    }

    /// Derives a clean, safe noun for simplified Regenerate prompt variations.
    private static func safeCategoryNoun(for garment: GarmentPlaygroundAttributes) -> String {
        let lower = garment.name.lowercased()
        switch garment.category {
        case .outer:
            if lower.contains("cardigan") { return "cardigan" }
            if lower.contains("coat") || lower.contains("trench") { return "coat" }
            if lower.contains("blazer") { return "blazer" }
            return "jacket"
        case .top:
            if lower.contains("shirt") { return "shirt" }
            if lower.contains("sweater") || lower.contains("knit") { return "knit top" }
            if lower.contains("blouse") { return "blouse" }
            return "top"
        case .bottom:
            if lower.contains("skirt") { return "skirt" }
            if lower.contains("jeans") { return "jeans" }
            if lower.contains("shorts") { return "shorts" }
            return "trousers"
        case .dress:
            if lower.contains("jumpsuit") { return "jumpsuit" }
            return "midi dress"
        }
    }

    /// Extracts the normalized visual color prefix (e.g. "pink color", "navy blue color")
    /// from `playgroundPrompt` when available so simplified variations keep the synced hue.
    private static func resolvedVisualColorPrefix(for garment: GarmentPlaygroundAttributes) -> String {
        if let prompt = garment.playgroundPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
           let range = prompt.range(
               of: #"^(?:[A-Za-z-]+\s+){1,2}color\b"#,
               options: [.regularExpression, .caseInsensitive]
           ) {
            return String(prompt[range]).lowercased()
        }
        return "\(garment.colorName.lowercased()) color"
    }

    private static let visualPatternWords: [String] = [
        "pattern", "patterned", "motif", "print", "printed",
        "floral", "embroidered", "embroidery", "jacquard", "brocade"
    ]

    private static let patternedTextileWords: [String] = [
        "batik", "tenun", "songket", "ikat", "endek", "ulos", "lurik", "cheongsam", "chongsam", "qipao", "chipao"
    ]

    /// Extracts a pattern cue from `garment` when present, adding `"patterned"` for cultural
    /// textiles (like batik or brocade) so Image Playground draws a motif instead of solid fabric.
    private static func patternCue(for garment: GarmentPlaygroundAttributes) -> String? {
        let combined = "\(garment.name) \(garment.fabricMaterial) \(garment.playgroundPrompt ?? "")".lowercased()
        let textile = patternedTextileWords.first { combined.contains($0) }
        let explicitPattern = visualPatternWords.first { combined.contains($0) }
        if let textile, let explicitPattern {
            return explicitPattern == "patterned" || explicitPattern == "motif" || explicitPattern == "print" || explicitPattern == "printed"
                ? "\(textile) \(explicitPattern)"
                : "\(explicitPattern) \(textile) patterned"
        }
        if let textile { return "\(textile) patterned" }
        return explicitPattern
    }

    /// Reinforces visual pattern wording with high-contrast, prominent keywords so cultural textiles
    /// (Batik, Tenun, Cheongsam, floral embroidery) render with vivid contrast rather than faint tone-on-tone.
    private static func reinforcePatternCue(in phrase: String, for garment: GarmentPlaygroundAttributes) -> String {
        let lower = "\(garment.name) \(garment.fabricMaterial) \(garment.playgroundPrompt ?? "") \(phrase)".lowercased()
        var updated = phrase

        // 1. Indonesian traditional textiles (Batik, Tenun, Songket, etc.)
        let indonesianTextiles = ["batik", "tenun", "songket", "ikat", "endek", "ulos", "lurik"]
        if let textile = indonesianTextiles.first(where: { lower.contains($0) }) {
            if !updated.localizedCaseInsensitiveContains("contrasting") && !updated.localizedCaseInsensitiveContains("prominent") {
                if updated.localizedCaseInsensitiveContains(textile) {
                    updated += " with distinct contrasting \(textile) motif pattern"
                } else {
                    updated += " featuring prominent contrasting \(textile) motif print"
                }
            }
            return updated
        }

        // 2. Chinese / Cheongsam / Imlek garments
        let isChineseOrCheongsam = lower.contains("cheongsam")
            || lower.contains("chongsam")
            || lower.contains("qipao")
            || lower.contains("chipao")
            || lower.contains("mandarin")
        if isChineseOrCheongsam {
            if !updated.localizedCaseInsensitiveContains("contrasting") && !updated.localizedCaseInsensitiveContains("prominent") && !updated.localizedCaseInsensitiveContains("gold") {
                if updated.localizedCaseInsensitiveContains("brocade") || updated.localizedCaseInsensitiveContains("jacquard") {
                    updated += " with distinct contrasting oriental floral pattern and mandarin collar"
                } else if updated.localizedCaseInsensitiveContains("embroidery") || updated.localizedCaseInsensitiveContains("embroidered") {
                    updated += " with prominent contrasting gold and floral embroidery and mandarin collar"
                } else {
                    updated += " with prominent contrasting gold floral embroidered motif and mandarin collar"
                }
            }
            return updated
        }

        // 3. General prints (floral print, brocade, embroidery)
        if (lower.contains("floral") || lower.contains("brocade") || lower.contains("embroidery") || lower.contains("embroidered"))
            && !updated.localizedCaseInsensitiveContains("contrasting") && !updated.localizedCaseInsensitiveContains("prominent") && !updated.localizedCaseInsensitiveContains("bold") {
            if updated.localizedCaseInsensitiveContains("floral print") {
                if let range = updated.range(of: "floral print", options: .caseInsensitive) {
                    updated.replaceSubrange(range, with: "distinct contrasting floral print")
                }
            } else if updated.localizedCaseInsensitiveContains("floral") {
                if let range = updated.range(of: "floral", options: .caseInsensitive) {
                    updated.replaceSubrange(range, with: "contrasting floral")
                }
            }
            return updated
        }

        guard let cue = patternCue(for: garment) else { return updated }
        if visualPatternWords.contains(where: { updated.lowercased().contains($0) }) {
            return updated
        }
        if let textile = patternedTextileWords.first(where: { updated.lowercased().contains($0) }),
           let range = updated.range(of: textile, options: .caseInsensitive) {
            return updated.replacingCharacters(in: range, with: "\(updated[range]) patterned")
        }
        return "\(cue) \(updated)"
    }

    /// Builds a clean phrase for an individual garment at the requested variation level.
    /// `0` uses the full sanitized `playgroundPrompt`; higher levels progressively simplify wording.
    private static func buildPhrase(
        for garment: GarmentPlaygroundAttributes,
        hasOuter: Bool,
        variation: Int
    ) -> String {
        switch variation {
        case 0:
            let base: String
            if let direct = garment.playgroundPrompt?.trimmingCharacters(in: .whitespacesAndNewlines), !direct.isEmpty {
                base = ensureColorWord(in: direct, colorName: garment.colorName)
            } else {
                base = "\(garment.colorName) color \(garment.name)"
            }
            let sanitized = sanitizePrompt(base, category: garment.category, hasOuter: hasOuter)
            return reinforcePatternCue(in: sanitized, for: garment)
        case 1:
            let colorPrefix = resolvedVisualColorPrefix(for: garment)
            let safeNoun = safeCategoryNoun(for: garment)
            let materialWords = sanitizePrompt(garment.fabricMaterial, category: garment.category, hasOuter: hasOuter)
                .split(separator: " ")
                .prefix(2)
                .joined(separator: " ")
            let cue = patternCue(for: garment) ?? ""
            let base = "\(colorPrefix) \(cue) \(materialWords) \(safeNoun)"
            let sanitized = sanitizePrompt(base, category: garment.category, hasOuter: hasOuter)
            return reinforcePatternCue(in: sanitized, for: garment)
        case 2:
            let colorPrefix = resolvedVisualColorPrefix(for: garment)
            let nameTail = sanitizePrompt(garment.name, category: garment.category, hasOuter: hasOuter)
                .split(separator: " ")
                .suffix(2)
                .joined(separator: " ")
            let base = "\(colorPrefix) \(nameTail.isEmpty ? safeCategoryNoun(for: garment) : nameTail)"
            return sanitizePrompt(base, category: garment.category, hasOuter: hasOuter)
        default:
            let colorPrefix = resolvedVisualColorPrefix(for: garment)
            let base = "\(colorPrefix) \(safeCategoryNoun(for: garment))"
            return sanitizePrompt(base, category: garment.category, hasOuter: hasOuter)
        }
    }

    /// Converts mapped outfit attributes into native `ImagePlaygroundConcept` tokens.
    /// Directly compatible with `.imagePlaygroundSheet(concepts:sourceImage:)`.
    @available(iOS 18.2, macOS 15.2, *)
    var playgroundConcepts: [ImagePlaygroundConcept] {
        playgroundConcepts(variationIndex: variationIndex)
    }

    /// Generates `ImagePlaygroundConcept` tokens for a given variation/simplification index.
    @available(iOS 18.2, macOS 15.2, *)
    func playgroundConcepts(variationIndex: Int) -> [ImagePlaygroundConcept] {
        let mode = ((variationIndex % 4) + 4) % 4
        let hasOuter = garments.contains { $0.category == .outer }
        let outerGarment = garments.first { $0.category == .outer }
        let topGarment = garments.first { $0.category == .top }
        let dressGarment = garments.first { $0.category == .dress }
        let bottomGarment = garments.first { $0.category == .bottom }
        let leadVerb = ["Wearing", "Styled in", "Outfit featuring", "Dressed in"][mode]
        let pairJoiner = mode % 2 == 0 ? ", " : " paired with "
        
        // When an outer layer is present, lead with the outer worn over the inner top/dress
        if let outer = outerGarment {
            let outerPhrase = Self.buildPhrase(for: outer, hasOuter: true, variation: mode)
            var segments: [String] = []
            
            if let top = topGarment {
                let topPhrase = Self.buildPhrase(for: top, hasOuter: true, variation: mode)
                segments.append("\(outerPhrase) over \(topPhrase)")
            } else if let dress = dressGarment {
                let dressPhrase = Self.buildPhrase(for: dress, hasOuter: true, variation: mode)
                segments.append("\(outerPhrase) over \(dressPhrase)")
            } else if bottomGarment != nil {
                segments.append("\(outerPhrase) over a neutral classic top")
            } else {
                segments.append(outerPhrase)
            }
            
            if let bottom = bottomGarment {
                let bottomPhrase = Self.buildPhrase(for: bottom, hasOuter: true, variation: mode)
                segments.append("with \(bottomPhrase)")
            }
            
            let combined = segments.joined(separator: ", ")
            return [.text("\(leadVerb) \(combined)")]
        }
        
        var garmentPhrases: [String] = []
        if topGarment == nil && dressGarment == nil && bottomGarment != nil {
            garmentPhrases.append("coordinated classic tailored blouse")
        }
        for garment in garments {
            let phrase = Self.buildPhrase(for: garment, hasOuter: hasOuter, variation: mode)
            if !phrase.isEmpty {
                garmentPhrases.append(phrase)
            }
        }
        
        if garmentPhrases.isEmpty {
            return [.text("Wearing a tailored stylish outfit")]
        }
        
        let outfitList = garmentPhrases.joined(separator: pairJoiner)
        var promptText = "\(leadVerb) \(outfitList)"
        if mode <= 1 {
            let lower = promptText.lowercased()
            switch upperSleeveCoverage {
            case .sleeveless:
                promptText += ", clean arms"
            case .short:
                if !lower.contains("short sleeve") && !lower.contains("short-sleeve") {
                    promptText += ", short sleeves"
                }
                promptText += ", clean arms"
            case .long:
                break
            }
        }
        return [.text(promptText)]
    }
}
#endif
