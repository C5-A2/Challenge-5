//
//  OutfitAttributeMapper.swift
//  Challenge-5
//
//  Created by Michael David Sin on 28/10/26.
//

import Foundation
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// Pipeline service responsible for extracting, parsing, and mapping structured outfit attributes
/// from SwiftData models or raw LLM JSON outputs into an Image Playground visual package (C5-46).
enum OutfitAttributeMapper {
    
    // MARK: - 1. Extract from SwiftData / ViewModel Domain Models
    
    /// Maps a stored or active `OutfitLook` and its occasion/profile context into an `OutfitPlaygroundPackage`.
    static func mapOutfitLookToPlayground(
        look: OutfitLook,
        occasion: OccasionItem? = nil,
        userProfile: UserProfile? = nil
    ) -> OutfitPlaygroundPackage {
        let occasionTitle = occasion?.title ?? look.occasion?.title ?? "Occasion Outfit"
        let dresscode = occasion?.dresscode.isEmpty == false ? occasion!.dresscode : (look.occasion?.dresscode ?? "Smart Casual")
        
        let bodyTypeName = userProfile?.bodyType?.rawValue ?? "Inverted Triangle"
        let torsoBalanceName = userProfile?.torsoBalance?.rawValue ?? "Balanced"
        let colorSeasonName = userProfile?.colorSeason?.rawValue ?? "Deep Winter"
        
        // 1. Map garments
        let mappedGarments: [GarmentPlaygroundAttributes] = look.garments.map { garment in
            let cleanHex = normalizeHexColor(garment.hexColor)
            return GarmentPlaygroundAttributes(
                category: garment.category,
                name: garment.name,
                clothingType: "\(garment.category.rawValue) \(garment.name)",
                colorHex: cleanHex,
                colorName: garment.colorName.isEmpty ? "Neutral" : garment.colorName,
                fabricMaterial: garment.material.isEmpty ? "Premium Cotton Blend" : garment.material,
                fitSilhouette: extractSilhouetteFromRationale(look.fitRationale, category: garment.category),
                playgroundPrompt: garment.playgroundPrompt
            )
        }
        
        // 2. Synthesize composite visual prompt
        let prompt = buildCompositePrompt(
            occasionTitle: occasionTitle,
            dresscode: dresscode,
            bodyTypeName: bodyTypeName,
            torsoBalanceName: torsoBalanceName,
            colorSeasonName: colorSeasonName,
            garments: mappedGarments
        )
        
        return OutfitPlaygroundPackage(
            id: look.id,
            lookIndex: look.lookIndex,
            occasionTitle: occasionTitle,
            dresscode: dresscode,
            bodyTypeName: bodyTypeName,
            torsoBalanceName: torsoBalanceName,
            colorSeasonName: colorSeasonName,
            garments: mappedGarments,
            compositeVisualPrompt: prompt
        )
    }
    
    // MARK: - 2. Parse from Raw LLM / LLaMA JSON Output
    
    /// DTO structure for parsing raw JSON emitted by on-device LLaMA or cloud LLM.
    private struct RawLLMGarmentDTO: Decodable {
        let category: String?
        let name: String?
        let cutDetail: String?
        let fabricMaterial: String?
        let colorName: String?
        let colorHex: String?
        let playgroundPrompt: String?
    }
    
    private struct RawLLMLookDTO: Decodable {
        let title: String?
        let top: RawLLMGarmentDTO?
        let outer: RawLLMGarmentDTO?
        let bottom: RawLLMGarmentDTO?
    }
    
    /// Parses raw LLM JSON text into an `OutfitPlaygroundPackage`.
    static func parsePlaygroundPackageFromLLM(
        jsonString: String,
        lookIndex: Int = 0,
        occasionTitle: String = "Curated Look",
        dresscode: String = "Smart Casual",
        userProfile: UserProfile? = nil
    ) throws -> OutfitPlaygroundPackage {
        let cleaned = cleanJsonString(jsonString)
        guard let data = cleaned.data(using: .utf8) else {
            throw AttributeMapperError.invalidJsonData
        }
        
        let dto = try JSONDecoder().decode(RawLLMLookDTO.self, from: data)
        var attributes: [GarmentPlaygroundAttributes] = []
        
        if let top = dto.top {
            attributes.append(mapRawDTO(top, defaultCategory: .top, fallbackName: "Tailored Top"))
        }
        if let outer = dto.outer {
            attributes.append(mapRawDTO(outer, defaultCategory: .outer, fallbackName: "Structured Blazer"))
        }
        if let bottom = dto.bottom {
            attributes.append(mapRawDTO(bottom, defaultCategory: .bottom, fallbackName: "Tailored Trousers"))
        }
        
        let bodyTypeName = userProfile?.bodyType?.rawValue ?? "Inverted Triangle"
        let torsoBalanceName = userProfile?.torsoBalance?.rawValue ?? "Balanced"
        let colorSeasonName = userProfile?.colorSeason?.rawValue ?? "Deep Winter"
        
        let prompt = buildCompositePrompt(
            occasionTitle: dto.title ?? occasionTitle,
            dresscode: dresscode,
            bodyTypeName: bodyTypeName,
            torsoBalanceName: torsoBalanceName,
            colorSeasonName: colorSeasonName,
            garments: attributes
        )
        
        return OutfitPlaygroundPackage(
            lookIndex: lookIndex,
            occasionTitle: dto.title ?? occasionTitle,
            dresscode: dresscode,
            bodyTypeName: bodyTypeName,
            torsoBalanceName: torsoBalanceName,
            colorSeasonName: colorSeasonName,
            garments: attributes,
            compositeVisualPrompt: prompt
        )
    }
    
    // MARK: - 3. Prompt Engineering for Full-Body Standing Model Visuals
    
    /// Synthesizes high-fidelity prompt for Image Playground matching the standing model avatar lookbook.
    static func buildCompositePrompt(
        occasionTitle: String,
        dresscode: String,
        bodyTypeName: String,
        torsoBalanceName: String,
        colorSeasonName: String,
        garments: [GarmentPlaygroundAttributes]
    ) -> String {
        var garmentDescriptions: [String] = []
        
        for garment in garments {
            let desc = "\(garment.colorName) color (\(garment.colorHex)) \(garment.fabricMaterial) \(garment.name) with \(garment.fitSilhouette)"
            garmentDescriptions.append(desc)
        }
        
        let outfitsJoined = garmentDescriptions.joined(separator: ", paired with ")
        
        return """
        A full-body studio photograph of an elegant model with a \(bodyTypeName) silhouette and \(torsoBalanceName) body proportion, standing confidently upright in a front-facing studio lookbook pose. The model is wearing a complete coordinated \(dresscode) outfit for \(occasionTitle): \(outfitsJoined). Harmonized for a \(colorSeasonName) color season. Clean off-white studio background with soft floor contact shadow, professional high-fashion editorial lookbook lighting, 8k resolution, crisp textile weave texture, hyper-realistic.
        """.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Private Helpers
    
    private static func mapRawDTO(
        _ dto: RawLLMGarmentDTO,
        defaultCategory: GarmentCategory,
        fallbackName: String
    ) -> GarmentPlaygroundAttributes {
        let category: GarmentCategory
        if let catString = dto.category, let parsed = GarmentCategory(rawValue: catString) {
            category = parsed
        } else {
            category = defaultCategory
        }
        
        let hex = normalizeHexColor(dto.colorHex ?? "#1A1A1A")
        
        return GarmentPlaygroundAttributes(
            category: category,
            name: dto.name ?? fallbackName,
            clothingType: "\(dto.name ?? fallbackName)",
            colorHex: hex,
            colorName: dto.colorName ?? "Tailored Hue",
            fabricMaterial: dto.fabricMaterial ?? "Premium Fabric",
            fitSilhouette: dto.cutDetail ?? "Refined tailored fit",
            playgroundPrompt: dto.playgroundPrompt
        )
    }
    
    private static func normalizeHexColor(_ hex: String) -> String {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.hasPrefix("#") {
            clean = "#" + clean
        }
        if clean.count == 7 {
            return clean.uppercased()
        }
        return "#1A1A1A"
    }
    
    private static func extractSilhouetteFromRationale(_ rationale: String, category: GarmentCategory) -> String {
        if rationale.localizedCaseInsensitiveContains("slim") {
            return "Slim-fit structured cut"
        } else if rationale.localizedCaseInsensitiveContains("straight") {
            return "Clean straight-leg silhouette"
        } else if rationale.localizedCaseInsensitiveContains("relaxed") {
            return "Relaxed tailored drape"
        }
        switch category {
        case .top: return "Refined collar tailored cut"
        case .outer: return "Structured shoulder taper"
        case .bottom: return "Straight-leg balance cut"
        case .dress: return "Defined-waist one-piece silhouette"
        }
    }
    
    private static func cleanJsonString(_ input: String) -> String {
        var cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start...end])
        }
        return cleaned
    }
    
    // MARK: - Playground Source Photo

    /// The last prepared photo, so it isn't recomputed on every view update.
    private static var sourceImageCache: (key: Int, image: UIImage)?

    /// Drops the cached full-resolution source photo to reclaim memory.
    static func clearSourceImageCache() {
        sourceImageCache = nil
    }
    /// Where the clothes start below the face, in face heights below the chin.
    private static let neckOffsetFaceRatio: CGFloat = 0.25
    /// The flat gray painted over her clothes.
    private static let plainClothesGray: CGFloat = 0.78

    /// The user's full-body photo for Image Playground, with her clothes painted plain gray.
    ///
    /// With the original photo, Image Playground copies the outfit she wore in it (the same dress,
    /// bag and sneakers in every look). A head-only crop avoided that but made the result half-body.
    /// This keeps the full-body framing, pose and body shape, and only removes what she was wearing.
    /// Falls back to the original photo when no face or person is found.
    static func playgroundSourceImage(fromPhotoData data: Data) -> UIImage? {
        let key = data.count ^ data.prefix(256).hashValue
        if let cached = sourceImageCache, cached.key == key { return cached.image }
        guard let photo = UIImage(data: data) else { return nil }
        let image = photoWithPlainClothes(photo) ?? photo
        sourceImageCache = (key, image)
        return image
    }

    private static func photoWithPlainClothes(_ photo: UIImage) -> UIImage? {
        // Redraw first so the pixels are upright, whatever the photo's EXIF orientation.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let upright = UIGraphicsImageRenderer(size: photo.size, format: format).image { _ in
            photo.draw(in: CGRect(origin: .zero, size: photo.size))
        }
        guard let cgImage = upright.cgImage else { return nil }

        let faceRequest = VNDetectFaceRectanglesRequest()
        let personRequest = VNGeneratePersonSegmentationRequest()
        personRequest.qualityLevel = .balanced
        personRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([faceRequest, personRequest])
        } catch {
            return nil
        }
        guard let face = faceRequest.results?.max(by: { $0.boundingBox.width < $1.boundingBox.width }),
              let maskBuffer = personRequest.results?.first?.pixelBuffer else { return nil }

        let original = CIImage(cgImage: cgImage)
        let extent = original.extent
        let rawMask = CIImage(cvPixelBuffer: maskBuffer)
        let personMask = rawMask.transformed(by: CGAffineTransform(
            scaleX: extent.width / rawMask.extent.width,
            y: extent.height / rawMask.extent.height
        ))

        // Only the body below the chin. Vision and Core Image both put the origin at the bottom left.
        let neckY = max(0, (face.boundingBox.minY - face.boundingBox.height * neckOffsetFaceRatio) * extent.height)
        let bodyArea = CIImage(color: .white)
            .cropped(to: CGRect(x: 0, y: 0, width: extent.width, height: neckY))
            .composited(over: CIImage(color: .black).cropped(to: extent))
        let clothesMask = personMask.applyingFilter("CIMultiplyCompositing", parameters: [kCIInputBackgroundImageKey: bodyArea])

        let gray = CIImage(color: CIColor(red: plainClothesGray, green: plainClothesGray, blue: plainClothesGray)).cropped(to: extent)
        let result = gray.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: original,
            kCIInputMaskImageKey: clothesMask
        ])
        guard let output = CIContext().createCGImage(result, from: extent) else { return nil }
        return UIImage(cgImage: output)
    }

    // MARK: - 4. Vision Background Removal (Transparent Cutout)
    
    /// Removes background from a UIImage using Apple Vision foreground instance mask,
    /// returning transparent PNG data without any background artifacts (C5-46).
    static func removeBackground(from uiImage: UIImage) async -> Data? {
        guard let png = uiImage.pngData(),
              let ciImage = CIImage(data: png, options: [.applyOrientationProperty: true]) else { return nil }
        return await removeBackground(from: ciImage)
    }
    
    /// Removes background from a CIImage using Apple Vision foreground instance mask.
    static func removeBackground(from ciImage: CIImage) async -> Data? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return nil }
            
            let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            
            let filter = CIFilter.blendWithMask()
            filter.inputImage = ciImage
            filter.maskImage = maskCIImage
            filter.backgroundImage = CIImage.empty()
            
            guard let outputCIImage = filter.outputImage else { return nil }
            let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
            guard let outputCG = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
            let resultUI = UIImage(cgImage: outputCG)
            return resultUI.pngData()
        } catch {
            return nil
        }
    }
}

enum AttributeMapperError: Error, LocalizedError {
    case invalidJsonData
    
    var errorDescription: String? {
        switch self {
        case .invalidJsonData:
            return "Could not parse structured outfit attributes from raw LLM string."
        }
    }
}
