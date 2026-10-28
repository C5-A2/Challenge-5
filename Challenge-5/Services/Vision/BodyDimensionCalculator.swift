//
//  BodyDimensionCalculator.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Vision-based body dimension and circumference calculation service (C5-93).
///
/// Computes shoulder width, bust, waist, and hip circumferences using Ramanujan's
/// ellipse approximation formula normalized by detected user height pixel-to-centimeter scale.
public final class BodyDimensionCalculator: BodyDimensionCalculatorProtocol, Sendable {

    public init() {}

    #if canImport(UIKit)
    /// Computes full anthropometric body dimensions from front and side capture photos.
    public func calculateDimensions(
        frontImage: UIImage,
        sideImage: UIImage?,
        enteredHeightCm: Double,
        frontPose: PoseAnalysisResult,
        sidePose: PoseAnalysisResult?
    ) async -> CalculatedBodyDimensions {
        await Self.calculateDimensionsInternal(
            frontImage: frontImage,
            sideImage: sideImage,
            enteredHeightCm: enteredHeightCm,
            frontPose: frontPose,
            sidePose: sidePose
        )
    }

    /// Static convenience method for direct dimension calculation.
    public static func calculateDimensions(
        frontImage: UIImage,
        sideImage: UIImage?,
        enteredHeightCm: Double,
        frontPose: PoseAnalysisResult,
        sidePose: PoseAnalysisResult?
    ) async -> CalculatedBodyDimensions {
        await calculateDimensionsInternal(
            frontImage: frontImage,
            sideImage: sideImage,
            enteredHeightCm: enteredHeightCm,
            frontPose: frontPose,
            sidePose: sidePose
        )
    }

    private static func calculateDimensionsInternal(
        frontImage: UIImage,
        sideImage: UIImage?,
        enteredHeightCm: Double,
        frontPose: PoseAnalysisResult,
        sidePose: PoseAnalysisResult?
    ) async -> CalculatedBodyDimensions {
        var warnings: [String] = []

        // 1. Calculate Pixels-per-Centimeter Scale
        let rawPixelsPerCm = BodyMeasurements.calculatePixelsPerCm(
            detectedPersonHeightPx: frontPose.personHeightPx,
            enteredHeightCm: enteredHeightCm
        )
        let pixelsPerCm: Double
        if let scale = rawPixelsPerCm, scale > 0 {
            pixelsPerCm = scale
        } else {
            let fallbackScale = max(1.0, frontPose.personHeightPx / max(100.0, enteredHeightCm))
            pixelsPerCm = fallbackScale
            warnings.append("Could not calculate precise pixel scale; using proportional approximation.")
        }

        let frontFixed = ImageOrientationHelper.fixOrientation(image: frontImage)
        let frontImageHeight = Double(frontFixed.cgImage?.height ?? 1000)

        // 2. Compute Shoulder Width in cm
        let shoulderWidthCm: Double
        if let swPx = frontPose.shoulderWidthPx, swPx > 0 {
            shoulderWidthCm = swPx / pixelsPerCm
        } else {
            shoulderWidthCm = enteredHeightCm * 0.235
            warnings.append("Shoulder landmarks not fully visible; estimated from height.")
        }

        // 3. Extract Front Silhouette Cross-Sections (Widths)
        let frontSeg = await PersonSegmentationAnalyzer.analyzeSegmentation(
            image: frontFixed,
            chestY: frontPose.chestLevelUIKitY,
            waistY: frontPose.waistLevelUIKitY,
            hipY: frontPose.hipLevelUIKitY,
            torsoCenterX: 0.5,
            poseResult: frontPose,
            isFrontView: true
        )
        warnings.append(contentsOf: frontSeg.warnings)

        let chestWidthPx = frontSeg.chestSlice?.widthPx ?? (frontPose.personHeightPx * 0.18)
        let waistWidthPx = frontSeg.waistSlice?.widthPx ?? (chestWidthPx * 0.78)
        let hipWidthPx = frontSeg.hipSlice?.widthPx ?? (chestWidthPx * 1.05)

        let chestWidthCm = max(15.0, chestWidthPx / pixelsPerCm)
        let waistWidthCm = max(15.0, waistWidthPx / pixelsPerCm)
        let hipWidthCm = max(18.0, hipWidthPx / pixelsPerCm)

        // 4. Extract Side Silhouette Cross-Sections (Depths)
        let chestDepthCm: Double
        let waistDepthCm: Double
        let hipDepthCm: Double

        if let sideImg = sideImage {
            let sideFixed = ImageOrientationHelper.fixOrientation(image: sideImg)

            let sideChestY = BodyPoseAnalyzer.mapFrontYToSideY(
                frontY: frontPose.chestLevelUIKitY,
                frontPose: frontPose,
                sidePose: sidePose
            )
            let sideWaistY = BodyPoseAnalyzer.mapFrontYToSideY(
                frontY: frontPose.waistLevelUIKitY,
                frontPose: frontPose,
                sidePose: sidePose
            )
            let sideHipY = BodyPoseAnalyzer.mapFrontYToSideY(
                frontY: frontPose.hipLevelUIKitY,
                frontPose: frontPose,
                sidePose: sidePose
            )

            let sideSeg = await PersonSegmentationAnalyzer.analyzeSegmentation(
                image: sideFixed,
                chestY: sideChestY,
                waistY: sideWaistY,
                hipY: sideHipY,
                torsoCenterX: 0.5,
                poseResult: sidePose,
                isFrontView: false
            )

            // Side pixel scale (if side pose height is detected, normalize by side height)
            let sideScale: Double
            if let sPose = sidePose, let sScale = BodyMeasurements.calculatePixelsPerCm(detectedPersonHeightPx: sPose.personHeightPx, enteredHeightCm: enteredHeightCm) {
                sideScale = sScale
            } else {
                sideScale = pixelsPerCm
            }

            if let cdPx = sideSeg.chestSlice?.widthPx {
                chestDepthCm = max(10.0, cdPx / sideScale)
            } else {
                chestDepthCm = chestWidthCm * 0.72
            }

            if let wdPx = sideSeg.waistSlice?.widthPx {
                waistDepthCm = max(10.0, wdPx / sideScale)
            } else {
                waistDepthCm = waistWidthCm * 0.70
            }

            if let hdPx = sideSeg.hipSlice?.widthPx {
                hipDepthCm = max(12.0, hdPx / sideScale)
            } else {
                hipDepthCm = hipWidthCm * 0.76
            }
        } else {
            // Fallback anatomical depth-to-width ratios when side photo is unavailable
            chestDepthCm = chestWidthCm * 0.72
            waistDepthCm = waistWidthCm * 0.70
            hipDepthCm = hipWidthCm * 0.76
            warnings.append("Side photo unavailable; body depth estimated using anatomical ratios.")
        }

        // 5. Compute Circumferences via Ramanujan Ellipse Approximation
        let rawBust = BodyMeasurements.ellipseCircumference(widthCm: chestWidthCm, depthCm: chestDepthCm)
        let rawWaist = BodyMeasurements.ellipseCircumference(widthCm: waistWidthCm, depthCm: waistDepthCm)
        let rawHip = BodyMeasurements.ellipseCircumference(widthCm: hipWidthCm, depthCm: hipDepthCm)

        let bustCircumferenceCm = rawBust > 0 ? rawBust : (chestWidthCm * 2.7)
        let waistCircumferenceCm = rawWaist > 0 ? rawWaist : (waistWidthCm * 2.65)
        let hipCircumferenceCm = rawHip > 0 ? rawHip : (hipWidthCm * 2.75)

        // 6. Compute Torso Length & Torso-to-Height Ratio (THR)
        let torsoHeightNormalized = max(0.15, frontPose.hipLevelUIKitY - frontPose.chestLevelUIKitY + 0.05)
        let torsoLengthCm = (torsoHeightNormalized * frontImageHeight) / pixelsPerCm
        let torsoToHeightRatio = (torsoLengthCm / enteredHeightCm) * 100.0

        return CalculatedBodyDimensions(
            shoulderWidthCm: round(shoulderWidthCm * 10) / 10,
            bustCircumferenceCm: round(bustCircumferenceCm * 10) / 10,
            waistCircumferenceCm: round(waistCircumferenceCm * 10) / 10,
            hipCircumferenceCm: round(hipCircumferenceCm * 10) / 10,
            chestWidthCm: round(chestWidthCm * 10) / 10,
            chestDepthCm: round(chestDepthCm * 10) / 10,
            waistWidthCm: round(waistWidthCm * 10) / 10,
            waistDepthCm: round(waistDepthCm * 10) / 10,
            hipWidthCm: round(hipWidthCm * 10) / 10,
            hipDepthCm: round(hipDepthCm * 10) / 10,
            torsoLengthCm: round(torsoLengthCm * 10) / 10,
            torsoToHeightRatio: round(torsoToHeightRatio * 10) / 10,
            pixelsPerCm: pixelsPerCm,
            warnings: warnings
        )
    }
    #endif
}
