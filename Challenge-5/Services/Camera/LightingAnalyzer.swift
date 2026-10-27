//
//  LightingAnalyzer.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import Foundation
import AVFoundation
import Vision
import CoreImage

/// Real-time analyzer that processes camera video sample buffers to evaluate
/// scene luminance, detect facial presence, verify head pose alignment (direct angle),
/// and drive dynamic camera guidance feedback (C5-83).
public final class LightingAnalyzer: LightingAnalyzerProtocol, @unchecked Sendable {

    // MARK: - Configuration & Thresholds

    private let minOptimalLuminance: Double = 0.20
    private let maxOptimalLuminance: Double = 0.90
    private let maxRollAngleDegrees: Double = 12.0
    private let maxYawAngleDegrees: Double = 14.0

    // High-accuracy geometric alignment targets matching the SwiftUI oval guide
    private let targetCenterX: CGFloat = 0.50
    private let targetCenterY: CGFloat = 0.55
    private let maxHorizontalTolerance: CGFloat = 0.07   // Face must be within ±7% of center X
    private let maxVerticalTolerance: CGFloat = 0.08     // Face must be within ±8% of center Y
    private let minFaceWidthRatio: CGFloat = 0.28        // Must comfortably fill the oval guide
    private let maxFaceWidthRatio: CGFloat = 0.55        // Must not overflow the oval guide
    private let minEyeNoseSymmetry: CGFloat = 0.58       // Strict front-facing symmetry (rejects profile)

    // Frame throttling (~8 FPS for smooth responsive UI and low thermal/battery load)
    private var isProcessing: Bool = false
    private var lastAnalysisTimestamp: TimeInterval = 0
    private let analysisInterval: TimeInterval = 0.12
    private let lock = NSLock()

    // MARK: - Initializer

    public init() {}

    // MARK: - Simple Luminance Evaluation

    public func evaluateLuminance(from sampleBuffer: CMSampleBuffer) -> LightingStatus {
        let luminance = calculateLuminance(from: sampleBuffer)
        if luminance < minOptimalLuminance {
            return .tooDark
        } else if luminance > maxOptimalLuminance {
            return .tooBright
        } else {
            return .optimal
        }
    }

    // MARK: - Full Real-Time Frame Analysis

    public func analyzeFrame(_ sampleBuffer: CMSampleBuffer) async -> RealTimeFaceAnalysisResult? {
        // Drop frame if another analysis is actively processing or within interval
        let now = Date().timeIntervalSince1970
        lock.lock()
        if isProcessing || (now - lastAnalysisTimestamp < analysisInterval) {
            lock.unlock()
            return nil
        }
        isProcessing = true
        lastAnalysisTimestamp = now
        lock.unlock()

        defer {
            lock.lock()
            isProcessing = false
            lock.unlock()
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        // 1. Calculate Real-Time Luminance (0.0 to 1.0)
        let luminance = calculateLuminanceFromPixelBuffer(pixelBuffer)
        let lightingStatus: LightingStatus
        if luminance < minOptimalLuminance {
            lightingStatus = .tooDark
        } else if luminance > maxOptimalLuminance {
            lightingStatus = .tooBright
        } else {
            lightingStatus = .optimal
        }

        // 2. Perform Vision Face & Pose Detection
        let faceResult = await detectFaceAndPose(in: pixelBuffer)

        // 3. Synthesize Guidance Text & Optimal State
        let isLightingOK = (lightingStatus == .optimal)
        let isAngleOK = faceResult.isHeadPoseDirect
        let isCentered = faceResult.isFaceCentered
        let isDetected = faceResult.isFaceDetected

        let guidanceText: String
        let isReady: Bool

        if !isDetected {
            guidanceText = "Position face within the oval guide"
            isReady = false
        } else if let specific = faceResult.poseSpecificGuidance {
            guidanceText = specific
            isReady = false
        } else if !isCentered {
            guidanceText = "Move face closer to the center"
            isReady = false
        } else if !isAngleOK {
            guidanceText = "Face camera directly — keep head upright"
            isReady = false
        } else if !isLightingOK {
            guidanceText = lightingStatus.statusText
            isReady = false
        } else {
            guidanceText = "Position & lighting optimal ✅"
            isReady = true
        }

        return RealTimeFaceAnalysisResult(
            luminance: luminance,
            lightingStatus: lightingStatus,
            isFaceDetected: isDetected,
            isFaceCentered: isCentered,
            isHeadPoseDirect: isAngleOK,
            rollAngleDegrees: faceResult.rollDegrees,
            yawAngleDegrees: faceResult.yawDegrees,
            captureQuality: faceResult.quality,
            guidanceText: guidanceText,
            isReadyForOptimalCapture: isReady
        )
    }

    // MARK: - Luminance Calculation (Luma Sampling)

    private func calculateLuminance(from sampleBuffer: CMSampleBuffer) -> Double {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return 0.5
        }
        return calculateLuminanceFromPixelBuffer(pixelBuffer)
    }

    private func calculateLuminanceFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        // If bi-planar YUV format (standard iOS camera output), plane 0 is Luminance (Y)
        if CVPixelBufferIsPlanar(pixelBuffer) && CVPixelBufferGetPlaneCount(pixelBuffer) >= 1 {
            guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return 0.5 }
            let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
            let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)

            // Sample pixels on a coarse grid for maximum speed (~256 sample points)
            let stepX = max(1, width / 16)
            let stepY = max(1, height / 16)
            var totalLuma: UInt64 = 0
            var count: UInt64 = 0

            let ptr = yPlane.assumingMemoryBound(to: UInt8.self)
            for y in stride(from: 0, to: height, by: stepY) {
                let rowOffset = y * bytesPerRow
                for x in stride(from: 0, to: width, by: stepX) {
                    totalLuma += UInt64(ptr[rowOffset + x])
                    count += 1
                }
            }

            guard count > 0 else { return 0.5 }
            let avgLuma = Double(totalLuma) / Double(count)
            return min(max(avgLuma / 255.0, 0.0), 1.0)
        } else {
            // Fallback for non-planar RGB buffers
            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 0.5 }
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

            let stepX = max(1, width / 16)
            let stepY = max(1, height / 16)
            var totalLum: Double = 0.0
            var count: Double = 0.0

            let ptr = baseAddress.assumingMemoryBound(to: UInt8.self)
            for y in stride(from: 0, to: height, by: stepY) {
                let rowOffset = y * bytesPerRow
                for x in stride(from: 0, to: width, by: stepX) {
                    let pixelIndex = rowOffset + (x * 4)
                    let b = Double(ptr[pixelIndex])
                    let g = Double(ptr[pixelIndex + 1])
                    let r = Double(ptr[pixelIndex + 2])
                    let lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
                    totalLum += lum
                    count += 1
                }
            }

            guard count > 0 else { return 0.5 }
            return min(max(totalLum / count, 0.0), 1.0)
        }
    }

    // MARK: - Vision Face & Pose Detection

    private struct VisionFaceEvaluation {
        var isFaceDetected: Bool = false
        var isFaceCentered: Bool = false
        var isHeadPoseDirect: Bool = false
        var rollDegrees: Double = 0.0
        var yawDegrees: Double = 0.0
        var quality: Float = 0.0
        var poseSpecificGuidance: String? = nil
    }

    private func detectFaceAndPose(in pixelBuffer: CVPixelBuffer) async -> VisionFaceEvaluation {
        await withCheckedContinuation { continuation in
            let landmarksRequest = VNDetectFaceLandmarksRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNFaceObservation],
                      !observations.isEmpty else {
                    continuation.resume(returning: VisionFaceEvaluation(
                        poseSpecificGuidance: "Position face within the oval guide"
                    ))
                    return
                }

                // Pick primary / largest face in frame
                guard let face = observations.max(by: {
                    ($0.boundingBox.width * $0.boundingBox.height) < ($1.boundingBox.width * $1.boundingBox.height)
                }) else {
                    continuation.resume(returning: VisionFaceEvaluation(
                        poseSpecificGuidance: "Position face within the oval guide"
                    ))
                    return
                }

                let box = face.boundingBox
                let midX = box.midX
                let midY = box.midY
                let faceWidth = box.width

                // 1. Strict Distance & Centering Checks relative to the Oval Guide
                let isDistanceTooFar = (faceWidth < self.minFaceWidthRatio)
                let isDistanceTooClose = (faceWidth > self.maxFaceWidthRatio)
                let isDistanceOK = !isDistanceTooFar && !isDistanceTooClose

                let diffX = midX - self.targetCenterX
                let diffY = midY - self.targetCenterY

                let isCenteredX = abs(diffX) <= self.maxHorizontalTolerance
                let isCenteredY = abs(diffY) <= self.maxVerticalTolerance
                let isCentered = isCenteredX && isCenteredY && isDistanceOK

                // 2. Facial Landmarks & Side Profile Detection
                // In a true side profile, either one eye is missing or landmarks fail to detect both eyes
                guard let landmarks = face.landmarks,
                      let leftEye = landmarks.leftEye,
                      let rightEye = landmarks.rightEye,
                      leftEye.pointCount >= 4,
                      rightEye.pointCount >= 4,
                      let nose = landmarks.nose ?? landmarks.noseCrest,
                      nose.pointCount >= 2 else {
                    // One eye or nose is occluded -> side profile detected
                    continuation.resume(returning: VisionFaceEvaluation(
                        isFaceDetected: true,
                        isFaceCentered: isCentered,
                        isHeadPoseDirect: false,
                        rollDegrees: 0,
                        yawDegrees: 45,
                        quality: 0.3,
                        poseSpecificGuidance: "Face camera directly — avoid side profile"
                    ))
                    return
                }

                // 3. Eye-Nose Horizontal Symmetry (Key check for front vs sideways angle)
                let leftEyeCenter = self.averagePoint(of: leftEye.normalizedPoints)
                let rightEyeCenter = self.averagePoint(of: rightEye.normalizedPoints)
                let noseCenter = self.averagePoint(of: nose.normalizedPoints)

                // Roll Angle (tilt) from eye line slope
                let dx = rightEyeCenter.x - leftEyeCenter.x
                let dy = rightEyeCenter.y - leftEyeCenter.y
                let rollDeg = abs(atan2(dy, dx) * 180.0 / .pi)

                // Distance from nose to left eye vs nose to right eye
                let distToLeft = abs(noseCenter.x - leftEyeCenter.x)
                let distToRight = abs(rightEyeCenter.x - noseCenter.x)

                let minEyeDist = min(distToLeft, distToRight)
                let maxEyeDist = max(distToLeft, distToRight)
                let symmetryRatio = maxEyeDist > 0 ? (minEyeDist / maxEyeDist) : 0.0

                // Also inspect Vision's estimated yaw if available
                var visionYawDeg = 0.0
                if let yaw = face.yaw {
                    visionYawDeg = abs(yaw.doubleValue * 180.0 / .pi)
                }

                // Direct front criteria:
                // - Head upright: roll <= 12°
                // - Face not turned: symmetryRatio >= 0.58
                // - Vision yaw <= 14°
                let isRollOK = (rollDeg <= self.maxRollAngleDegrees)
                let isSymmetryOK = (symmetryRatio >= self.minEyeNoseSymmetry)
                let isYawOK = (visionYawDeg <= self.maxYawAngleDegrees)
                let isPoseDirect = isRollOK && isSymmetryOK && isYawOK

                var specificGuidance: String? = nil
                if isDistanceTooFar {
                    specificGuidance = "Move closer to fit the oval guide"
                } else if isDistanceTooClose {
                    specificGuidance = "Move slightly further back"
                } else if !isCenteredX {
                    // Mirrored front camera: diffX < 0 means face is left on screen, needs to move right
                    specificGuidance = (diffX < 0) ? "Move face slightly right" : "Move face slightly left"
                } else if !isCenteredY {
                    // Vision origin is bottom: diffY < 0 means face is too low on screen, needs to move up
                    specificGuidance = (diffY < 0) ? "Move face higher in the oval" : "Move face lower in the oval"
                } else if !isRollOK {
                    specificGuidance = "Keep your head upright"
                } else if !isSymmetryOK || !isYawOK {
                    specificGuidance = "Face camera directly — front view only"
                }

                let quality = face.faceCaptureQuality ?? 0.5

                let eval = VisionFaceEvaluation(
                    isFaceDetected: true,
                    isFaceCentered: isCentered,
                    isHeadPoseDirect: isPoseDirect,
                    rollDegrees: rollDeg,
                    yawDegrees: max(visionYawDeg, (1.0 - symmetryRatio) * 45.0),
                    quality: quality,
                    poseSpecificGuidance: specificGuidance
                )

                continuation.resume(returning: eval)
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([landmarksRequest])
            } catch {
                continuation.resume(returning: VisionFaceEvaluation())
            }
        }
    }

    private func averagePoint(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sumX = points.reduce(CGFloat.zero) { $0 + $1.x }
        let sumY = points.reduce(CGFloat.zero) { $0 + $1.y }
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
}
