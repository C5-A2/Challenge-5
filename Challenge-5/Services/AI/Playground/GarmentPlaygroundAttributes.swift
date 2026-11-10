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
    
    // MARK: - Safety Seatbelt (Sanitizer for Image Playground)
    
    /// Words that trigger Apple Image Playground's sensitive content or safety filter.
    private static let blockedWords: Set<String> = [
        "sheer", "translucent", "transparent", "mesh", "see-through", "fishnet",
        "revealing", "sexy", "naked", "nude", "skin", "flesh", "cutout", "cut-out",
        "slit", "plunging", "deep-v", "low-cut", "cleavage", "waist", "swallowtail"
    ]
    
    /// Sanitizes garment text, stripping guardrail-triggering words and ensuring proper outer sleeves.
    private static func sanitizePrompt(_ text: String, category: GarmentCategory, hasOuter: Bool) -> String {
        let tokens = text.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let cleanTokens = tokens.filter { token in
            !blockedWords.contains(token.lowercased())
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
                .replacingOccurrences(of: "camisole", with: "top", options: .caseInsensitive)
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

    /// Builds a clean phrase for an individual garment.
    /// Prefers the LLM's dynamic `playgroundPrompt`; falls back to basic `colorName + color + name`.
    private static func buildPhrase(for garment: GarmentPlaygroundAttributes, hasOuter: Bool) -> String {
        if let direct = garment.playgroundPrompt?.trimmingCharacters(in: .whitespacesAndNewlines), !direct.isEmpty {
            let withColorWord = ensureColorWord(in: direct, colorName: garment.colorName)
            return sanitizePrompt(withColorWord, category: garment.category, hasOuter: hasOuter)
        }
        
        // Lightweight fallback when playgroundPrompt is nil
        let fallback = "\(garment.colorName) color \(garment.name)"
        return sanitizePrompt(fallback, category: garment.category, hasOuter: hasOuter)
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
        
        // When an outer layer is present, lead with the outer worn over the inner top/dress
        if let outer = outerGarment {
            let outerPhrase = Self.buildPhrase(for: outer, hasOuter: true)
            var segments: [String] = []
            
            if let top = topGarment {
                let topPhrase = Self.buildPhrase(for: top, hasOuter: true)
                segments.append("\(outerPhrase) over \(topPhrase)")
            } else if let dress = dressGarment {
                let dressPhrase = Self.buildPhrase(for: dress, hasOuter: true)
                segments.append("\(outerPhrase) over \(dressPhrase)")
            } else {
                segments.append(outerPhrase)
            }
            
            if let bottom = bottomGarment {
                let bottomPhrase = Self.buildPhrase(for: bottom, hasOuter: true)
                segments.append("with \(bottomPhrase)")
            }
            
            let combined = segments.joined(separator: ", ")
            return [.text("Wearing \(combined)")]
        }
        
        var garmentPhrases: [String] = []
        for garment in garments {
            let phrase = Self.buildPhrase(for: garment, hasOuter: hasOuter)
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
