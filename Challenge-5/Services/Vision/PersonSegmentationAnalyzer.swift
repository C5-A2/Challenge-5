//
//  PersonSegmentationAnalyzer.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation
import Vision
import CoreVideo
#if canImport(UIKit)
import UIKit
#endif

/// Vision Framework Person Segmentation service (C5-93).
///
/// Generates human silhouette probability masks using `VNGeneratePersonSegmentationRequest`,
/// isolates the torso silhouette from adjacent limbs, and measures horizontal cross-sectional
/// slices across Chest, Waist (narrowest contour), and Hip (widest bilateral contour).
public final class PersonSegmentationAnalyzer: Sendable {

    public init() {}

    #if canImport(UIKit)
    /// Performs silhouette segmentation on a photograph at designated anatomical height levels.
    public static func analyzeSegmentation(
        image: UIImage,
        chestY: Double,
        waistY: Double,
        hipY: Double,
        torsoCenterX: Double = 0.5,
        poseResult: PoseAnalysisResult? = nil,
        isFrontView: Bool = true
    ) async -> SegmentationAnalysisResult {
        let fixedImage = ImageOrientationHelper.fixOrientation(image: image)
        guard let cgImage = fixedImage.cgImage else {
            return SegmentationAnalysisResult(
                chestSlice: nil,
                waistSlice: nil,
                hipSlice: nil,
                maskTopNormalizedY: nil,
                maskBottomNormalizedY: nil,
                isSegmentationAvailable: false,
                warnings: ["Failed to get CGImage for segmentation."]
            )
        }

        let originalWidth = Double(cgImage.width)

        return await withCheckedContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = .balanced
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

            do {
                try handler.perform([request])
                guard let observation = request.results?.first else {
                    continuation.resume(returning: SegmentationAnalysisResult(
                        chestSlice: nil,
                        waistSlice: nil,
                        hipSlice: nil,
                        maskTopNormalizedY: nil,
                        maskBottomNormalizedY: nil,
                        isSegmentationAvailable: false,
                        warnings: ["Person segmentation mask could not be generated."]
                    ))
                    return
                }

                let pixelBuffer = observation.pixelBuffer
                let result = processPixelBuffer(
                    pixelBuffer,
                    originalWidth: originalWidth,
                    chestY: chestY,
                    waistY: waistY,
                    hipY: hipY,
                    torsoCenterX: torsoCenterX,
                    poseResult: poseResult,
                    isFrontView: isFrontView
                )
                continuation.resume(returning: result)
            } catch {
                continuation.resume(returning: SegmentationAnalysisResult(
                    chestSlice: nil,
                    waistSlice: nil,
                    hipSlice: nil,
                    maskTopNormalizedY: nil,
                    maskBottomNormalizedY: nil,
                    isSegmentationAvailable: false,
                    warnings: ["Segmentation error: \(error.localizedDescription)"]
                ))
            }
        }
    }

    // MARK: - Pixel Buffer Processing

    private static func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        originalWidth: Double,
        chestY: Double,
        waistY: Double,
        hipY: Double,
        torsoCenterX: Double,
        poseResult: PoseAnalysisResult?,
        isFrontView: Bool
    ) -> SegmentationAnalysisResult {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return SegmentationAnalysisResult(
                chestSlice: nil,
                waistSlice: nil,
                hipSlice: nil,
                maskTopNormalizedY: nil,
                maskBottomNormalizedY: nil,
                isSegmentationAvailable: false,
                warnings: ["Could not read segmentation pixel buffer memory."]
            )
        }

        let maskWidth = CVPixelBufferGetWidth(pixelBuffer)
        let maskHeight = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let threshold: UInt8 = 110 // Silhouette probability threshold (out of 255)

        // Scan for overall vertical extent of mask
        var detectedTopY: Double? = nil
        var detectedBottomY: Double? = nil

        for row in 0..<maskHeight {
            let rowPtr = baseAddress.advanced(by: row * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            var hasPerson = false
            for col in 0..<maskWidth {
                if rowPtr[col] >= threshold {
                    hasPerson = true
                    break
                }
            }
            if hasPerson {
                if detectedTopY == nil {
                    detectedTopY = Double(row) / Double(maskHeight)
                }
                detectedBottomY = Double(row) / Double(maskHeight)
            }
        }

        // Determine actual torso center X from shoulder and hip joints if available
        var effectiveCenterX = torsoCenterX
        if let pose = poseResult {
            let ls = pose.joints[.leftShoulder]?.normalizedLocation
            let rs = pose.joints[.rightShoulder]?.normalizedLocation
            let lh = pose.joints[.leftHip]?.normalizedLocation
            let rh = pose.joints[.rightHip]?.normalizedLocation

            var sumX: Double = 0
            var count: Double = 0
            if let ls = ls, let rs = rs {
                sumX += Double(ls.x + rs.x)
                count += 2
            }
            if let lh = lh, let rh = rh {
                sumX += Double(lh.x + rh.x)
                count += 2
            }
            if count > 0 {
                effectiveCenterX = sumX / count
            }
        }

        // Calculate arm exclusion bounds if front view
        let chestArmBounds = isFrontView ? calculateArmExclusionBounds(atY: chestY, levelType: .chest, poseResult: poseResult, torsoCenterX: effectiveCenterX) : nil
        let waistArmBounds = isFrontView ? calculateArmExclusionBounds(atY: waistY, levelType: .waist, poseResult: poseResult, torsoCenterX: effectiveCenterX) : nil
        let hipArmBounds = isFrontView ? calculateArmExclusionBounds(atY: hipY, levelType: .hip, poseResult: poseResult, torsoCenterX: effectiveCenterX) : nil

        // 1. Extract Chest / Bust slice
        let chestSlice = extractSlice(
            atNormalizedY: chestY,
            torsoCenterX: effectiveCenterX,
            baseAddress: baseAddress,
            maskWidth: maskWidth,
            maskHeight: maskHeight,
            bytesPerRow: bytesPerRow,
            threshold: threshold,
            originalWidth: originalWidth,
            leftLimitNorm: chestArmBounds?.left,
            rightLimitNorm: chestArmBounds?.right
        )

        // 2. Extract Waist slice (scans narrowest contour around waist level)
        let waistSlice = extractNarrowestWaistSlice(
            centerWaistY: waistY,
            torsoCenterX: effectiveCenterX,
            baseAddress: baseAddress,
            maskWidth: maskWidth,
            maskHeight: maskHeight,
            bytesPerRow: bytesPerRow,
            threshold: threshold,
            originalWidth: originalWidth,
            leftLimitNorm: waistArmBounds?.left,
            rightLimitNorm: waistArmBounds?.right
        )

        // 3. Extract Hip slice (scans widest contour around hip level with bilateral crotch gap detection)
        let hipSlice = extractWidestHipSlice(
            centerHipY: hipY,
            torsoCenterX: effectiveCenterX,
            baseAddress: baseAddress,
            maskWidth: maskWidth,
            maskHeight: maskHeight,
            bytesPerRow: bytesPerRow,
            threshold: threshold,
            originalWidth: originalWidth,
            leftLimitNorm: hipArmBounds?.left,
            rightLimitNorm: hipArmBounds?.right,
            poseResult: poseResult,
            isFrontView: isFrontView
        )

        var warnings: [String] = []
        if chestSlice == nil || waistSlice == nil || hipSlice == nil {
            warnings.append("Could not extract clean silhouette contours at all target levels. Manual calibration recommended.")
        }

        return SegmentationAnalysisResult(
            chestSlice: chestSlice,
            waistSlice: waistSlice,
            hipSlice: hipSlice,
            maskTopNormalizedY: detectedTopY,
            maskBottomNormalizedY: detectedBottomY,
            isSegmentationAvailable: (detectedTopY != nil),
            warnings: warnings
        )
    }

    private enum TorsoLevelType {
        case chest
        case waist
        case hip
    }

    /// Calculates anatomical torso horizontal bounds to exclude adjoining arms.
    private static func calculateArmExclusionBounds(
        atY normY: Double,
        levelType: TorsoLevelType,
        poseResult: PoseAnalysisResult?,
        torsoCenterX: Double
    ) -> (left: Double, right: Double)? {
        guard let pose = poseResult else { return nil }

        let joints = pose.joints
        let ls = joints[.leftShoulder]?.normalizedLocation
        let rs = joints[.rightShoulder]?.normalizedLocation
        let lh = joints[.leftHip]?.normalizedLocation
        let rh = joints[.rightHip]?.normalizedLocation

        guard let s1 = ls ?? rs, let _ = s1 as CGPoint? else { return nil }

        let sLeftX: Double
        let sRightX: Double
        if let ls = ls, let rs = rs {
            sLeftX = Double(min(ls.x, rs.x))
            sRightX = Double(max(ls.x, rs.x))
        } else {
            let sx = Double((ls ?? rs)!.x)
            if sx < torsoCenterX {
                sLeftX = sx
                sRightX = torsoCenterX + (torsoCenterX - sx)
            } else {
                sRightX = sx
                sLeftX = torsoCenterX - (sx - torsoCenterX)
            }
        }
        let shoulderSpan = max(0.12, sRightX - sLeftX)

        let hLeftX: Double
        let hRightX: Double
        if let lh = lh, let rh = rh {
            hLeftX = Double(min(lh.x, rh.x))
            hRightX = Double(max(lh.x, rh.x))
        } else {
            hLeftX = torsoCenterX - (shoulderSpan * 0.42)
            hRightX = torsoCenterX + (shoulderSpan * 0.42)
        }

        let armJoints = [joints[.leftElbow], joints[.rightElbow], joints[.leftWrist], joints[.rightWrist]].compactMap { $0?.normalizedLocation }
        let leftArms = armJoints.filter { Double($0.x) < torsoCenterX }
        let rightArms = armJoints.filter { Double($0.x) > torsoCenterX }

        let armRadius = shoulderSpan * 0.12

        var innerArmLeftLimit: Double? = nil
        if let nearestLeftArm = leftArms.min(by: { abs(Double($0.y) - normY) < abs(Double($1.y) - normY) }),
           abs(Double(nearestLeftArm.y) - normY) < 0.20 {
            innerArmLeftLimit = Double(nearestLeftArm.x) + armRadius
        }

        var innerArmRightLimit: Double? = nil
        if let nearestRightArm = rightArms.min(by: { abs(Double($0.y) - normY) < abs(Double($1.y) - normY) }),
           abs(Double(nearestRightArm.y) - normY) < 0.20 {
            innerArmRightLimit = Double(nearestRightArm.x) - armRadius
        }

        switch levelType {
        case .chest:
            let anatomicalChestLeft = sLeftX - (shoulderSpan * 0.02)
            let anatomicalChestRight = sRightX + (shoulderSpan * 0.02)

            let finalLeft = max(anatomicalChestLeft, innerArmLeftLimit ?? anatomicalChestLeft)
            let finalRight = min(anatomicalChestRight, innerArmRightLimit ?? anatomicalChestRight)
            return (finalLeft, finalRight)

        case .waist:
            let anatomicalWaistLeft = max(sLeftX, hLeftX) - (shoulderSpan * 0.04)
            let anatomicalWaistRight = min(sRightX, hRightX) + (shoulderSpan * 0.04)

            let finalLeft = max(anatomicalWaistLeft, innerArmLeftLimit ?? anatomicalWaistLeft)
            let finalRight = min(anatomicalWaistRight, innerArmRightLimit ?? anatomicalWaistRight)
            return (finalLeft, finalRight)

        case .hip:
            let hipFlareAllowance = max(shoulderSpan * 0.30, (hRightX - hLeftX) * 0.60)
            let anatomicalHipLeft = max(0.02, hLeftX - hipFlareAllowance)
            let anatomicalHipRight = min(0.98, hRightX + hipFlareAllowance)

            let minHipWidthLeft = hLeftX - (shoulderSpan * 0.18)
            let minHipWidthRight = hRightX + (shoulderSpan * 0.18)

            var finalLeft = anatomicalHipLeft
            if let armLeft = innerArmLeftLimit {
                finalLeft = max(anatomicalHipLeft, min(armLeft, minHipWidthLeft))
            }
            var finalRight = anatomicalHipRight
            if let armRight = innerArmRightLimit {
                finalRight = min(anatomicalHipRight, max(armRight, minHipWidthRight))
            }
            return (finalLeft, finalRight)
        }
    }

    /// Scans several vertical offsets around waist level to detect the narrowest contour (True Waist).
    private static func extractNarrowestWaistSlice(
        centerWaistY: Double,
        torsoCenterX: Double,
        baseAddress: UnsafeMutableRawPointer,
        maskWidth: Int,
        maskHeight: Int,
        bytesPerRow: Int,
        threshold: UInt8,
        originalWidth: Double,
        leftLimitNorm: Double?,
        rightLimitNorm: Double?
    ) -> SliceExtractionResult? {
        let offsets = [-0.025, -0.012, 0.0, 0.012, 0.025]
        var candidateSlices: [SliceExtractionResult] = []

        for offset in offsets {
            let y = min(0.95, max(0.05, centerWaistY + offset))
            if let slice = extractSlice(
                atNormalizedY: y,
                torsoCenterX: torsoCenterX,
                baseAddress: baseAddress,
                maskWidth: maskWidth,
                maskHeight: maskHeight,
                bytesPerRow: bytesPerRow,
                threshold: threshold,
                originalWidth: originalWidth,
                leftLimitNorm: leftLimitNorm,
                rightLimitNorm: rightLimitNorm
            ) {
                candidateSlices.append(slice)
            }
        }

        return candidateSlices.min(by: { $0.widthPx < $1.widthPx })
    }

    /// Scans several offsets around hip level to detect the widest contour (Fullest Hip / Gluteal Apex).
    private static func extractWidestHipSlice(
        centerHipY: Double,
        torsoCenterX: Double,
        baseAddress: UnsafeMutableRawPointer,
        maskWidth: Int,
        maskHeight: Int,
        bytesPerRow: Int,
        threshold: UInt8,
        originalWidth: Double,
        leftLimitNorm: Double?,
        rightLimitNorm: Double?,
        poseResult: PoseAnalysisResult?,
        isFrontView: Bool
    ) -> SliceExtractionResult? {
        let offsets = [-0.03, -0.015, 0.0, 0.015, 0.03, 0.045, 0.06]
        var candidateSlices: [SliceExtractionResult] = []

        let minColLimit: Int = leftLimitNorm != nil ? max(0, min(maskWidth - 1, Int(leftLimitNorm! * Double(maskWidth)))) : 0
        let maxColLimit: Int = rightLimitNorm != nil ? min(maskWidth - 1, max(0, Int(rightLimitNorm! * Double(maskWidth)))) : (maskWidth - 1)

        let lh = isFrontView ? poseResult?.joints[.leftHip]?.normalizedLocation : nil
        let rh = isFrontView ? poseResult?.joints[.rightHip]?.normalizedLocation : nil
        let hasHipJoints = isFrontView && (lh != nil || rh != nil)

        let hLeftX: Double
        let hRightX: Double
        if let lh = lh, let rh = rh {
            hLeftX = Double(min(lh.x, rh.x))
            hRightX = Double(max(lh.x, rh.x))
        } else if let h = lh ?? rh {
            let hx = Double(h.x)
            if hx < torsoCenterX {
                hLeftX = hx
                hRightX = torsoCenterX + (torsoCenterX - hx)
            } else {
                hRightX = hx
                hLeftX = torsoCenterX - (hx - torsoCenterX)
            }
        } else {
            hLeftX = torsoCenterX - 0.12
            hRightX = torsoCenterX + 0.12
        }

        for offset in offsets {
            let y = min(0.95, max(0.05, centerHipY + offset))
            let row = min(maskHeight - 1, max(0, Int(y * Double(maskHeight))))
            let rowPtr = baseAddress.advanced(by: row * bytesPerRow).assumingMemoryBound(to: UInt8.self)

            if isFrontView && hasHipJoints {
                // Dual-Anchor Bilateral algorithm: Bridges the crotch gap between legs
                var leftAnchorCol = min(maskWidth - 1, max(0, Int(hLeftX * Double(maskWidth))))
                var rightAnchorCol = min(maskWidth - 1, max(0, Int(hRightX * Double(maskWidth))))

                if rowPtr[leftAnchorCol] < threshold {
                    let searchSpan = max(10, Int(Double(maskWidth) * 0.08))
                    for d in 1...searchSpan {
                        let cRight = leftAnchorCol + d
                        if cRight < rightAnchorCol && rowPtr[cRight] >= threshold {
                            leftAnchorCol = cRight
                            break
                        }
                        let cLeft = leftAnchorCol - d
                        if cLeft >= minColLimit && rowPtr[cLeft] >= threshold {
                            leftAnchorCol = cLeft
                            break
                        }
                    }
                }

                if rowPtr[rightAnchorCol] < threshold {
                    let searchSpan = max(10, Int(Double(maskWidth) * 0.08))
                    for d in 1...searchSpan {
                        let cLeft = rightAnchorCol - d
                        if cLeft > leftAnchorCol && rowPtr[cLeft] >= threshold {
                            rightAnchorCol = cLeft
                            break
                        }
                        let cRight = rightAnchorCol + d
                        if cRight <= maxColLimit && rowPtr[cRight] >= threshold {
                            rightAnchorCol = cRight
                            break
                        }
                    }
                }

                if rowPtr[leftAnchorCol] >= threshold && rowPtr[rightAnchorCol] >= threshold {
                    var leftEdge = leftAnchorCol
                    while leftEdge > minColLimit && rowPtr[leftEdge - 1] >= threshold {
                        leftEdge -= 1
                    }

                    var rightEdge = rightAnchorCol
                    while rightEdge < maxColLimit && rowPtr[rightEdge + 1] >= threshold {
                        rightEdge += 1
                    }

                    if rightEdge > leftEdge {
                        let normL = Double(leftEdge) / Double(maskWidth)
                        let normR = Double(rightEdge) / Double(maskWidth)
                        let normW = normR - normL
                        candidateSlices.append(SliceExtractionResult(
                            normalizedY: y,
                            normalizedLeft: normL,
                            normalizedRight: normR,
                            widthPx: normW * originalWidth,
                            normalizedWidth: normW,
                            confidence: 0.95
                        ))
                        continue
                    }
                }
            }

            if let slice = extractSlice(
                atNormalizedY: y,
                torsoCenterX: torsoCenterX,
                baseAddress: baseAddress,
                maskWidth: maskWidth,
                maskHeight: maskHeight,
                bytesPerRow: bytesPerRow,
                threshold: threshold,
                originalWidth: originalWidth,
                leftLimitNorm: leftLimitNorm,
                rightLimitNorm: rightLimitNorm
            ) {
                candidateSlices.append(slice)
            }
        }

        return candidateSlices.max(by: { $0.widthPx < $1.widthPx })
    }

    /// Extracts a horizontal slice along a specific row while bounded by arm boundaries.
    private static func extractSlice(
        atNormalizedY normY: Double,
        torsoCenterX: Double,
        baseAddress: UnsafeMutableRawPointer,
        maskWidth: Int,
        maskHeight: Int,
        bytesPerRow: Int,
        threshold: UInt8,
        originalWidth: Double,
        leftLimitNorm: Double? = nil,
        rightLimitNorm: Double? = nil
    ) -> SliceExtractionResult? {
        guard normY >= 0.0 && normY <= 1.0 else { return nil }

        let row = min(maskHeight - 1, max(0, Int(normY * Double(maskHeight))))
        let rowPtr = baseAddress.advanced(by: row * bytesPerRow).assumingMemoryBound(to: UInt8.self)

        let centerCol = min(maskWidth - 1, max(0, Int(torsoCenterX * Double(maskWidth))))

        let minColLimit: Int = leftLimitNorm != nil ? max(0, min(maskWidth - 1, Int(leftLimitNorm! * Double(maskWidth)))) : 0
        let maxColLimit: Int = rightLimitNorm != nil ? min(maskWidth - 1, max(0, Int(rightLimitNorm! * Double(maskWidth)))) : (maskWidth - 1)

        let clampedStartCol = min(maxColLimit, max(minColLimit, centerCol))
        var startCol = clampedStartCol

        if rowPtr[startCol] < threshold {
            let searchSpan = max(10, Int(Double(maskWidth) * 0.15))
            var found = false
            for offset in 1...searchSpan {
                let leftCol = max(minColLimit, clampedStartCol - offset)
                let rightCol = min(maxColLimit, clampedStartCol + offset)
                if rowPtr[leftCol] >= threshold {
                    startCol = leftCol
                    found = true
                    break
                }
                if rowPtr[rightCol] >= threshold {
                    startCol = rightCol
                    found = true
                    break
                }
            }
            if !found {
                var minX: Int? = nil
                var maxX: Int? = nil
                for col in minColLimit...maxColLimit {
                    if rowPtr[col] >= threshold {
                        if minX == nil { minX = col }
                        maxX = col
                    }
                }
                guard let l = minX, let r = maxX, r > l else { return nil }
                let normL = Double(l) / Double(maskWidth)
                let normR = Double(r) / Double(maskWidth)
                let normW = normR - normL
                return SliceExtractionResult(
                    normalizedY: normY,
                    normalizedLeft: normL,
                    normalizedRight: normR,
                    widthPx: normW * originalWidth,
                    normalizedWidth: normW,
                    confidence: 0.65
                )
            }
        }

        var leftEdge = startCol
        while leftEdge > minColLimit && rowPtr[leftEdge - 1] >= threshold {
            leftEdge -= 1
        }

        var rightEdge = startCol
        while rightEdge < maxColLimit && rowPtr[rightEdge + 1] >= threshold {
            rightEdge += 1
        }

        guard rightEdge > leftEdge else { return nil }

        let normL = Double(leftEdge) / Double(maskWidth)
        let normR = Double(rightEdge) / Double(maskWidth)
        let normW = normR - normL

        return SliceExtractionResult(
            normalizedY: normY,
            normalizedLeft: normL,
            normalizedRight: normR,
            widthPx: normW * originalWidth,
            normalizedWidth: normW,
            confidence: 0.90
        )
    }
    #endif
}
