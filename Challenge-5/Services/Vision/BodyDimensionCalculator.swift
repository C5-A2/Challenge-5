//
//  BodyDimensionCalculator.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation
import Vision
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

        // 2. Compute Shoulder Width in cm
        let shoulderWidthCm: Double
        if let swPx = frontPose.shoulderWidthPx, swPx > 0 {
            shoulderWidthCm = swPx / pixelsPerCm
        } else {
            shoulderWidthCm = enteredHeightCm * 0.235
            warnings.append("Shoulder landmarks not fully visible; estimated from height.")
        }

        // 3. Initial vertical target levels from front pose (CobaBodyScan ScanSession pipeline)
        let initialFrontChestY = frontPose.chestLevelUIKitY
        let initialFrontWaistY = frontPose.waistLevelUIKitY
        let initialFrontHipY = frontPose.hipLevelUIKitY

        let initialSideChestY = BodyPoseAnalyzer.mapFrontYToSideY(
            frontY: initialFrontChestY,
            frontPose: frontPose,
            sidePose: sidePose
        )
        let initialSideWaistY = BodyPoseAnalyzer.mapFrontYToSideY(
            frontY: initialFrontWaistY,
            frontPose: frontPose,
            sidePose: sidePose
        )
        let initialSideHipY = BodyPoseAnalyzer.mapFrontYToSideY(
            frontY: initialFrontHipY,
            frontPose: frontPose,
            sidePose: sidePose
        )

        // 4. Extract Front Silhouette Cross-Sections (Widths)
        let frontSeg = await PersonSegmentationAnalyzer.analyzeSegmentation(
            image: frontFixed,
            chestY: initialFrontChestY,
            waistY: initialFrontWaistY,
            hipY: initialFrontHipY,
            torsoCenterX: 0.5,
            poseResult: frontPose,
            isFrontView: true
        )
        warnings.append(contentsOf: frontSeg.warnings)

        var actualFrontChestY = initialFrontChestY
        var actualFrontWaistY = initialFrontWaistY
        var actualFrontHipY = initialFrontHipY

        let effectiveSideChestY = initialSideChestY
        var effectiveSideWaistY = initialSideWaistY
        var effectiveSideHipY = initialSideHipY

        if let fChest = frontSeg.chestSlice {
            actualFrontChestY = fChest.normalizedY
        }

        // If front waist detected narrowest contour, update frontWaistY and re-map sideWaistY to keep them perfectly in sync
        if let fWaist = frontSeg.waistSlice {
            actualFrontWaistY = fWaist.normalizedY
            effectiveSideWaistY = BodyPoseAnalyzer.mapFrontYToSideY(
                frontY: actualFrontWaistY,
                frontPose: frontPose,
                sidePose: sidePose
            )
        }

        // If front hip detected widest contour, update frontHipY and re-map sideHipY to keep them perfectly in sync
        if let fHip = frontSeg.hipSlice {
            actualFrontHipY = fHip.normalizedY
            effectiveSideHipY = BodyPoseAnalyzer.mapFrontYToSideY(
                frontY: actualFrontHipY,
                frontPose: frontPose,
                sidePose: sidePose
            )
        }

        let chestWidthPx = frontSeg.chestSlice?.widthPx ?? (frontPose.personHeightPx * 0.18)
        let waistWidthPx = frontSeg.waistSlice?.widthPx ?? (chestWidthPx * 0.78)
        let hipWidthPx = frontSeg.hipSlice?.widthPx ?? (chestWidthPx * 1.05)

        let chestWidthCm = chestWidthPx / pixelsPerCm
        let waistWidthCm = waistWidthPx / pixelsPerCm
        let hipWidthCm = hipWidthPx / pixelsPerCm

        // 5. Extract Side Silhouette Cross-Sections (Depths) at mapped anatomical levels
        let chestDepthCm: Double
        let waistDepthCm: Double
        let hipDepthCm: Double

        var sideSegResult: SegmentationAnalysisResult? = nil
        var actualSideHipY = effectiveSideHipY

        if let sideImg = sideImage {
            let sideFixed = ImageOrientationHelper.fixOrientation(image: sideImg)

            let sideSeg = await PersonSegmentationAnalyzer.analyzeSegmentation(
                image: sideFixed,
                chestY: effectiveSideChestY,
                waistY: effectiveSideWaistY,
                hipY: effectiveSideHipY,
                torsoCenterX: 0.5,
                poseResult: sidePose,
                isFrontView: false
            )
            sideSegResult = sideSeg
            warnings.append(contentsOf: sideSeg.warnings)

            if let sHip = sideSeg.hipSlice {
                actualSideHipY = sHip.normalizedY
            }

            // Use the same front-derived pixelsPerCm scale exactly like CobaBodyScan
            if let cdPx = sideSeg.chestSlice?.widthPx, cdPx > 0 {
                chestDepthCm = cdPx / pixelsPerCm
            } else {
                chestDepthCm = chestWidthCm * 0.72
            }

            if let wdPx = sideSeg.waistSlice?.widthPx, wdPx > 0 {
                waistDepthCm = wdPx / pixelsPerCm
            } else {
                waistDepthCm = waistWidthCm * 0.70
            }

            if let hdPx = sideSeg.hipSlice?.widthPx, hdPx > 0 {
                hipDepthCm = hdPx / pixelsPerCm
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

        // 6. Compute Circumferences via Ramanujan Ellipse Approximation
        let rawBust = BodyMeasurements.ellipseCircumference(widthCm: chestWidthCm, depthCm: chestDepthCm)
        let rawWaist = BodyMeasurements.ellipseCircumference(widthCm: waistWidthCm, depthCm: waistDepthCm)
        let rawHip = BodyMeasurements.ellipseCircumference(widthCm: hipWidthCm, depthCm: hipDepthCm)

        let bustCircumferenceCm = (rawBust > 0 && !rawBust.isNaN) ? rawBust : (chestWidthCm * 2.7)
        let waistCircumferenceCm = (rawWaist > 0 && !rawWaist.isNaN) ? rawWaist : (waistWidthCm * 2.65)
        let hipCircumferenceCm = (rawHip > 0 && !rawHip.isNaN) ? rawHip : (hipWidthCm * 2.75)

        // 7. Compute Torso Length, Shoulder-to-Waist, & Torso-to-Height Ratio (Matching CobaBodyScan ScanSession.computeTorsoMeasurements)
        let totalNormHeight = max(0.3, frontPose.feetBottomUIKitY - frontPose.headTopUIKitY)

        let neckY: Double
        if let nk = frontPose.joints[.neck]?.normalizedLocation {
            neckY = Double(nk.y)
        } else {
            neckY = max(0.05, actualFrontChestY - 0.12)
        }

        let shoulderY: Double
        let ls = frontPose.joints[.leftShoulder]?.normalizedLocation
        let rs = frontPose.joints[.rightShoulder]?.normalizedLocation
        if let ls = ls, let rs = rs {
            shoulderY = Double(ls.y + rs.y) / 2.0
        } else if let s = ls ?? rs {
            shoulderY = Double(s.y)
        } else {
            shoulderY = max(0.08, actualFrontChestY - 0.08)
        }

        let deltaTorso = max(0.05, actualFrontHipY - neckY)
        let torsoLengthCm = (deltaTorso / totalNormHeight) * enteredHeightCm

        let deltaShoulderWaist = max(0.05, actualFrontWaistY - shoulderY)
        let shoulderToWaistCm = (deltaShoulderWaist / totalNormHeight) * enteredHeightCm

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
            shoulderToWaistCm: round(shoulderToWaistCm * 10) / 10,
            torsoToHeightRatio: round(torsoToHeightRatio * 10) / 10,
            pixelsPerCm: pixelsPerCm,
            frontChestY: actualFrontChestY,
            frontWaistY: actualFrontWaistY,
            frontHipY: actualFrontHipY,
            sideChestY: effectiveSideChestY,
            sideWaistY: effectiveSideWaistY,
            sideHipY: actualSideHipY,
            frontChestSlice: frontSeg.chestSlice,
            frontWaistSlice: frontSeg.waistSlice,
            frontHipSlice: frontSeg.hipSlice,
            sideChestSlice: sideSegResult?.chestSlice,
            sideWaistSlice: sideSegResult?.waistSlice,
            sideHipSlice: sideSegResult?.hipSlice,
            warnings: warnings
        )
    }
    #endif
}
