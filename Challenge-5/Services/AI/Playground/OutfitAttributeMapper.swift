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
        userProfile: UserProfile? = nil,
        variationIndex: Int = 0
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
            compositeVisualPrompt: prompt,
            variationIndex: variationIndex
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
    /// The user's full-body photo for Image Playground, passed as-is without masking or
    /// painting over the body so Image Playground can preserve skin tone, body shape, and proportions.
    static func playgroundSourceImage(fromPhotoData data: Data, openArms: Bool = false) -> UIImage? {
        let key = data.count ^ data.prefix(256).hashValue
        if let cached = sourceImageCache, cached.key == key { return cached.image }
        guard let photo = UIImage(data: data) else { return nil }
        sourceImageCache = (key, photo)
        return photo
    }

    // MARK: - 4. Post-Playground Face & Jawline Restoration (Option A)

    /// Restores the user's exact original face and jawline contour from `sourcePhotoData` onto the
    /// Image Playground generated image (`generatedCGImage`) using Vision 2D facial landmarks
    /// and a Procrustes uniform similarity transform.
    ///
    /// Preserves 100% of the source face's aspect ratio, jawline taper, cheek shading, and sharpness
    /// while blending seamlessly into the generated hair, neck, and outfit.
    static func restoreOriginalFace(
        in generatedCGImage: CGImage,
        fromSourcePhotoData sourcePhotoData: Data?
    ) async -> CGImage {
        guard let sourcePhotoData,
              let rawSrcCI = CIImage(data: sourcePhotoData, options: [.applyOrientationProperty: true]) else {
            return generatedCGImage
        }

        let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
        // Normalize source CIImage origin to (0, 0) after orientation transform
        let normalizedSrcCI = rawSrcCI.transformed(
            by: CGAffineTransform(translationX: -rawSrcCI.extent.origin.x, y: -rawSrcCI.extent.origin.y)
        )
        guard let srcCG = context.createCGImage(normalizedSrcCI, from: normalizedSrcCI.extent) else {
            return generatedCGImage
        }

        let dstCG = generatedCGImage
        guard let srcFace = detectPrimaryFaceLandmarks(in: srcCG),
              let dstFace = detectPrimaryFaceLandmarks(in: dstCG),
              let srcLandmarks = srcFace.landmarks,
              let dstLandmarks = dstFace.landmarks,
              let srcContourRegion = srcLandmarks.faceContour,
              let srcLeftBrowRegion = srcLandmarks.leftEyebrow,
              let srcRightBrowRegion = srcLandmarks.rightEyebrow else {
            return generatedCGImage
        }

        let srcSize = CGSize(width: srcCG.width, height: srcCG.height)
        let dstSize = CGSize(width: dstCG.width, height: dstCG.height)

        let srcAnchors = extractAlignmentAnchorPoints(from: srcLandmarks, imageSize: srcSize)
        let dstAnchors = extractAlignmentAnchorPoints(from: dstLandmarks, imageSize: dstSize)
        guard srcAnchors.count == dstAnchors.count, srcAnchors.count >= 20 else {
            return generatedCGImage
        }

        // Compute 2D Procrustes similarity transform (uniform scale + rotation + translation)
        let count = CGFloat(srcAnchors.count)
        let srcMean = CGPoint(
            x: srcAnchors.map(\.x).reduce(0, +) / count,
            y: srcAnchors.map(\.y).reduce(0, +) / count
        )
        let dstMean = CGPoint(
            x: dstAnchors.map(\.x).reduce(0, +) / count,
            y: dstAnchors.map(\.y).reduce(0, +) / count
        )

        var numCos: CGFloat = 0
        var numSin: CGFloat = 0
        var denom: CGFloat = 0
        for i in 0..<srcAnchors.count {
            let sx = srcAnchors[i].x - srcMean.x
            let sy = srcAnchors[i].y - srcMean.y
            let dx = dstAnchors[i].x - dstMean.x
            let dy = dstAnchors[i].y - dstMean.y
            numCos += sx * dx + sy * dy
            numSin += sx * dy - sy * dx
            denom += sx * sx + sy * sy
        }
        guard denom > 1e-4 else { return generatedCGImage }

        let a = numCos / denom
        let b = numSin / denom
        let uniformScale = hypot(a, b)
        let rotationRadians = atan2(b, a)

        // Guard against implausible face scale or rotation mismatches
        guard uniformScale > 0.2, uniformScale < 5.0, abs(rotationRadians) < (.pi / 6) else {
            return generatedCGImage
        }

        let transform = CGAffineTransform(translationX: -srcMean.x, y: -srcMean.y)
            .concatenating(CGAffineTransform(a: a, b: b, c: -b, d: a, tx: 0, ty: 0))
            .concatenating(CGAffineTransform(translationX: dstMean.x, y: dstMean.y))

        let srcContour = srcContourRegion.pointsInImage(imageSize: srcSize).map { $0.applying(transform) }
        let srcBrows = (
            srcLeftBrowRegion.pointsInImage(imageSize: srcSize) +
            srcRightBrowRegion.pointsInImage(imageSize: srcSize)
        ).map { $0.applying(transform) }

        guard srcContour.count >= 11,
              let browMaxY = srcBrows.map(\.y).max(),
              let firstContour = srcContour.first,
              let lastContour = srcContour.last else {
            return generatedCGImage
        }

        let chinPt = srcContour[srcContour.count / 2]
        let faceCenter = CGPoint(
            x: srcContour.map(\.x).reduce(0, +) / CGFloat(srcContour.count),
            y: (browMaxY + chinPt.y) / 2
        )
        let faceWidth = hypot(lastContour.x - firstContour.x, lastContour.y - firstContour.y)
        let faceHeight = max(1.0, browMaxY - chinPt.y)

        // Build expanded contour polygon covering face + jawline edge while staying above collar
        var polygon: [CGPoint] = []
        let contourCount = srcContour.count
        let halfIndex = CGFloat(contourCount / 2)
        for (i, pt) in srcContour.enumerated() {
            let t = abs(CGFloat(i) - halfIndex) / max(1.0, halfIndex)
            let radialX = pt.x - faceCenter.x
            let radialY = pt.y - faceCenter.y
            let sideExpand = 0.03 + 0.13 * pow(t, 0.7)
            let downExpand = (1.0 - t) * 0.03 * faceHeight
            polygon.append(
                CGPoint(
                    x: pt.x + radialX * sideExpand,
                    y: pt.y + radialY * 0.03 - downExpand
                )
            )
        }

        // Close polygon with a smooth forehead dome above the eyebrows
        if let firstTemple = polygon.first, let lastTemple = polygon.last {
            let foreheadTopY = browMaxY + faceHeight * 0.52
            let midX = (firstTemple.x + lastTemple.x) / 2
            let halfSpanX = abs(lastTemple.x - firstTemple.x) / 2
            let dirX: CGFloat = lastTemple.x >= firstTemple.x ? 1.0 : -1.0
            let baseTempleY = (firstTemple.y + lastTemple.y) / 2

            for step in 1...7 {
                let angle = CGFloat(step) / 8.0 * .pi
                let x = midX + dirX * cos(angle) * halfSpanX * 1.02
                let y = baseTempleY + sin(angle) * (foreheadTopY - baseTempleY)
                polygon.append(CGPoint(x: x, y: y))
            }
        }

        guard let rawMaskCG = rasterizePolygonMask(polygon: polygon, size: dstSize) else {
            return generatedCGImage
        }

        let dstExtent = CGRect(origin: .zero, size: dstSize)
        let featherRadius = max(3.0, faceWidth * 0.045)
        var maskCI = CIImage(cgImage: rawMaskCG)
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: featherRadius])
            .cropped(to: dstExtent)

        // Clip mask to the source photo's foreground person mask so room background never leaks in
        let srcCI = CIImage(cgImage: srcCG)
        if let srcForegroundMask = generateForegroundMask(for: srcCI) {
            let alignedForegroundMask = srcForegroundMask
                .transformed(by: transform)
                .cropped(to: dstExtent)
            maskCI = maskCI.applyingFilter(
                "CIMultiplyCompositing",
                parameters: [kCIInputBackgroundImageKey: alignedForegroundMask]
            )
        }

        let alignedSrcCI = srcCI.transformed(by: transform).cropped(to: dstExtent)
        let dstCI = CIImage(cgImage: dstCG)

        let blendedCI = alignedSrcCI.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: dstCI,
                kCIInputMaskImageKey: maskCI
            ]
        )

        return context.createCGImage(blendedCI, from: dstExtent) ?? generatedCGImage
    }

    private static func detectPrimaryFaceLandmarks(in cgImage: CGImage) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()
        request.revision = VNDetectFaceLandmarksRequestRevision3
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            return request.results?.max(by: { $0.boundingBox.width < $1.boundingBox.width })
        } catch {
            return nil
        }
    }

    private static func extractAlignmentAnchorPoints(
        from landmarks: VNFaceLandmarks2D,
        imageSize: CGSize
    ) -> [CGPoint] {
        let regions: [VNFaceLandmarkRegion2D?] = [
            landmarks.leftEye,
            landmarks.rightEye,
            landmarks.leftEyebrow,
            landmarks.rightEyebrow,
            landmarks.nose,
            landmarks.noseCrest,
            landmarks.outerLips,
            landmarks.faceContour
        ]
        return regions.compactMap { $0?.pointsInImage(imageSize: imageSize) }.flatMap { $0 }
    }

    private static func rasterizePolygonMask(polygon: [CGPoint], size: CGSize) -> CGImage? {
        guard let first = polygon.first, size.width > 0, size.height > 0 else { return nil }
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let maskContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        maskContext.setFillColor(gray: 0, alpha: 1)
        maskContext.fill(CGRect(origin: .zero, size: size))
        maskContext.setFillColor(gray: 1, alpha: 1)
        maskContext.beginPath()
        maskContext.move(to: first)
        for pt in polygon.dropFirst() {
            maskContext.addLine(to: pt)
        }
        maskContext.closePath()
        maskContext.fillPath()
        return maskContext.makeImage()
    }

    private static func generateForegroundMask(for ciImage: CIImage) -> CIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return nil }
            let maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
            return CIImage(cvPixelBuffer: maskPixelBuffer)
        } catch {
            return nil
        }
    }

    // MARK: - 5. Vision Background Removal (Transparent Cutout)
    
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
