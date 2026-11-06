//
//  VisionGarmentCropper.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import CoreImage
import Vision

/// Crops the outer, top, or bottom garment from a look image with the Vision framework (C5-58).
///
/// - Body pose (shoulders, hips, knees, ankles) locates the upper and lower body,
///   so the face and background stay out of the crop.
/// - When the look has an outer piece, the `.top` crop is the strip between the
///   shoulders where the inner layer shows through (C5-113).
/// - Without a body pose, proportional regions of the person are used instead (C5-59).
/// - The person is placed on white like a product photo, which helps Google Lens.
actor VisionGarmentCropper: GarmentCroppingProtocol {

    // MARK: - Types

    /// Garment regions in pixels, with a top-left origin.
    nonisolated private struct BodyRegions {
        /// A top without an outer layer.
        let upperBody: CGRect
        /// An outer piece, which can be longer than a top (coats).
        let outerBody: CGRect
        let lowerBody: CGRect
        /// A one-piece garment: from the neck to about the knees.
        let dressBody: CGRect
        /// `nil` when the inner layer can't be located (no body pose found).
        let innerTop: CGRect?
        /// Where the outer piece ends (pixels from the top), `nil` when it can't be found.
        let outerHemY: CGFloat?
        /// Shoulders-to-hips length, `nil` without a body pose.
        let torsoLength: CGFloat?
    }

    // MARK: - Properties

    private let ciContext = CIContext()

    // MARK: - Cropping

    func makeGarmentCrop(for request: GarmentCropRequest) async throws -> GarmentCrop {
        let image = request.lookImage
        let imageBounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let personBounds = await mainPersonRect(in: image) ?? imageBounds
        let regions = await bodyRegions(in: image, personBounds: personBounds)

        let garmentRect: CGRect
        switch request.category {
        case .outer:
            garmentRect = regions.outerBody
        case .top:
            if request.hasOuterLayer {
                guard let innerTop = regions.innerTop else {
                    throw StoreError.garmentNotDetected(request.category)
                }
                garmentRect = innerTop
            } else {
                garmentRect = regions.upperBody
            }
        case .bottom:
            garmentRect = bottomRect(in: regions, hasOuterLayer: request.hasOuterLayer)
        case .dress:
            garmentRect = regions.dressBody
        }

        let clippedRect = garmentRect.intersection(imageBounds).integral
        let minimumSide = StoreConstants.Crop.minimumCropSide
        let baseImage = await personOnWhite(in: image) ?? image
        guard !clippedRect.isNull,
              clippedRect.width > minimumSide,
              clippedRect.height > minimumSide,
              let garmentImage = baseImage.cropping(to: clippedRect) else {
            throw StoreError.garmentNotDetected(request.category)
        }

        return GarmentCrop(image: garmentImage)
    }

    // MARK: - Person Region

    /// The largest detected person, with a little padding.
    private func mainPersonRect(in image: CGImage) async -> CGRect? {
        var request = DetectHumanRectanglesRequest()
        request.upperBodyOnly = false
        guard let people = try? await request.perform(on: image), !people.isEmpty else { return nil }

        let size = CGSize(width: image.width, height: image.height)
        let rects = people.map { $0.boundingBox.toImageCoordinates(size, origin: .upperLeft) }
        guard let largest = rects.max(by: { $0.width * $0.height < $1.width * $1.height }) else { return nil }

        return largest
            .insetBy(dx: -largest.width * StoreConstants.Crop.personHorizontalPaddingRatio,
                     dy: -largest.height * StoreConstants.Crop.personVerticalPaddingRatio)
            .intersection(CGRect(origin: .zero, size: size))
            .integral
    }

    // MARK: - Body Regions

    private func bodyRegions(in image: CGImage, personBounds: CGRect) async -> BodyRegions {
        let size = CGSize(width: image.width, height: image.height)
        guard let poses = try? await DetectHumanBodyPoseRequest().perform(on: image),
              let pose = poses.max(by: { $0.allJoints().count < $1.allJoints().count }) else {
            return proportionalRegions(in: personBounds)
        }

        func points(_ names: [HumanBodyPoseObservation.JointName]) -> [CGPoint] {
            names.compactMap { pose.joint(for: $0) }
                .filter { $0.confidence > StoreConstants.Crop.minimumJointConfidence }
                .map { $0.location.toImageCoordinates(size, origin: .upperLeft) }
        }

        let shoulders = points([.leftShoulder, .rightShoulder])
        let hips = points([.leftHip, .rightHip])
        let lowerLegs = points([.leftAnkle, .rightAnkle, .leftKnee, .rightKnee])
        guard !shoulders.isEmpty, !hips.isEmpty else {
            return proportionalRegions(in: personBounds)
        }

        let shoulderY = average(shoulders.map(\.y))
        let hipY = average(hips.map(\.y))
        let torsoLength = hipY - shoulderY
        guard torsoLength > 0 else {
            return proportionalRegions(in: personBounds)
        }

        // Upper body starts at the neck so the face stays out.
        // A top ends just below the hips; an outer piece ends at its hem (found by color),
        // or further down when the hem isn't found, for long coats.
        let upperStartY = points([.neck]).first?.y
            ?? (shoulderY - torsoLength * StoreConstants.Crop.neckOffsetTorsoRatio)
        let topEndY = hipY + torsoLength * StoreConstants.Crop.topExtensionBelowHipTorsoRatio
        let upperBody = CGRect(x: personBounds.minX, y: upperStartY,
                               width: personBounds.width, height: topEndY - upperStartY)
        let hemY = outerHemY(in: image, shoulders: shoulders, lowerLegs: lowerLegs, shoulderY: shoulderY,
                             hipY: hipY, torsoLength: torsoLength, personBounds: personBounds)
        let fallbackOuterEndY = hipY + torsoLength * StoreConstants.Crop.outerExtensionBelowHipTorsoRatio
        let outerEndY = min(hemY.map { $0 + torsoLength * StoreConstants.Crop.hemPaddingTorsoRatio } ?? fallbackOuterEndY,
                            personBounds.maxY)
        let outerBody = CGRect(x: personBounds.minX, y: upperStartY,
                               width: personBounds.width, height: outerEndY - upperStartY)

        // Bottoms: from just above the hips to just below the ankles (shoes out),
        // as wide as the legs (hands out).
        let lowerStartY = hipY - torsoLength * StoreConstants.Crop.lowerBodyStartAboveHipTorsoRatio
        let ankles = points([.leftAnkle, .rightAnkle])
        let lowestLegY = (ankles.isEmpty ? lowerLegs : ankles).map(\.y).max() ?? personBounds.maxY
        let lowerEndY = min(lowestLegY + torsoLength * StoreConstants.Crop.lowerBodyExtensionBelowAnklesTorsoRatio,
                            personBounds.maxY)
        let legXs = (hips + lowerLegs).map(\.x)
        let legPadding = torsoLength * StoreConstants.Crop.lowerBodyHorizontalPaddingTorsoRatio
        let lowerMinX = max((legXs.min() ?? personBounds.minX) - legPadding, personBounds.minX)
        let lowerMaxX = min((legXs.max() ?? personBounds.maxX) + legPadding, personBounds.maxX)
        let lowerBody = CGRect(x: lowerMinX, y: lowerStartY,
                               width: lowerMaxX - lowerMinX, height: lowerEndY - lowerStartY)

        // Inner top: the strip between the shoulders, from the neck to the hips.
        let shoulderCenterX = average(shoulders.map(\.x))
        let shoulderWidth: CGFloat
        if shoulders.count > 1, let minX = shoulders.map(\.x).min(), let maxX = shoulders.map(\.x).max() {
            shoulderWidth = maxX - minX
        } else {
            shoulderWidth = personBounds.width * StoreConstants.Crop.fallbackShoulderWidthPersonRatio
        }
        let innerTopWidth = shoulderWidth * StoreConstants.Crop.innerTopWidthShoulderRatio
        let innerTop = CGRect(x: shoulderCenterX - innerTopWidth / 2, y: upperStartY,
                              width: innerTopWidth, height: hipY - upperStartY)

        let dressEndY = min(hipY + torsoLength * StoreConstants.Crop.dressExtensionBelowHipTorsoRatio,
                            personBounds.maxY)
        let dressBody = CGRect(x: personBounds.minX, y: upperStartY,
                               width: personBounds.width, height: dressEndY - upperStartY)

        return BodyRegions(upperBody: upperBody, outerBody: outerBody, lowerBody: lowerBody,
                           dressBody: dressBody, innerTop: innerTop, outerHemY: hemY, torsoLength: torsoLength)
    }

    /// Regions from the person's proportions, used when no body pose is found (C5-59).
    /// The inner layer can't be located this way.
    private func proportionalRegions(in personBounds: CGRect) -> BodyRegions {
        let upperBody = CGRect(
            x: personBounds.minX,
            y: personBounds.minY + personBounds.height * StoreConstants.Crop.fallbackUpperBodyStartRatio,
            width: personBounds.width,
            height: personBounds.height * StoreConstants.Crop.fallbackUpperBodyHeightRatio
        )
        let lowerBody = CGRect(
            x: personBounds.minX,
            y: personBounds.minY + personBounds.height * StoreConstants.Crop.fallbackLowerBodyStartRatio,
            width: personBounds.width,
            height: personBounds.height * StoreConstants.Crop.fallbackLowerBodyHeightRatio
        )
        let dressBody = CGRect(
            x: personBounds.minX,
            y: upperBody.minY,
            width: personBounds.width,
            height: personBounds.height * StoreConstants.Crop.fallbackDressHeightRatio
        )
        return BodyRegions(upperBody: upperBody, outerBody: upperBody, lowerBody: lowerBody,
                           dressBody: dressBody, innerTop: nil, outerHemY: nil, torsoLength: nil)
    }

    // MARK: - Outer Hem

    /// Where the outer piece ends. The outer's color comes from its sleeves and the bottoms' color
    /// from the lower legs; going down from the hips, the hem is the first rows where fewer than a
    /// quarter of the person's pixels look like the outer. `nil` when it can't be told apart.
    private func outerHemY(in image: CGImage, shoulders: [CGPoint], lowerLegs: [CGPoint], shoulderY: CGFloat,
                           hipY: CGFloat, torsoLength: CGFloat, personBounds: CGRect) -> CGFloat? {
        guard shoulders.count > 1,
              let leftShoulderX = shoulders.map(\.x).min(),
              let rightShoulderX = shoulders.map(\.x).max(),
              let sampler = LookPixelSampler(image: image) else { return nil }

        let halfWidth = max(1, torsoLength * StoreConstants.Crop.hemSampleHalfWidthTorsoRatio)
        let sleeveOffset = (rightShoulderX - leftShoulderX) * StoreConstants.Crop.hemSleeveOffsetShoulderRatio
        let sleeveTopY = shoulderY + torsoLength * StoreConstants.Crop.hemSleeveStartTorsoRatio
        let sleeveHeight = torsoLength * (StoreConstants.Crop.hemSleeveEndTorsoRatio - StoreConstants.Crop.hemSleeveStartTorsoRatio)
        let sleeveRects = [leftShoulderX - sleeveOffset, rightShoulderX + sleeveOffset].map {
            CGRect(x: $0 - halfWidth, y: sleeveTopY, width: halfWidth * 2, height: sleeveHeight)
        }
        let legBottomY = lowerLegs.map(\.y).max() ?? personBounds.maxY
        let legTopY = lowerLegs.map(\.y).min() ?? hipY
        let legCenterX = lowerLegs.isEmpty ? personBounds.midX : lowerLegs.map(\.x).reduce(0, +) / CGFloat(lowerLegs.count)
        let legRect = CGRect(x: legCenterX - halfWidth, y: legTopY, width: halfWidth * 2, height: legBottomY - legTopY)

        guard let outerColor = sampler.averageForegroundColor(in: sleeveRects),
              let bottomColor = sampler.averageForegroundColor(in: [legRect]),
              outerColor.distance(to: bottomColor) >= StoreConstants.Crop.hemMinimumColorDistance else { return nil }

        let requiredRows = max(StoreConstants.Crop.hemMinimumConsecutiveRows,
                               Int(torsoLength * StoreConstants.Crop.hemConsecutiveRowsTorsoRatio))
        let searchEndY = Int(min(hipY + torsoLength * StoreConstants.Crop.hemSearchDepthTorsoRatio, personBounds.maxY))
        let columns = Int(personBounds.minX)..<Int(personBounds.maxX)
        var passingRows = 0
        for rowY in Int(hipY)..<max(Int(hipY), searchEndY) {
            var personPixelCount = 0
            var outerPixelCount = 0
            for column in columns {
                guard let pixel = sampler.color(atX: column, y: rowY), !pixel.isBackground else { continue }
                personPixelCount += 1
                if pixel.distance(to: outerColor) < pixel.distance(to: bottomColor) {
                    outerPixelCount += 1
                }
            }
            let outerShare = personPixelCount == 0 ? 0 : Double(outerPixelCount) / Double(personPixelCount)
            if outerShare < StoreConstants.Crop.hemMaximumOuterPixelShare {
                passingRows += 1
                if passingRows >= requiredRows {
                    return CGFloat(rowY - passingRows + 1)
                }
            } else {
                passingRows = 0
            }
        }
        return nil
    }

    /// Bottoms under a long outer start at its hem, so the crop shows the pants instead of the coat.
    /// Keeps the normal region when too little leg would be left (the outer covers the pants).
    private func bottomRect(in regions: BodyRegions, hasOuterLayer: Bool) -> CGRect {
        let lowerBody = regions.lowerBody
        guard hasOuterLayer,
              let hemY = regions.outerHemY,
              let torsoLength = regions.torsoLength,
              hemY > lowerBody.minY else { return lowerBody }
        let visibleHeight = lowerBody.maxY - hemY
        guard visibleHeight >= torsoLength * StoreConstants.Crop.minimumVisibleBottomTorsoRatio else { return lowerBody }
        return CGRect(x: lowerBody.minX, y: hemY, width: lowerBody.width, height: visibleHeight)
    }

    private func average(_ values: [CGFloat]) -> CGFloat {
        values.reduce(0, +) / CGFloat(values.count)
    }

    // MARK: - Background

    /// The full-size image with everything except people replaced by white.
    /// Returns `nil` when person segmentation isn't available (for example in some simulators).
    private func personOnWhite(in image: CGImage) async -> CGImage? {
        let handler = ImageRequestHandler(image)
        guard let people = try? await handler.perform(GeneratePersonInstanceMaskRequest()),
              !people.allInstances.isEmpty,
              let masked = try? people.generateMaskedImage(for: people.allInstances, imageFrom: handler,
                                                           croppedToInstancesExtent: false) else {
            return nil
        }
        let cutout = CIImage(cvPixelBuffer: masked)
        let white = CIImage(color: .white).cropped(to: cutout.extent)
        return ciContext.createCGImage(cutout.composited(over: white), from: cutout.extent)
    }
}
