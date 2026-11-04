//
//  ReferenceImageStyleAnalyzer.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 31/10/26.
//

import CoreGraphics
import Foundation
import Vision

/// What the user's reference photos show, written for the outfit prompt.
nonisolated struct ReferenceStyleAnalysis: Sendable {
    /// One line per photo: pieces, layering, colors (with the closest palette colors) and items seen.
    let promptDescription: String
    /// The outfit structure seen most often in the photos, `nil` when it can't be told.
    let suggestedStructure: OutfitStructure?
}

/// Reads the outfit in the user's reference photos on device, because the language model
/// only receives text and never sees the images.
///
/// For each photo:
/// - Body pose (Vision) locates the torso, sleeves and thighs, and their colors are sampled,
///   so the colors describe the clothes instead of the background.
/// - Sleeves that differ from the torso suggest an outer layer; a torso that matches the thighs
///   suggests a dress or jumpsuit.
/// - Colors are named and mapped to the closest swatch of the user's palette, so the reference
///   and the palette rule don't contradict each other.
/// - Image classification (Vision) adds the clothing items it recognizes.
final class ReferenceImageStyleAnalyzer: Sendable {

    // MARK: - Constants

    nonisolated private enum Constants {
        static let maximumPhotoCount = 3
        static let minimumJointConfidence: Float = 0.3
        static let minimumClassificationConfidence: Float = 0.1
        static let maximumItemsPerPhoto = 4

        // Sampled regions, as fractions of the torso length (shoulders to hips) or shoulder width.
        static let torsoSampleStartTorsoRatio: CGFloat = 0.3
        static let torsoSampleEndAboveHipTorsoRatio: CGFloat = 0.1
        static let torsoSampleHalfWidthShoulderRatio: CGFloat = 0.15
        static let sleeveOffsetShoulderRatio: CGFloat = 0.1
        static let sleeveSampleStartTorsoRatio: CGFloat = 0.3
        static let sleeveSampleEndTorsoRatio: CGFloat = 0.6
        static let sampleHalfWidthTorsoRatio: CGFloat = 0.03
        static let thighSampleStartTorsoRatio: CGFloat = 0.2
        static let thighSampleEndTorsoRatio: CGFloat = 0.6

        /// Sleeves this far (RGB distance) from the torso color are read as an outer layer.
        static let outerLayerColorDistance: Double = 50
        /// A torso this close (RGB distance) to the thighs is read as one piece (dress or jumpsuit).
        static let onePieceColorDistance: Double = 30

        // Color naming (HSB).
        static let blackMaximumBrightness: Double = 0.18
        static let whiteMinimumBrightness: Double = 0.88
        static let neutralMaximumSaturation: Double = 0.15
        static let darkMaximumBrightness: Double = 0.4
        static let lightMinimumBrightness: Double = 0.78
    }

    /// Words in Vision's classification labels that name clothing, and how they are written in the prompt.
    nonisolated private static let clothingKeywords: [(keyword: String, item: String)] = [
        ("dress", "dress"), ("gown", "gown"), ("jumpsuit", "jumpsuit"), ("skirt", "skirt"),
        ("jeans", "jeans"), ("denim", "denim"), ("trousers", "trousers"), ("pants", "pants"), ("shorts", "shorts"),
        ("suit", "suit"), ("blazer", "blazer"), ("coat", "coat"), ("jacket", "jacket"), ("cardigan", "cardigan"),
        ("sweater", "sweater"), ("sweatshirt", "sweatshirt"), ("hoodie", "hoodie"), ("shirt", "shirt"),
        ("blouse", "blouse"), ("t-shirt", "t-shirt"), ("vest", "vest"), ("leather", "leather"), ("lace", "lace")
    ]
    /// Items that are trousers or similar, which rule out a dress.
    nonisolated private static let separateBottomItems: Set<String> = ["jeans", "denim", "trousers", "pants", "shorts"]
    nonisolated private static let onePieceItems: Set<String> = ["dress", "gown", "jumpsuit"]

    // MARK: - Shared Instance

    static let shared = ReferenceImageStyleAnalyzer()

    private init() {}

    // MARK: - Analysis

    /// Describes the outfits in up to 3 reference photos. `nil` when there are no photos
    /// or nothing could be read from them.
    func analyzeOutfits(from imagesData: [Data], palette: [ColorSeason.ColorSwatch]) async -> ReferenceStyleAnalysis? {
        var lines: [String] = []
        var structures: [OutfitStructure] = []

        for (offset, data) in imagesData.prefix(Constants.maximumPhotoCount).enumerated() {
            guard let image = LookImageDecoder.makeImage(from: data),
                  let photo = await analyzePhoto(image, palette: palette) else { continue }
            lines.append("Photo \(offset + 1): \(photo.description)")
            if let structure = photo.structure {
                structures.append(structure)
            }
        }
        guard !lines.isEmpty else { return nil }

        let mostCommonStructure = Dictionary(grouping: structures, by: { $0 })
            .max { $0.value.count < $1.value.count }?
            .key
        return ReferenceStyleAnalysis(promptDescription: lines.joined(separator: "\n"),
                                      suggestedStructure: mostCommonStructure)
    }

    // MARK: - One Photo

    private func analyzePhoto(_ image: CGImage, palette: [ColorSeason.ColorSwatch])
        async -> (description: String, structure: OutfitStructure?)? {
        let items = await clothingItems(in: image)
        guard let sampler = LookPixelSampler(image: image) else { return nil }

        guard let regions = await bodySampleRegions(in: image) else {
            // No body pose: only the items and the overall clothing color can be described.
            let overall = sampler.averageForegroundColor(in: [CGRect(x: 0, y: 0, width: image.width, height: image.height)])
            var parts: [String] = []
            if let overall {
                parts.append("main color \(describe(overall, palette: palette))")
            }
            if !items.isEmpty {
                parts.append("items seen: \(items.joined(separator: ", "))")
            }
            let outfitStructure = structure(fromItems: items, hasOuterLayer: false, looksOnePiece: false)
            return parts.isEmpty ? nil : (parts.joined(separator: "; "), outfitStructure)
        }

        let torsoColor = sampler.averageForegroundColor(in: [regions.torso])
        let sleeveColor = sampler.averageForegroundColor(in: regions.sleeves)
        let thighColor = sampler.averageForegroundColor(in: [regions.thighs])

        let hasOuterLayer: Bool = {
            guard let torsoColor, let sleeveColor else { return false }
            return torsoColor.distance(to: sleeveColor) > Constants.outerLayerColorDistance
        }()
        let looksOnePiece: Bool = {
            guard let torsoColor, let thighColor else { return false }
            return torsoColor.distance(to: thighColor) < Constants.onePieceColorDistance
        }()
        let outfitStructure = structure(fromItems: items, hasOuterLayer: hasOuterLayer, looksOnePiece: looksOnePiece)

        var parts: [String] = [outfitStructure?.promptDescription.lowercased() ?? "outfit"]
        if hasOuterLayer, let sleeveColor {
            parts.append("outer layer \(describe(sleeveColor, palette: palette))")
        }
        if outfitStructure?.hasDress == true {
            if let torsoColor {
                parts.append("dress \(describe(torsoColor, palette: palette))")
            }
        } else {
            if let torsoColor {
                parts.append("top \(describe(torsoColor, palette: palette))")
            }
            if let thighColor {
                parts.append("bottom \(describe(thighColor, palette: palette))")
            }
        }
        if !items.isEmpty {
            parts.append("items seen: \(items.joined(separator: ", "))")
        }
        return (parts.joined(separator: "; "), outfitStructure)
    }

    /// Items win over colors: trousers rule out a dress, a recognized dress means one piece.
    private func structure(fromItems items: [String], hasOuterLayer: Bool, looksOnePiece: Bool) -> OutfitStructure? {
        let hasSeparateBottom = items.contains { Self.separateBottomItems.contains($0) }
        let hasOnePieceItem = items.contains { Self.onePieceItems.contains($0) }
        let isOnePiece = hasOnePieceItem || (looksOnePiece && !hasSeparateBottom)
        if isOnePiece {
            return hasOuterLayer ? .dressWithOuter : .dress
        }
        return hasOuterLayer ? .outerTopBottom : .topBottom
    }

    // MARK: - Body Regions

    private struct SampleRegions {
        let torso: CGRect
        let sleeves: [CGRect]
        let thighs: CGRect
    }

    /// Torso, sleeve and thigh areas from the body pose (pixels, top-left origin).
    private func bodySampleRegions(in image: CGImage) async -> SampleRegions? {
        let size = CGSize(width: image.width, height: image.height)
        guard let poses = try? await DetectHumanBodyPoseRequest().perform(on: image),
              let pose = poses.max(by: { $0.allJoints().count < $1.allJoints().count }) else { return nil }

        func points(_ names: [HumanBodyPoseObservation.JointName]) -> [CGPoint] {
            names.compactMap { pose.joint(for: $0) }
                .filter { $0.confidence > Constants.minimumJointConfidence }
                .map { $0.location.toImageCoordinates(size, origin: .upperLeft) }
        }

        let shoulders = points([.leftShoulder, .rightShoulder])
        let hips = points([.leftHip, .rightHip])
        guard shoulders.count > 1, !hips.isEmpty,
              let leftShoulderX = shoulders.map(\.x).min(),
              let rightShoulderX = shoulders.map(\.x).max() else { return nil }

        let shoulderY = shoulders.map(\.y).reduce(0, +) / CGFloat(shoulders.count)
        let hipY = hips.map(\.y).reduce(0, +) / CGFloat(hips.count)
        let hipCenterX = hips.map(\.x).reduce(0, +) / CGFloat(hips.count)
        let torsoLength = hipY - shoulderY
        let shoulderWidth = rightShoulderX - leftShoulderX
        guard torsoLength > 0, shoulderWidth > 0 else { return nil }

        let centerX = (leftShoulderX + rightShoulderX) / 2
        let torsoHalfWidth = shoulderWidth * Constants.torsoSampleHalfWidthShoulderRatio
        let torsoTop = shoulderY + torsoLength * Constants.torsoSampleStartTorsoRatio
        let torsoBottom = hipY - torsoLength * Constants.torsoSampleEndAboveHipTorsoRatio
        let torso = CGRect(x: centerX - torsoHalfWidth, y: torsoTop,
                           width: torsoHalfWidth * 2, height: torsoBottom - torsoTop)

        let sampleHalfWidth = max(1, torsoLength * Constants.sampleHalfWidthTorsoRatio)
        let sleeveOffset = shoulderWidth * Constants.sleeveOffsetShoulderRatio
        let sleeveTop = shoulderY + torsoLength * Constants.sleeveSampleStartTorsoRatio
        let sleeveHeight = torsoLength * (Constants.sleeveSampleEndTorsoRatio - Constants.sleeveSampleStartTorsoRatio)
        let sleeves = [leftShoulderX - sleeveOffset, rightShoulderX + sleeveOffset].map {
            CGRect(x: $0 - sampleHalfWidth, y: sleeveTop, width: sampleHalfWidth * 2, height: sleeveHeight)
        }

        let thighTop = hipY + torsoLength * Constants.thighSampleStartTorsoRatio
        let thighHeight = torsoLength * (Constants.thighSampleEndTorsoRatio - Constants.thighSampleStartTorsoRatio)
        let thighs = CGRect(x: hipCenterX - torsoHalfWidth, y: thighTop,
                            width: torsoHalfWidth * 2, height: thighHeight)

        return SampleRegions(torso: torso, sleeves: sleeves, thighs: thighs)
    }

    // MARK: - Clothing Items

    /// Clothing words from Vision's image classification labels.
    private func clothingItems(in image: CGImage) async -> [String] {
        guard let observations = try? await ClassifyImageRequest().perform(on: image) else { return [] }
        var items: [String] = []
        for observation in observations where observation.confidence > Constants.minimumClassificationConfidence {
            let words = observation.identifier.lowercased()
                .split(whereSeparator: { $0 == "_" || $0 == " " || $0 == "," })
                .map(String.init)
            for entry in Self.clothingKeywords where words.contains(entry.keyword) && !items.contains(entry.item) {
                items.append(entry.item)
            }
        }
        return Array(items.prefix(Constants.maximumItemsPerPhoto))
    }

    // MARK: - Color Description

    /// "dark red (closest palette color: Burgundy #800020)".
    private func describe(_ color: LookPixelSampler.RGBColor, palette: [ColorSeason.ColorSwatch]) -> String {
        let name = colorName(for: color)
        guard let swatch = closestSwatch(to: color, in: palette) else { return name }
        return "\(name) (closest palette color: \(swatch.name) \(swatch.hex))"
    }

    private func closestSwatch(to color: LookPixelSampler.RGBColor,
                               in palette: [ColorSeason.ColorSwatch]) -> ColorSeason.ColorSwatch? {
        palette.min { first, second in
            guard let firstColor = rgbColor(fromHex: first.hex) else { return false }
            guard let secondColor = rgbColor(fromHex: second.hex) else { return true }
            return color.distance(to: firstColor) < color.distance(to: secondColor)
        }
    }

    /// A plain color name from hue, saturation and brightness, for example "dark red" or "beige".
    private func colorName(for color: LookPixelSampler.RGBColor) -> String {
        let red = color.red / 255, green = color.green / 255, blue = color.blue / 255
        let maximum = max(red, green, blue), minimum = min(red, green, blue)
        let brightness = maximum
        let saturation = maximum == 0 ? 0 : (maximum - minimum) / maximum

        if brightness < Constants.blackMaximumBrightness { return "black" }
        if saturation < Constants.neutralMaximumSaturation {
            if brightness > Constants.whiteMinimumBrightness { return "white" }
            return brightness < Constants.darkMaximumBrightness ? "charcoal" : "grey"
        }

        let delta = maximum - minimum
        var hue: Double
        if maximum == red {
            hue = (green - blue) / delta
        } else if maximum == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }
        hue = (hue * 60).truncatingRemainder(dividingBy: 360)
        if hue < 0 { hue += 360 }

        let baseName: String
        switch hue {
        case ..<15, 345...: baseName = "red"
        case ..<40: baseName = brightness > Constants.lightMinimumBrightness ? "beige" : "brown"
        case ..<65: baseName = "yellow"
        case ..<160: baseName = "green"
        case ..<200: baseName = "teal"
        case ..<255: baseName = "blue"
        case ..<290: baseName = "purple"
        default: baseName = "pink"
        }
        if brightness < Constants.darkMaximumBrightness { return "dark \(baseName)" }
        if brightness > Constants.lightMinimumBrightness && baseName != "beige" { return "light \(baseName)" }
        return baseName
    }

    private func rgbColor(fromHex hex: String) -> LookPixelSampler.RGBColor? {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return LookPixelSampler.RGBColor(red: Double((value >> 16) & 0xFF),
                                         green: Double((value >> 8) & 0xFF),
                                         blue: Double(value & 0xFF))
    }
}
