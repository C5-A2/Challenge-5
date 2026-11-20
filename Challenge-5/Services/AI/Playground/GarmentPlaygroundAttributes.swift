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
    /// Clothing nouns that name what the piece is. A phrase without one ("satin ruffled sweetheart bodice")
    /// reads like underwear to Image Playground, which then refuses the whole image.
    static let garmentNouns: Set<String> = [
        "dress", "gown", "top", "blouse", "shirt", "tee", "t-shirt", "tank", "sweater", "cardigan", "knit", "jumper",
        "sweatshirt", "hoodie", "polo", "turtleneck", "camisole", "jumpsuit", "romper", "playsuit", "skirt", "trousers",
        "pants", "jeans", "shorts", "culottes", "leggings", "blazer", "jacket", "coat", "trench", "vest", "gilet",
        "kimono", "outer", "bomber", "parka", "kebaya", "kaftan", "abaya", "gamis", "cheongsam", "qipao", "sarong",
        "co-ord", "set", "suit", "tunic", "bustier", "overalls"
    ]

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
        // Words that make Image Playground draw letters on the fabric ("S-shaped stripes" became random text).
        "letter", "letters", "lettering", "logo", "logos", "slogan", "text", "typography", "monogram", "script", "s-shaped"
    ]

    /// Neutral garment-noun replacements for sensitive terms so the silhouette stays coherent.
    private static let tokenReplacements: [String: String] = [
        "bikini": "top",
        // Indonesian fashion words Image Playground doesn't know, swapped for what they look like.
        "kutubaru": "kebaya",
        "sabrina": "off-shoulder",
        "wiru": "pleated",
        "draperi": "draped",
        "kartini": "lapel",
        "jarik": "sarong",
        "selendang": "shawl",
        "brokat": "brocade",
        "payet": "sequin",
        "renda": "lace"
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

    /// Indonesian textiles Image Playground barely knows by name alone.
    private static let indonesianTextiles = ["batik", "tenun", "songket", "ikat", "ulos", "lurik", "endek", "sasirangan", "jumputan"]

    /// Words dropped from a textile garment's phrase before it is rebuilt: motif names Image Playground
    /// misreads ("buketan floral" became a plain flower print, "parang" means nothing to it), print words
    /// added back below, and shiny fabrics that wash a print out into a faint tone-on-tone texture.
    private static let textileNoiseWords: Set<String> = [
        "color", "colored", "colour", "motif", "motifs", "print", "printed", "pattern", "patterned",
        "parang", "kawung", "buketan", "floral", "flower", "flowers", "mega", "mendung", "lereng", "truntum",
        "sekar", "jagad", "satin", "silk", "silky", "shiny", "indonesian"
    ]

    /// Image Playground draws "apricot color batik top" as a plain apricot top: the color word wins over the print.
    /// For a batik (or other Indonesian textile) garment the phrase is rebuilt so the print leads and the
    /// garment color becomes the print's ground, with a dark or light motif that contrasts with it.
    /// What each batik motif looks like, in words Image Playground draws. The motif names alone mean nothing to
    /// it and were dropped, so every look got the same small dotted batik.
    private static let batikMotifVisuals: [(names: [String], visual: String)] = [
        (["mega mendung", "megamendung"], "layered cloud swirl motifs"),
        (["parang"], "diagonal wavy bands with small leaf shapes"),
        (["lereng"], "diagonal striped bands filled with small motifs"),
        (["kawung"], "large geometric four-petal circle medallions"),
        (["ceplok"], "large repeating geometric medallions"),
        (["sekar jagad", "sekarjagad"], "a dense patchwork of small floral motifs"),
        (["truntum"], "scattered tiny star-shaped flowers"),
        (["buketan"], "flowing floral bouquets with small birds"),
        (["sidomukti", "sido mukti", "sidoluhur", "sido luhur"], "a diamond lattice with small floral centers"),
        (["tambal"], "a patchwork of mixed geometric squares"),
        (["lasem", "floral", "flower"], "flowing floral vines")
    ]
    /// A different motif, motif scale and color story per look when the model named none, like the variety in
    /// real kebaya looks: parang stripes, cloud swirls, dense florals, large medallions, florals with birds.
    private static let lookBatikVisuals = [
        "diagonal wavy bands with small leaf shapes",
        "layered cloud swirl motifs",
        "a dense patchwork of small floral motifs",
        "large geometric four-petal circle medallions",
        "flowing floral bouquets with small birds"
    ]
    private static let lightGroundMotifColors = ["deep sogan brown and black", "indigo and soft brown", "black", "deep brown and ochre", "navy and rust"]
    private static let darkGroundMotifColors = ["cream and soft ochre", "white", "ivory and copper", "cream and soft brown", "soft white and dusty rose"]

    private static func textilePhrase(for garment: GarmentPlaygroundAttributes, short: Bool, lookIndex: Int = 0) -> String? {
        let base = "\(garment.playgroundPrompt ?? "") \(garment.name)"
        let tokens = base.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        guard let textile = indonesianTextiles.first(where: { tokens.contains($0) }) else { return nil }

        let colorWords = Set(garment.colorName.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty })
        var shape = tokens.filter { token in
            !textileNoiseWords.contains(token) && !indonesianTextiles.contains(token) && !colorWords.contains(token)
        }
        while let first = shape.first, ["and", "with", "in", "on", "of", "a"].contains(first) { shape.removeFirst() }
        while let last = shape.last, ["and", "with", "in", "on", "of", "a"].contains(last) { shape.removeLast() }
        // The prompt and the name usually repeat the cut ("peplum top ... peplum top"): keep each word once.
        var seenWords = Set<String>()
        shape = shape.filter { seenWords.insert($0).inserted }
        // Eight words keep a shaped skirt ("draped sarong wrap skirt with front pleats") whole.
        let garmentShape = short || shape.isEmpty ? safeCategoryNoun(for: garment) : shape.prefix(8).joined(separator: " ")
        // The motif the model named, described visually; otherwise one per look. Never "large cream and gold":
        // that came out as old-fashioned paisley or damask.
        let lowerBase = " " + tokens.joined(separator: " ") + " "
        let turn = ((lookIndex % 5) + 5) % 5
        let motif = batikMotifVisuals.first { entry in entry.names.contains { lowerBase.contains(" \($0) ") } }?.visual
            ?? lookBatikVisuals[turn]
        let motifColors = isLight(hex: garment.colorHex) ? lightGroundMotifColors[turn] : darkGroundMotifColors[turn]
        let origin = textile == "batik" ? "Javanese" : "Indonesian"
        let ground = garment.colorName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if short {
            return "\(garmentShape) in \(origin) \(textile) with \(motif) in \(motifColors) on a \(ground) ground"
        }
        return "\(garmentShape) in traditional \(origin) \(textile) fabric with \(motif) in \(motifColors) on a \(ground) ground"
    }

    /// Whether a hex color is light (so a dark motif contrasts with it).
    private static func isLight(hex: String) -> Bool {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard clean.count == 6, let value = UInt32(clean, radix: 16) else { return true }
        let r = Double((value >> 16) & 0xFF), g = Double((value >> 8) & 0xFF), b = Double(value & 0xFF)
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5
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
    /// Color words removed from the model's visual prompt before the real color is put back.
    private static let colorWords: Set<String> = [
        "color", "colored", "colour", "coloured", "red", "pink", "rose", "blush", "coral", "peach", "orange", "rust",
        "terracotta", "yellow", "mustard", "lemon", "butter", "gold", "golden", "green", "sage", "olive", "mint",
        "emerald", "forest", "teal", "turquoise", "aqua", "tosca", "blue", "navy", "cobalt", "sky", "periwinkle",
        "lavender", "lilac", "purple", "plum", "violet", "mauve", "burgundy", "maroon", "wine", "berry", "fuchsia",
        "magenta", "brown", "chocolate", "camel", "tan", "beige", "cream", "ivory", "white", "black", "grey", "gray",
        "charcoal", "silver", "khaki", "taupe", "nougat", "latte", "mocha", "pastel", "light", "dark", "deep",
        "dusty", "pale", "bright", "muted", "neon", "soft", "vivid", "apple", "apricot", "baby", "brick", "bubblegum",
        "burnt", "cherry", "chartreuse", "cornflower", "cyan", "denim", "electric", "hot", "indigo", "jade",
        "kelly", "lime", "marigold", "midnight", "moss", "ocean", "orchid", "petrol", "pistachio", "powder", "raspberry",
        "royal", "salmon", "sand", "seafoam", "tangerine", "watermelon", "crimson", "slate", "amber"
    ]

    /// The garment with one color, read from its hex, in its visual prompt and color name.
    /// The model sometimes writes its own color inside the prompt ("organza bow red halter top") while the
    /// parser snapped the garment to another swatch (Pastel Pink): only a leading color was replaced, so the
    /// picture came out red. Every color word is removed and the hex color leads, so the image matches the card.
    private static func withHexColor(_ garment: GarmentPlaygroundAttributes) -> GarmentPlaygroundAttributes {
        guard let color = OutfitGenerationPipeline.visualColorName(fromHex: garment.colorHex) else { return garment }
        let swatchWords = Set(garment.colorName.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty })
        var prompt = garment.playgroundPrompt
        if let current = prompt?.trimmingCharacters(in: .whitespacesAndNewlines), !current.isEmpty {
            let kept = current
                .components(separatedBy: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "-")))
                .filter { !$0.isEmpty }
                .filter { word in
                    // "off-white" or "navy-blue" is checked part by part, so it can't repeat a color.
                    let parts = word.lowercased().split(separator: "-").map(String.init)
                    return !parts.contains { colorWords.contains($0) || swatchWords.contains($0) }
                }
            prompt = "\(color) color " + kept.joined(separator: " ")
        }
        return GarmentPlaygroundAttributes(
            id: garment.id,
            category: garment.category,
            name: garment.name,
            clothingType: garment.clothingType,
            colorHex: garment.colorHex,
            colorName: color,
            fabricMaterial: garment.fabricMaterial,
            fitSilhouette: garment.fitSilhouette,
            stylingDetails: garment.stylingDetails,
            playgroundPrompt: prompt
        )
    }

    /// Shoes that fit the occasion (heels for formal events, sneakers or flats for casual ones), in black for a
    /// dark outfit and beige otherwise. Without them Image Playground copied the shoes of the profile photo.
    private var occasionShoes: String {
        let darkPieces = garments.filter { !Self.isLight(hex: $0.colorHex) }.count
        let darkOutfit = !garments.isEmpty && darkPieces * 2 > garments.count
        let shoes = OccasionStyleBank.shoes(forTitle: occasionTitle, dresscode: dresscode, lookIndex: lookIndex, darkOutfit: darkOutfit)
        // Same safety filter as the garments, so no blocked word can stop the whole image.
        return shoes
            .components(separatedBy: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "-")))
            .filter { !$0.isEmpty && !Self.blockedWords.contains($0.lowercased()) }
            .joined(separator: " ")
    }

    /// The piece's clothing noun: the last noun in its name ("mini dress", "midi skirt"), otherwise its category's.
    private static func garmentNoun(for garment: GarmentPlaygroundAttributes) -> String {
        let words = garment.name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "-")))
            .filter { !$0.isEmpty }
        if let index = words.lastIndex(where: { garmentNouns.contains($0) }) {
            // Keep a length word in front of it ("mini dress", "maxi skirt").
            if index > 0, ["mini", "midi", "maxi", "cropped", "wide-leg", "pencil", "pleated"].contains(words[index - 1]) {
                return "\(words[index - 1]) \(words[index])"
            }
            return words[index]
        }
        switch garment.category {
        case .dress: return "dress"
        case .top: return "top"
        case .bottom: return "skirt"
        case .outer: return "jacket"
        }
    }

    private static func buildPhrase(
        for originalGarment: GarmentPlaygroundAttributes,
        hasOuter: Bool,
        variation: Int,
        lookIndex: Int = 0
    ) -> String {
        let garment = withHexColor(originalGarment)
        let phrase = buildPhraseWithoutNounCheck(for: garment, hasOuter: hasOuter, variation: variation, lookIndex: lookIndex)
        let words = Set(phrase.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "-")))
            .filter { !$0.isEmpty })
        // A kebaya is drawn as a lace or brocade blouse; the word alone gave a plain top.
        if words.contains("kebaya"), words.isDisjoint(with: ["lace", "brocade", "embroidered", "beaded"]) {
            return phrase.replacingOccurrences(of: "kebaya", with: "embroidered lace kebaya", options: .caseInsensitive)
        }
        guard !phrase.isEmpty, words.isDisjoint(with: garmentNouns) else { return phrase }
        let noun = sanitizePrompt(garmentNoun(for: garment), category: garment.category, hasOuter: hasOuter)
        return "\(phrase) \(noun)"
    }

    private static func buildPhraseWithoutNounCheck(
        for garment: GarmentPlaygroundAttributes,
        hasOuter: Bool,
        variation: Int,
        lookIndex: Int = 0
    ) -> String {
        // Batik and other Indonesian textiles: the print leads the phrase in every variation,
        // otherwise the color word wins and the piece is drawn plain.
        if let phrase = textilePhrase(for: garment, short: variation >= 2, lookIndex: lookIndex) {
            return sanitizePrompt(phrase, category: garment.category, hasOuter: hasOuter)
        }
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
        // Regenerate only rewords the lead verb and joiner; every garment keeps its full phrase
        // (variation 0). The simplified variations dropped the details ("corset mini dress" -> "midi dress").
        let hasOuter = garments.contains { $0.category == .outer }
        let outerGarment = garments.first { $0.category == .outer }
        let topGarment = garments.first { $0.category == .top }
        let dressGarment = garments.first { $0.category == .dress }
        let bottomGarment = garments.first { $0.category == .bottom }
        let leadVerb = ["Wearing", "Styled in", "Outfit featuring", "Dressed in"][mode]
        let pairJoiner = mode % 2 == 0 ? ", " : " paired with "
        
        // When an outer layer is present, lead with the outer worn over the inner top/dress
        if let outer = outerGarment {
            let outerPhrase = Self.buildPhrase(for: outer, hasOuter: true, variation: 0, lookIndex: lookIndex)
            var segments: [String] = []
            
            if let top = topGarment {
                let topPhrase = Self.buildPhrase(for: top, hasOuter: true, variation: 0, lookIndex: lookIndex)
                segments.append("\(outerPhrase) over \(topPhrase)")
            } else if let dress = dressGarment {
                let dressPhrase = Self.buildPhrase(for: dress, hasOuter: true, variation: 0, lookIndex: lookIndex)
                segments.append("\(outerPhrase) over \(dressPhrase)")
            } else if bottomGarment != nil {
                segments.append("\(outerPhrase) over a neutral classic top")
            } else {
                segments.append(outerPhrase)
            }
            
            if let bottom = bottomGarment {
                let bottomPhrase = Self.buildPhrase(for: bottom, hasOuter: true, variation: 0, lookIndex: lookIndex)
                segments.append("with \(bottomPhrase)")
            }
            
            segments.append("and \(occasionShoes)")
            let combined = segments.joined(separator: ", ")
            print("🎨 [ImagePlayground] Concept (variation \(mode)): \(leadVerb) \(combined)")
            return [.text("\(leadVerb) \(combined)")]
        }
        
        var garmentPhrases: [String] = []
        if topGarment == nil && dressGarment == nil && bottomGarment != nil {
            garmentPhrases.append("coordinated classic tailored blouse")
        }
        for garment in garments {
            let phrase = Self.buildPhrase(for: garment, hasOuter: hasOuter, variation: 0, lookIndex: lookIndex)
            if !phrase.isEmpty {
                garmentPhrases.append(phrase)
            }
        }
        
        if garmentPhrases.isEmpty {
            return [.text("Wearing a tailored stylish outfit")]
        }
        
        let outfitList = garmentPhrases.joined(separator: pairJoiner)
        var promptText = "\(leadVerb) \(outfitList), and \(occasionShoes)"
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
        print("🎨 [ImagePlayground] Concept (variation \(mode)): \(promptText)")
        return [.text(promptText)]
    }
}
#endif
