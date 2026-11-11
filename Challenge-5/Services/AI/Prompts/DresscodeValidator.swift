//
//  DresscodeValidator.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 11/11/26.
//

import Foundation

// MARK: - Dresscode Compliance Result

struct DresscodeComplianceResult: Sendable {
    let isCompliant: Bool
    let violations: [String]

    init(isCompliant: Bool, violations: [String] = []) {
        self.isCompliant = isCompliant
        self.violations = violations
    }

    var violationSummary: String {
        violations.joined(separator: "; ")
    }
}

// MARK: - Dresscode Requirement Specification

struct DresscodeRequirement: Sendable {
    let rawText: String

    enum PieceRequirement: Sendable, Equatable {
        case any
        case onePiece(String)    // e.g. "dress", "gown", "jumpsuit"
        case separates(String)   // e.g. "skirt", "pants", "separates"
        case outerwear(String)   // e.g. "blazer", "suit"
    }

    let pieceRequirement: PieceRequirement
    let requiredPatterns: [String]
    let requiredColors: [String]
    let requiredCuts: [String]
    let requiredVibes: [String]

    var isEmpty: Bool {
        rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasSpecificRequirements: Bool {
        !isEmpty && (!requiredPatterns.isEmpty || pieceRequirement != .any || !requiredColors.isEmpty || !requiredCuts.isEmpty)
    }

    // MARK: - Known Keyword Dictionaries

    private static let onePieceKeywords: [String: String] = [
        "dress": "Dress", "dresses": "Dress", "gown": "Gown", "gowns": "Gown",
        "jumpsuit": "Jumpsuit", "jumpsuits": "Jumpsuit", "romper": "Romper", "rompers": "Romper",
        "playsuit": "Playsuit", "terusan": "Dress", "gaun": "Gaun",
        "gamis": "Gamis", "kaftan": "Kaftan", "swimsuit": "Swimsuit", "swimsuits": "Swimsuit",
        "monokini": "Monokini", "cheongsam": "Cheongsam", "qipao": "Qipao"
    ]

    private static let separatesKeywords: [String: String] = [
        "skirt": "Skirt", "rok": "Skirt", "pants": "Pants", "trousers": "Trousers",
        "jeans": "Jeans", "shorts": "Shorts", "culottes": "Culottes", "kulot": "Culottes",
        "celana": "Pants", "blouse": "Blouse", "shirt": "Shirt", "kemeja": "Shirt",
        "top": "Top", "atasan": "Top", "separates": "Separates", "two-piece": "Two-Piece",
        "bikini": "Bikini", "bikinis": "Bikini"
    ]

    private static let outerwearKeywords: [String: String] = [
        "blazer": "Blazer", "suit": "Suit", "pantsuit": "Suit", "jacket": "Jacket",
        "coat": "Coat", "cardigan": "Cardigan", "outer": "Outer", "jas": "Blazer"
    ]

    private static let patternKeywords: [String] = [
        "batik", "tenun", "songket", "kebaya", "lurik", "ikat", "brokat",
        "floral", "flower", "flowers", "bunga",
        "stripes", "striped", "garis", "pinstripe",
        "plaid", "checkered", "checks", "tartan", "gingham", "kotak",
        "polka dot", "polkadot", "dots",
        "houndstooth", "jacquard", "paisley",
        "leopard", "zebra", "animal print",
        "lace", "embroidery", "embroidered", "bordir",
        "sequin", "sequins", "glitter", "shimmer",
        "denim", "leather", "satin", "velvet", "linen", "tweed", "silk", "chiffon", "crochet"
    ]

    private static let cutKeywords: [String] = [
        "mini", "midi", "maxi", "floor-length", "slit",
        "sleeveless", "tank", "tube", "halter", "strapless", "spaghetti",
        "long-sleeve", "long sleeve", "lengan panjang",
        "off-shoulder", "off shoulder", "sabrina",
        "wide-leg", "wide leg", "kulot", "palazzo", "flare",
        "crop", "cropped", "wrap", "bodycon", "fitted", "pleated", "a-line", "asymmetric"
    ]

    private static let colorKeywords: [String: [String]] = [
        "red": ["red", "merah", "crimson", "scarlet", "ruby", "burgundy", "maroon", "cherry", "wine"],
        "pink": ["pink", "merah muda", "rose", "blush", "fuchsia", "magenta"],
        "blue": ["blue", "biru", "navy", "cobalt", "sky blue", "baby blue", "teal", "indigo", "turquoise", "denim blue"],
        "green": ["green", "hijau", "emerald", "olive", "sage", "mint", "forest green", "khaki"],
        "yellow": ["yellow", "kuning", "mustard", "canary", "lemon", "butter yellow", "gold", "golden"],
        "orange": ["orange", "oranye", "jingga", "terracotta", "rust", "coral", "peach"],
        "purple": ["purple", "ungu", "lavender", "lilac", "plum", "violet", "mauve"],
        "white": ["white", "putih", "ivory", "cream", "off-white", "broken white", "ecru"],
        "black": ["black", "hitam", "charcoal", "all black", "onyx"],
        "brown": ["brown", "coklat", "tan", "beige", "camel", "chocolate", "espresso"],
        "grey": ["grey", "gray", "abu-abu", "silver", "slate"],
        "pastel": ["pastel"],
        "monochrome": ["monochrome", "monokrom"]
    ]

    private static let vibeKeywords: [String] = [
        "formal", "semi-formal", "casual", "smart casual", "cocktail",
        "black tie", "traditional", "modern", "chic", "glamorous", "edgy", "boho", "minimalist", "beach", "party"
    ]

    // MARK: - Initializer & Parser

    init(dresscode: String) {
        self.rawText = dresscode
        let lower = dresscode.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let words = lower.components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
        let wordSet = Set(words)

        // 1. Piece Requirement
        if let match = words.first(where: { Self.onePieceKeywords[$0] != nil }) {
            self.pieceRequirement = .onePiece(Self.onePieceKeywords[match]!)
        } else if let match = words.first(where: { Self.outerwearKeywords[$0] != nil }) {
            self.pieceRequirement = .outerwear(Self.outerwearKeywords[match]!)
        } else if let match = words.first(where: { Self.separatesKeywords[$0] != nil }) {
            self.pieceRequirement = .separates(Self.separatesKeywords[match]!)
        } else {
            self.pieceRequirement = .any
        }

        // 2. Patterns
        var foundPatterns: [String] = []
        for pat in Self.patternKeywords {
            if pat.contains(" ") {
                if lower.contains(pat) { foundPatterns.append(pat) }
            } else {
                if wordSet.contains(pat) { foundPatterns.append(pat) }
            }
        }
        self.requiredPatterns = foundPatterns

        // 3. Cuts
        var foundCuts: [String] = []
        for cut in Self.cutKeywords {
            if cut.contains(" ") || cut.contains("-") {
                let normCut = cut.replacingOccurrences(of: "-", with: " ")
                let normLower = lower.replacingOccurrences(of: "-", with: " ")
                if normLower.contains(normCut) { foundCuts.append(cut) }
            } else {
                if wordSet.contains(cut) { foundCuts.append(cut) }
            }
        }
        self.requiredCuts = foundCuts

        // 4. Colors
        var foundColors: [String] = []
        for (canonical, synonyms) in Self.colorKeywords {
            if synonyms.contains(where: { syn in
                syn.contains(" ") ? lower.contains(syn) : wordSet.contains(syn)
            }) {
                foundColors.append(canonical)
            }
        }
        self.requiredColors = foundColors

        // 5. Vibes
        var foundVibes: [String] = []
        for vibe in Self.vibeKeywords {
            if vibe.contains(" ") {
                if lower.contains(vibe) { foundVibes.append(vibe) }
            } else {
                if wordSet.contains(vibe) { foundVibes.append(vibe) }
            }
        }
        self.requiredVibes = foundVibes
    }
}

// MARK: - Dresscode Validator

enum DresscodeValidator {

    /// Validates whether a generated look strictly complies with the dresscode across pattern, piece structure, cuts, and color.
    static func checkCompliance(
        look: OutfitLook,
        dresscode: String
    ) -> DresscodeComplianceResult {
        let cleanDresscode = dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDresscode.isEmpty else {
            return DresscodeComplianceResult(isCompliant: true)
        }

        let requirement = DresscodeRequirement(dresscode: cleanDresscode)
        guard requirement.hasSpecificRequirements else {
            return DresscodeComplianceResult(isCompliant: true)
        }

        var violations: [String] = []
        let garments = look.garments
        let categories = Set(garments.map { $0.category })

        // 1. Piece Type / Number of Pieces Check
        switch requirement.pieceRequirement {
        case .onePiece(let pieceName):
            if !categories.contains(.dress) {
                let found = garments.map { $0.category.rawValue }.joined(separator: ", ")
                violations.append("Dresscode requires a \(pieceName) (1-piece outfit), but output contains separates: [\(found)]. Outfit MUST feature a Dress.")
            }
        case .separates(let pieceName):
            if categories.contains(.dress) {
                violations.append("Dresscode requires separates (\(pieceName)), but output contains a Dress. Outfit MUST contain separate Top and Bottom.")
            }
        case .outerwear(let outerName):
            if !categories.contains(.outer) {
                violations.append("Dresscode requires outerwear (\(outerName)), but no Outer garment was provided.")
            }
        case .any:
            break
        }

        // 2. Pattern / Textile Check
        for pattern in requirement.requiredPatterns {
            let hasPattern = garments.contains { g in
                let nameMatches = g.name.localizedCaseInsensitiveContains(pattern)
                let materialMatches = g.material.localizedCaseInsensitiveContains(pattern)
                let promptMatches = g.playgroundPrompt?.localizedCaseInsensitiveContains(pattern) ?? false
                let rationaleMatches = g.rationale.localizedCaseInsensitiveContains(pattern)
                return nameMatches || materialMatches || promptMatches || rationaleMatches
            }
            if !hasPattern {
                violations.append("Missing required pattern/textile: '\(pattern)'. At least one primary garment MUST explicitly feature '\(pattern)' in its name and playgroundPrompt.")
            }
        }

        // 3. Cuts / Silhouettes Check
        for cut in requirement.requiredCuts {
            let normCut = cut.replacingOccurrences(of: "-", with: " ")
            let hasCut = garments.contains { g in
                let cleanName = g.name.replacingOccurrences(of: "-", with: " ").lowercased()
                let cleanPrompt = (g.playgroundPrompt ?? "").replacingOccurrences(of: "-", with: " ").lowercased()
                let cleanRationale = g.rationale.replacingOccurrences(of: "-", with: " ").lowercased()
                return cleanName.contains(normCut) || cleanPrompt.contains(normCut) || cleanRationale.contains(normCut)
            }
            if !hasCut {
                violations.append("Missing required cut/silhouette: '\(cut)'. The garment name or cut detail MUST incorporate '\(cut)'.")
            }
        }

        // 4. Color Check
        for color in requirement.requiredColors {
            // Check if primary garment(s) match the color
            let matchingGarments = garments.filter { g in
                isGarmentMatchingColor(g, canonicalColor: color)
            }
            if matchingGarments.isEmpty {
                let actualColors = garments.map { "\($0.category.rawValue): \($0.colorName)" }.joined(separator: ", ")
                violations.append("Dresscode mandates color '\(color)', but garments are: [\(actualColors)]. The primary garment MUST be \(color).")
            }
        }

        return DresscodeComplianceResult(isCompliant: violations.isEmpty, violations: violations)
    }

    /// Checks if an individual garment's color matches the canonical dresscode color (via name, synonyms, prompt, or hex hue).
    static func isGarmentMatchingColor(_ garment: GarmentItem, canonicalColor: String) -> Bool {
        let nameLower = garment.colorName.lowercased()
        let promptLower = (garment.playgroundPrompt ?? "").lowercased()

        // Match by synonyms
        let synonyms = DresscodeRequirement.colorSynonyms(for: canonicalColor)
        for syn in synonyms {
            if nameLower.contains(syn) || promptLower.contains(syn) {
                return true
            }
        }

        // Match by Hex Hue via PaletteColorFamily
        if let family = PaletteColorFamily(hex: garment.hexColor) {
            switch canonicalColor {
            case "red":
                return family == .red
            case "blue":
                return family == .blue
            case "green":
                return family == .green
            case "yellow":
                return family == .gold
            case "orange":
                return family == .gold || family == .red
            case "purple":
                return family == .purple
            case "black":
                return family == .neutral && isVeryDark(hex: garment.hexColor)
            case "white":
                return family == .neutral && isVeryLight(hex: garment.hexColor)
            case "brown":
                return family == .earth
            case "grey":
                return family == .neutral && !isVeryDark(hex: garment.hexColor) && !isVeryLight(hex: garment.hexColor)
            default:
                break
            }
        }

        return false
    }

    /// Applies deterministic post-processing safety net on a look to guarantee 100% compliance if retries failed.
    static func enforceCompliance(
        on look: OutfitLook,
        dresscode: String,
        colorSeason: ColorSeason?
    ) {
        let cleanDresscode = dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDresscode.isEmpty else { return }

        let req = DresscodeRequirement(dresscode: cleanDresscode)
        guard req.hasSpecificRequirements else { return }

        // 1. Enforce Pattern (e.g. "batik")
        for pattern in req.requiredPatterns {
            let alreadyHas = look.garments.contains { g in
                g.name.localizedCaseInsensitiveContains(pattern) ||
                g.material.localizedCaseInsensitiveContains(pattern) ||
                (g.playgroundPrompt?.localizedCaseInsensitiveContains(pattern) ?? false)
            }
            if !alreadyHas, let target = primaryGarment(for: look) {
                let capitalizedPattern = pattern.capitalized
                if !target.name.localizedCaseInsensitiveContains(capitalizedPattern) {
                    target.name = "\(capitalizedPattern) \(target.name)"
                }
                if !target.material.localizedCaseInsensitiveContains(capitalizedPattern) {
                    target.material = "\(capitalizedPattern) \(target.material)"
                }
                if let prompt = target.playgroundPrompt, !prompt.localizedCaseInsensitiveContains(pattern) {
                    target.playgroundPrompt = prompt.replacingOccurrences(of: "color ", with: "color \(pattern) ")
                } else if target.playgroundPrompt == nil {
                    target.playgroundPrompt = "\(target.colorName.lowercased()) color \(pattern) \(target.category.rawValue.lowercased())"
                }
                target.rationale = "Features traditional \(pattern) as strictly mandated by the dresscode."
            }
        }

        // 2. Enforce Color (e.g. "red")
        for color in req.requiredColors {
            let alreadyHas = look.garments.contains { isGarmentMatchingColor($0, canonicalColor: color) }
            if !alreadyHas, let target = primaryGarment(for: look) {
                // Find matching swatch from season if available, else default
                let swatches = colorSeason?.allSwatches ?? []
                let matchingSwatch = swatches.first { swatch in
                    if let family = PaletteColorFamily(hex: swatch.hex) {
                        return (color == "red" && family == .red) ||
                               (color == "blue" && family == .blue) ||
                               (color == "green" && family == .green) ||
                               (color == "yellow" && family == .gold) ||
                               (color == "purple" && family == .purple) ||
                               (color == "brown" && family == .earth)
                    }
                    return swatch.name.localizedCaseInsensitiveContains(color)
                }

                if let swatch = matchingSwatch {
                    target.colorName = swatch.name
                    target.hexColor = swatch.hex
                } else {
                    let fallback = defaultHexAndName(for: color)
                    target.colorName = fallback.name
                    target.hexColor = fallback.hex
                }

                // Update playgroundPrompt with new color
                if let prompt = target.playgroundPrompt {
                    let words = prompt.components(separatedBy: " ")
                    if words.count >= 2 && words[1] == "color" {
                        var updatedWords = words
                        updatedWords[0] = target.colorName.lowercased()
                        target.playgroundPrompt = updatedWords.joined(separator: " ")
                    } else {
                        target.playgroundPrompt = "\(target.colorName.lowercased()) color \(target.category.rawValue.lowercased())"
                    }
                }
            }
        }

        // 3. Enforce Piece Structure if Dress was mandated
        if case .onePiece(let pieceName) = req.pieceRequirement, !look.garments.contains(where: { $0.category == .dress }) {
            // Transform the primary separates into a Dress
            let pattern = req.requiredPatterns.first?.capitalized ?? ""
            let color = req.requiredColors.first?.capitalized ?? "Tailored"
            let patternPrefix = pattern.isEmpty ? "" : "\(pattern) "
            let dressName = "\(patternPrefix)\(color) \(pieceName)"
            let dress = GarmentItem(
                category: .dress,
                name: dressName,
                material: pattern.isEmpty ? "Silk Crepe" : "\(pattern) Cotton",
                colorName: look.garments.first?.colorName ?? "Ruby Red",
                hexColor: look.garments.first?.hexColor ?? "#C41E3A",
                rationale: "Complete \(pieceName) ensemble strictly adhering to the '\(cleanDresscode)' dresscode.",
                playgroundPrompt: "\(look.garments.first?.colorName.lowercased() ?? "red") color \(pattern.lowercased()) dress"
            )
            dress.outfitLook = look
            // Keep outer if present, replace top and bottom with dress
            var newGarments = look.garments.filter { $0.category == .outer }
            newGarments.append(dress)
            look.garments = newGarments.sortedForOutfitDisplay()
        }
    }

    private static func primaryGarment(for look: OutfitLook) -> GarmentItem? {
        if let dress = look.garments.first(where: { $0.category == .dress }) {
            return dress
        }
        if let top = look.garments.first(where: { $0.category == .top }) {
            return top
        }
        return look.garments.first
    }

    private static func isVeryDark(hex: String) -> Bool {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard clean.count == 6, let val = UInt32(clean, radix: 16) else { return false }
        let r = Double((val >> 16) & 0xFF)
        let g = Double((val >> 8) & 0xFF)
        let b = Double(val & 0xFF)
        return (r + g + b) / 3.0 < 50
    }

    private static func isVeryLight(hex: String) -> Bool {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard clean.count == 6, let val = UInt32(clean, radix: 16) else { return false }
        let r = Double((val >> 16) & 0xFF)
        let g = Double((val >> 8) & 0xFF)
        let b = Double(val & 0xFF)
        return (r + g + b) / 3.0 > 220
    }

    private static func defaultHexAndName(for canonicalColor: String) -> (name: String, hex: String) {
        switch canonicalColor {
        case "red": return ("Crimson Red", "#C41E3A")
        case "blue": return ("Royal Blue", "#1E3F66")
        case "green": return ("Emerald Green", "#1B4D3E")
        case "yellow": return ("Warm Mustard", "#D4AF37")
        case "orange": return ("Terracotta", "#C85A32")
        case "purple": return ("Deep Plum", "#4A2E4B")
        case "pink": return ("Rose Pink", "#E0838A")
        case "black": return ("Charcoal Black", "#1A1A1A")
        case "white": return ("Ivory White", "#FDFBF7")
        case "brown": return ("Chestnut Brown", "#5B3A29")
        case "grey": return ("Slate Grey", "#708090")
        default: return ("Neutral", "#333333")
        }
    }
}

extension DresscodeRequirement {
    static func colorSynonyms(for canonicalColor: String) -> [String] {
        colorKeywords[canonicalColor] ?? [canonicalColor]
    }
}
