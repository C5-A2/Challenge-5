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
        let upperBody: CGRect
        let lowerBody: CGRect
        /// `nil` when the inner layer can't be located (no body pose found).
        let innerTop: CGRect?
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
            garmentRect = regions.upperBody
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
            garmentRect = regions.lowerBody
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

        // Upper body starts at the neck so the face stays out, and extends below the hips for long tops.
        let upperStartY = points([.neck]).first?.y
            ?? (shoulderY - torsoLength * StoreConstants.Crop.neckOffsetTorsoRatio)
        let upperEndY = hipY + torsoLength * StoreConstants.Crop.upperBodyExtensionBelowHipTorsoRatio
        let upperBody = CGRect(x: personBounds.minX, y: upperStartY,
                               width: personBounds.width, height: upperEndY - upperStartY)

        let lowerStartY = hipY - torsoLength * StoreConstants.Crop.lowerBodyStartAboveHipTorsoRatio
        let lowestLegY = lowerLegs.map(\.y).max() ?? personBounds.maxY
        let lowerEndY = min(lowestLegY + torsoLength * StoreConstants.Crop.lowerBodyExtensionBelowLegsTorsoRatio,
                            personBounds.maxY)
        let lowerBody = CGRect(x: personBounds.minX, y: lowerStartY,
                               width: personBounds.width, height: lowerEndY - lowerStartY)

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

        return BodyRegions(upperBody: upperBody, lowerBody: lowerBody, innerTop: innerTop)
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
        return BodyRegions(upperBody: upperBody, lowerBody: lowerBody, innerTop: nil)
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
