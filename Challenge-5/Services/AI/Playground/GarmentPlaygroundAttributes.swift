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
        negativePrompt: String = "deformed limbs, extra arms, missing legs, distorted face, blurry fabric, low resolution, multiple people"
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
    }
}

// MARK: - Native Apple ImagePlayground Integration (iOS 18.2+)

#if canImport(ImagePlayground)
import ImagePlayground

extension OutfitPlaygroundPackage {
    
    // MARK: - 1. Safe Color Name Resolution
    
    /// Standard, unambiguous fashion color words that Apple Image Playground understands safely.
    private static let safeFashionColors: [String] = [
        "ivory", "cream", "beige", "camel", "tan", "khaki", "taupe", "brown",
        "charcoal", "black", "white", "gray", "grey", "silver", "gold",
        "yellow", "mustard", "amber", "orange", "coral", "peach", "terracotta", "rust",
        "pink", "rose", "blush", "fuchsia", "magenta", "red", "crimson", "burgundy", "maroon",
        "plum", "purple", "violet", "lavender", "lilac", "mauve",
        "navy", "cobalt", "slate", "blue", "teal", "turquoise", "aqua", "cyan",
        "emerald", "jade", "olive", "sage", "mint", "forest", "green"
    ]
    
    /// Words in Pantone swatch names that can confuse Image Playground or trigger safety guardrails.
    private static let unsafeColorDescriptors: Set<String> = [
        "swan", "smoke", "elephant", "skin", "sunburn", "innuendo", "poison", "daiquiri",
        "curacao", "rum", "raisin", "wine", "merlot", "zinfandel", "bungee", "cord",
        "pirate", "military", "trooper", "turbulence", "storm", "thunderstorm", "silent",
        "forged", "iron", "shoe", "tap", "slipper", "ballet", "toadstool", "beetle",
        "dachshund", "impala", "wolf", "arctic", "dove", "turtledove", "mourning", "fruit",
        "pelican", "heron", "wren", "raven", "cabbage", "tofu", "corn", "asparagus",
        "rutabaga", "shortbread", "chocolate", "coffee", "lemonade", "sugar", "bonbon",
        "bubblegum", "beach", "ball", "tee", "first", "latte", "lattè", "chimera",
        "brindle", "buckskin", "surf", "web", "bossy", "naked", "nude", "flesh", "blood",
        "ghost", "bone", "skeleton", "dead", "flame", "fire", "gun", "gunmetal", "bullet"
    ]
    
    /// Converts Pantone / metaphorical color names and hex codes into clean, natural clothing color names.
    private static func safePlaygroundColorName(colorName: String, hex: String) -> String {
        let lowerName = colorName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let hslColor = colorNameFromHex(hex)
        
        if lowerName.isEmpty || lowerName == "neutral" || lowerName == "tailored hue" {
            return hslColor
        }
        
        let words = lowerName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        let hasUnsafeWord = words.contains { unsafeColorDescriptors.contains($0) }
        
        // Extract any recognized standard fashion color words present in the name
        let matchedSafeColors = safeFashionColors.filter { safeWord in
            words.contains(safeWord)
        }
        
        if let primarySafeColor = matchedSafeColors.first {
            // If the original name contained a metaphorical/unsafe word (e.g. "White Swan", "Smoke Gray"),
            // pair a clean tone modifier or return the HSL-refined color if more descriptive.
            if hasUnsafeWord {
                if primarySafeColor == "white" {
                    return "warm ivory"
                } else if primarySafeColor == "gray" || primarySafeColor == "grey" {
                    return "soft gray"
                }
                return primarySafeColor
            }
            
            // Allow safe light/dark/warm/soft/deep prefixes when the rest of the name is clean
            let safePrefixes: Set<String> = ["light", "dark", "deep", "soft", "warm", "cool", "pale", "pastel", "bright", "dusty", "muted", "rich"]
            if let prefix = words.first, safePrefixes.contains(prefix), prefix != primarySafeColor {
                return "\(prefix) \(primarySafeColor)"
            }
            return primarySafeColor
        }
        
        // Fallback to deterministic HSL color name derived from the swatch hex
        return hslColor
    }
    
    /// Derives a clean, natural clothing color name directly from a hex string (`#RRGGBB`).
    private static func colorNameFromHex(_ hex: String) -> String {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if clean.hasPrefix("#") { clean.removeFirst() }
        guard clean.count == 6, let rgb = UInt32(clean, radix: 16) else {
            return "neutral beige"
        }
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        let l = (maxC + minC) / 2.0
        
        let s: Double
        if delta == 0 {
            s = 0
        } else {
            s = delta / (1.0 - abs(2.0 * l - 1.0))
        }
        
        var h: Double = 0
        if delta > 0 {
            if maxC == r {
                h = 60.0 * (((g - b) / delta).truncatingRemainder(dividingBy: 6.0))
            } else if maxC == g {
                h = 60.0 * (((b - r) / delta) + 2.0)
            } else {
                h = 60.0 * (((r - g) / delta) + 4.0)
            }
            if h < 0 { h += 360.0 }
        }
        
        // Low saturation -> Achromatic / Neutral tones
        if s < 0.12 {
            if l >= 0.88 { return "ivory white" }
            if l >= 0.75 { return "light gray" }
            if l >= 0.55 { return "soft gray" }
            if l >= 0.35 { return "slate gray" }
            if l >= 0.18 { return "charcoal gray" }
            return "black"
        }
        
        // Warm low-to-medium saturation -> Cream / Beige / Taupe / Brown
        if (h >= 18 && h <= 58) && s < 0.38 {
            if l >= 0.80 { return "warm cream" }
            if l >= 0.65 { return "beige" }
            if l >= 0.45 { return "taupe" }
            if l >= 0.25 { return "warm brown" }
            return "dark brown"
        }
        
        // Chromatic hues
        switch h {
        case 345...360, 0..<12:
            if l >= 0.75 { return "blush pink" }
            if l >= 0.45 { return s < 0.45 ? "dusty rose" : "crimson red" }
            return "burgundy"
        case 12..<28:
            if l >= 0.72 { return "soft peach" }
            if l >= 0.45 { return s < 0.50 ? "terracotta" : "coral" }
            return "rust brown"
        case 28..<45:
            if l >= 0.76 { return "warm ivory" }
            if l >= 0.48 { return s < 0.55 ? "camel" : "amber" }
            return "warm brown"
        case 45..<68:
            if l >= 0.76 { return "pastel yellow" }
            if l >= 0.46 { return "mustard yellow" }
            return "olive brown"
        case 68..<155:
            if l >= 0.72 { return "mint green" }
            if l >= 0.42 { return s < 0.35 ? "sage green" : "emerald green" }
            return h < 105 ? "olive green" : "forest green"
        case 155..<195:
            if l >= 0.70 { return "soft aqua" }
            if l >= 0.40 { return "teal" }
            return "deep teal"
        case 195..<250:
            if l >= 0.70 { return "sky blue" }
            if l >= 0.40 { return s < 0.38 ? "slate blue" : "cobalt blue" }
            return "navy blue"
        case 250..<295:
            if l >= 0.70 { return "soft lavender" }
            if l >= 0.40 { return "violet" }
            return "deep plum"
        default: // 295..<345
            if l >= 0.72 { return "soft pink" }
            if l >= 0.45 { return s < 0.45 ? "mauve" : "rose pink" }
            return "berry plum"
        }
    }
    
    // MARK: - 2. Safe Fabric Material Resolution
    
    /// Core single-word fabric nouns that are 100% safe for Image Playground (excludes "sheer", "mesh", "lace", "transparent", etc.).
    private static let safeFabricKeywords: [String] = [
        "linen", "cotton", "silk", "satin", "chiffon", "crepe", "denim",
        "wool", "knit", "twill", "velvet", "chambray", "poplin", "corduroy",
        "tweed", "cashmere", "rayon", "viscose", "jersey", "gabardine"
    ]
    
    /// Extracts a single clean fabric word, stripping modifiers like "Light sheer", "See-through", or "Transparent".
    private static func safePlaygroundMaterial(from rawMaterial: String) -> String {
        let lower = rawMaterial.lowercased()
        let words = lower
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        for fabric in safeFabricKeywords {
            if words.contains(fabric) {
                return fabric
            }
        }
        return ""
    }
    
    // MARK: - 3. Safe Garment Description & Outer Sleeve Normalization
    
    /// Builds a guardrail-safe, anatomically clean garment phrase with a guaranteed clothing noun.
    /// Fixes outer sleeve distortion by enforcing full-length long sleeves on outerwear and removing conflicting sleeve terms on inner tops.
    private static func safePlaygroundGarmentDescription(
        for garment: GarmentPlaygroundAttributes,
        hasOuter: Bool
    ) -> String {
        let rawLower = garment.name.lowercased()
        let tokens = rawLower
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let tokenSet = Set(tokens)
        
        switch garment.category {
        case .outer:
            // Determine clean outerwear noun (avoiding "trench", "cape", "kimono", "cropped", "belted" which distort sleeves)
            let outerNoun: String
            var isSleevelessVest = false
            if tokenSet.contains("vest") || tokenSet.contains("gilet") || tokenSet.contains("waistcoat") {
                outerNoun = "tailored vest"
                isSleevelessVest = true
            } else if tokenSet.contains("cardigan") {
                outerNoun = "cardigan"
            } else if tokenSet.contains("blazer") || tokenSet.contains("suit") {
                outerNoun = "blazer"
            } else if tokenSet.contains("coat") || tokenSet.contains("trench") || tokenSet.contains("overcoat") || tokenSet.contains("duster") || tokenSet.contains("parka") {
                outerNoun = "tailored coat"
            } else if tokenSet.contains("overshirt") || tokenSet.contains("shacket") {
                outerNoun = "overshirt"
            } else {
                outerNoun = "tailored jacket"
            }
            
            var styleModifiers: [String] = []
            if tokenSet.contains("structured") && !outerNoun.contains("structured") {
                styleModifiers.append("structured")
            } else if tokenSet.contains("tailored") && !outerNoun.contains("tailored") {
                styleModifiers.append("tailored")
            }
            if !isSleevelessVest {
                // Explicitly enforce full-length long sleeves so Image Playground never renders half-sleeves or elbow buckles
                styleModifiers.append("long-sleeve")
            }
            styleModifiers.append(outerNoun)
            return styleModifiers.joined(separator: " ")
            
        case .top:
            // Determine clean top noun
            let topNoun: String
            if tokenSet.contains("polo") {
                topNoun = "polo shirt"
            } else if tokenSet.contains("tee") || (tokenSet.contains("t") && tokenSet.contains("shirt")) || rawLower.contains("t-shirt") {
                topNoun = "t-shirt"
            } else if tokenSet.contains("henley") {
                topNoun = "henley shirt"
            } else if tokenSet.contains("turtleneck") {
                topNoun = "turtleneck top"
            } else if tokenSet.contains("sweater") || tokenSet.contains("pullover") || tokenSet.contains("jumper") {
                topNoun = "knit sweater"
            } else if tokenSet.contains("tunic") {
                topNoun = "tunic blouse"
            } else if tokenSet.contains("kebaya") {
                topNoun = "kebaya blouse"
            } else if tokenSet.contains("shirt") || tokenSet.contains("oxford") || rawLower.contains("button-down") || rawLower.contains("button-up") {
                topNoun = "collared shirt"
            } else if tokenSet.contains("blouse") || tokenSet.contains("peplum") || tokenSet.contains("camisole") || tokenSet.contains("cami") || tokenSet.contains("tank") || tokenSet.contains("halter") {
                topNoun = hasOuter ? "inner blouse" : "blouse"
            } else {
                topNoun = hasOuter ? "inner top" : "tailored top"
            }
            
            // When worn under an outer layer, omit all sleeve/shoulder descriptors on the inner top
            // so Image Playground does not blend bare/short arms with the outer's long sleeves.
            if hasOuter {
                return topNoun
            }
            
            var modifiers: [String] = []
            if rawLower.contains("long-sleeve") || rawLower.contains("long sleeve") {
                modifiers.append("long-sleeve")
            } else if rawLower.contains("short-sleeve") || rawLower.contains("short sleeve") {
                modifiers.append("short-sleeve")
            }
            if rawLower.contains("v-neck") || rawLower.contains("v neck") {
                modifiers.append("v-neck")
            } else if rawLower.contains("boat-neck") || rawLower.contains("boat neck") || tokenSet.contains("bateau") {
                modifiers.append("boat-neck")
            } else if rawLower.contains("crew-neck") || rawLower.contains("crew neck") {
                modifiers.append("crew-neck")
            }
            if tokenSet.contains("pleated") {
                modifiers.append("pleated")
            } else if tokenSet.contains("ruffled") || tokenSet.contains("ruffle") || tokenSet.contains("ruffles") {
                modifiers.append("ruffled")
            } else if tokenSet.contains("draped") {
                modifiers.append("draped")
            } else if tokenSet.contains("wrap") {
                modifiers.append("wrap")
            }
            modifiers.append(topNoun)
            return modifiers.joined(separator: " ")
            
        case .bottom:
            // Detect whether this bottom is a skirt, culottes, jeans, shorts, or trousers
            let isSkirt = tokenSet.contains("skirt")
                || rawLower.contains("a-line")
                || tokenSet.contains("pencil")
                || tokenSet.contains("midi")
                || tokenSet.contains("maxi")
                || tokenSet.contains("tiered")
                || tokenSet.contains("ruffle")
                || tokenSet.contains("ruffles")
                || tokenSet.contains("ruffled")
                || tokenSet.contains("flared")
                || tokenSet.contains("lilit")
                || tokenSet.contains("sarong")
            
            if isSkirt {
                var modifiers: [String] = []
                if rawLower.contains("a-line") || rawLower.contains("a line") {
                    modifiers.append("A-line")
                } else if tokenSet.contains("pleated") || tokenSet.contains("pleat") {
                    modifiers.append("pleated")
                } else if tokenSet.contains("wrap") {
                    modifiers.append("wrap")
                } else if tokenSet.contains("tiered") {
                    modifiers.append("tiered")
                } else if tokenSet.contains("flared") {
                    modifiers.append("flared")
                } else if tokenSet.contains("straight") || tokenSet.contains("pencil") {
                    modifiers.append("straight")
                }
                if tokenSet.contains("ruffle") || tokenSet.contains("ruffles") || tokenSet.contains("ruffled") {
                    modifiers.append("ruffled")
                }
                if tokenSet.contains("maxi") {
                    modifiers.append("maxi")
                } else if tokenSet.contains("midi") {
                    modifiers.append("midi")
                }
                modifiers.append("skirt")
                return modifiers.joined(separator: " ")
            }
            
            if tokenSet.contains("culottes") || tokenSet.contains("culotte") {
                return "wide-leg culottes"
            }
            if tokenSet.contains("jeans") || tokenSet.contains("denim") {
                if rawLower.contains("wide-leg") || rawLower.contains("wide leg") {
                    return "wide-leg jeans"
                }
                return "straight-leg jeans"
            }
            if tokenSet.contains("shorts") || tokenSet.contains("bermuda") {
                return "tailored shorts"
            }
            if tokenSet.contains("chinos") || tokenSet.contains("chino") || tokenSet.contains("khaki") {
                return "tailored chino pants"
            }
            
            var trouserModifiers: [String] = []
            if rawLower.contains("wide-leg") || rawLower.contains("wide leg") || tokenSet.contains("palazzo") {
                trouserModifiers.append("wide-leg")
            } else if rawLower.contains("straight-leg") || rawLower.contains("straight leg") || tokenSet.contains("straight") {
                trouserModifiers.append("straight-leg")
            } else if tokenSet.contains("tapered") {
                trouserModifiers.append("tapered")
            } else {
                trouserModifiers.append("tailored")
            }
            if tokenSet.contains("pleated") || tokenSet.contains("pleat") {
                trouserModifiers.append("pleated")
            }
            trouserModifiers.append("trousers")
            return trouserModifiers.joined(separator: " ")
            
        case .dress:
            if tokenSet.contains("jumpsuit") {
                if rawLower.contains("wide-leg") || rawLower.contains("wide leg") {
                    return "wide-leg jumpsuit"
                }
                return "tailored jumpsuit"
            }
            
            var modifiers: [String] = []
            if !hasOuter {
                if rawLower.contains("long-sleeve") || rawLower.contains("long sleeve") {
                    modifiers.append("long-sleeve")
                } else if rawLower.contains("short-sleeve") || rawLower.contains("short sleeve") {
                    modifiers.append("short-sleeve")
                }
            }
            if rawLower.contains("a-line") || rawLower.contains("a line") {
                modifiers.append("A-line")
            } else if tokenSet.contains("wrap") {
                modifiers.append("wrap")
            } else if tokenSet.contains("pleated") || tokenSet.contains("pleat") {
                modifiers.append("pleated")
            } else if tokenSet.contains("tiered") {
                modifiers.append("tiered")
            } else if tokenSet.contains("shirt") || tokenSet.contains("shirtdress") {
                modifiers.append("shirt")
            } else if tokenSet.contains("flared") || tokenSet.contains("fit-and-flare") {
                modifiers.append("flared")
            }
            if tokenSet.contains("ruffle") || tokenSet.contains("ruffles") || tokenSet.contains("ruffled") {
                modifiers.append("ruffled")
            }
            if tokenSet.contains("maxi") || tokenSet.contains("gown") {
                modifiers.append("maxi")
            } else if tokenSet.contains("midi") {
                modifiers.append("midi")
            }
            modifiers.append("dress")
            return modifiers.joined(separator: " ")
        }
    }
    
    /// Sanitizes an LLM-provided direct `playgroundPrompt`, acting as a minimal safety seatbelt:
    /// strips guardrail-triggering words (e.g. sheer, naked, waist) and enforces full-length outer sleeves.
    private static func sanitizeDirectPlaygroundPrompt(
        _ prompt: String,
        category: GarmentCategory,
        hasOuter: Bool
    ) -> String {
        let rawLower = prompt.lowercased()
        let words = rawLower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        
        let filteredWords = words.filter { word in
            !unsafeColorDescriptors.contains(word) &&
            word != "sheer" && word != "translucent" && word != "transparent" && word != "mesh" &&
            word != "waist" && word != "cutout" && word != "slit" && word != "sexy" && word != "naked"
        }
        var cleaned = filteredWords.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            cleaned = prompt
        }
        
        if category == .outer {
            // Strip sleeve-shortening words and ensure long sleeves
            cleaned = cleaned
                .replacingOccurrences(of: "short-sleeve", with: "")
                .replacingOccurrences(of: "short sleeve", with: "")
                .replacingOccurrences(of: "sleeveless", with: "")
                .replacingOccurrences(of: "cropped", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.localizedCaseInsensitiveContains("long-sleeve") && !cleaned.localizedCaseInsensitiveContains("long sleeve") && !cleaned.localizedCaseInsensitiveContains("vest") {
                cleaned = "long-sleeve \(cleaned)"
            }
        } else if hasOuter && (category == .top || category == .dress) {
            // Under an outer layer, remove conflicting sleeve descriptors
            cleaned = cleaned
                .replacingOccurrences(of: "sleeveless", with: "")
                .replacingOccurrences(of: "spaghetti-strap", with: "")
                .replacingOccurrences(of: "camisole", with: "top")
                .replacingOccurrences(of: "tank top", with: "top")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
    
    private static func buildSafePhrase(for garment: GarmentPlaygroundAttributes, hasOuter: Bool) -> String {
        // 1. If LLM directly provided a playgroundPrompt, use it with minimal safety seatbelt!
        if let direct = garment.playgroundPrompt?.trimmingCharacters(in: .whitespacesAndNewlines), !direct.isEmpty {
            return sanitizeDirectPlaygroundPrompt(direct, category: garment.category, hasOuter: hasOuter)
        }
        
        // 2. Fallback to automated attribute assembly
        let color = safePlaygroundColorName(colorName: garment.colorName, hex: garment.colorHex)
        let material = safePlaygroundMaterial(from: garment.fabricMaterial)
        let description = safePlaygroundGarmentDescription(for: garment, hasOuter: hasOuter)
        
        var parts: [String] = []
        if !color.isEmpty {
            parts.append(color)
        }
        if !material.isEmpty && !description.localizedCaseInsensitiveContains(material) {
            parts.append(material)
        }
        parts.append(description)
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Converts mapped outfit attributes into native `ImagePlaygroundConcept` tokens.
    /// Directly compatible with `.imagePlaygroundSheet(concepts:sourceImage:)`.
    @available(iOS 18.2, macOS 15.2, *)
    var playgroundConcepts: [ImagePlaygroundConcept] {
        let hasOuter = garments.contains { $0.category == .outer }
        
        let outerGarment = garments.first { $0.category == .outer }
        let topGarment = garments.first { $0.category == .top }
        let dressGarment = garments.first { $0.category == .dress }
        let bottomGarment = garments.first { $0.category == .bottom }
        
        // When an outer layer is present, lead with the long-sleeve outer worn over the inner top/dress
        // so Image Playground renders full-length outer sleeves cleanly without inner-sleeve conflicts.
        if let outer = outerGarment {
            let outerPhrase = Self.buildSafePhrase(for: outer, hasOuter: true)
            var segments: [String] = []
            
            if let top = topGarment {
                let topPhrase = Self.buildSafePhrase(for: top, hasOuter: true)
                segments.append("\(outerPhrase) over \(topPhrase)")
            } else if let dress = dressGarment {
                let dressPhrase = Self.buildSafePhrase(for: dress, hasOuter: true)
                segments.append("\(outerPhrase) over \(dressPhrase)")
            } else {
                segments.append(outerPhrase)
            }
            
            if let bottom = bottomGarment {
                let bottomPhrase = Self.buildSafePhrase(for: bottom, hasOuter: true)
                segments.append("with \(bottomPhrase)")
            }
            
            let combined = segments.joined(separator: ", ")
            return [.text("Wearing \(combined)")]
        }
        
        var garmentPhrases: [String] = []
        for garment in garments {
            let phrase = Self.buildSafePhrase(for: garment, hasOuter: hasOuter)
            if !phrase.isEmpty {
                garmentPhrases.append(phrase)
            }
        }
        
        if garmentPhrases.isEmpty {
            return [.text("Wearing a tailored stylish outfit")]
        }
        
        let outfitList = garmentPhrases.joined(separator: ", ")
        return [.text("Wearing \(outfitList)")]
    }
}
#endif
