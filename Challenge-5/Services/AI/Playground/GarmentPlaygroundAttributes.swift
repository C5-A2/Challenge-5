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
        stylingDetails: String? = nil
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
    
    /// Converts mapped outfit attributes into native `ImagePlaygroundConcept` tokens.
    /// Directly compatible with `.imagePlaygroundSheet(concepts:sourceImage:)`.
    @available(iOS 18.2, macOS 15.2, *)
    var playgroundConcepts: [ImagePlaygroundConcept] {
        var concepts: [ImagePlaygroundConcept] = garments.map { garment in
            .extracted(
                from: "Wearing \(garment.category.rawValue.lowercased()): \(garment.colorName) (\(garment.colorHex)) \(garment.fabricMaterial) \(garment.name) with \(garment.fitSilhouette)",
                title: garment.category.rawValue
            )
        }
        
        // Add human body persona & studio lighting guidance
        concepts.append(.text("full-body model with \(bodyTypeName) silhouette and \(torsoBalanceName) body proportion, soft flat even studio lighting, natural original skin tone, clean neutral background with subtle floor shadow"))
        
        // Instruct Image Playground to map garments onto the person in the source image (mock_result_1)
        concepts.append(.text("Dress the person in the source image in this complete coordinated outfit, preserving the model's exact standing pose, face, skin tone, and body proportions"))
        
        return concepts
    }
}
#endif
