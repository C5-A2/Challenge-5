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

    private let minOptimalLuminance: Double = 0.35
    private let maxOptimalLuminance: Double = 0.85
    private let maxRollAngleDegrees: Double = 12.0
    private let maxYawAngleDegrees: Double = 15.0

    // Frame throttling (min 100ms interval = ~10 FPS for battery & CPU efficiency)
    private var lastAnalysisTimestamp: TimeInterval = 0
    private let analysisInterval: TimeInterval = 0.10
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

    public func analyzeFrame(_ sampleBuffer: CMSampleBuffer) async -> RealTimeFaceAnalysisResult {
        // Throttle frames to prevent unnecessary CPU load
        let now = Date().timeIntervalSince1970
        lock.lock()
        guard now - lastAnalysisTimestamp >= analysisInterval else {
            lock.unlock()
            return RealTimeFaceAnalysisResult()
        }
        lastAnalysisTimestamp = now
        lock.unlock()

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return RealTimeFaceAnalysisResult()
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
        } else if !isCentered {
            guidanceText = "Move face to the center of the guide"
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
    }

    private func detectFaceAndPose(in pixelBuffer: CVPixelBuffer) async -> VisionFaceEvaluation {
        await withCheckedContinuation { continuation in
            let faceRequest = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNFaceObservation],
                      let face = observations.first else {
                    continuation.resume(returning: VisionFaceEvaluation())
                    return
                }

                // Roll: tilt angle clockwise/counter-clockwise in radians
                var rollDeg = 0.0
                if let roll = face.roll {
                    rollDeg = abs(roll.doubleValue * 180.0 / .pi)
                }

                // Yaw: head turn angle left/right in radians
                var yawDeg = 0.0
                if let yaw = face.yaw {
                    yawDeg = abs(yaw.doubleValue * 180.0 / .pi)
                }

                // Centering check: bounding box (normalized 0.0 to 1.0 from bottom-left)
                let box = face.boundingBox
                let midX = box.midX
                let midY = box.midY
                let isCentered = (midX >= 0.30 && midX <= 0.70) && (midY >= 0.25 && midY <= 0.75)

                let isPoseDirect = (rollDeg <= self.maxRollAngleDegrees) && (yawDeg <= self.maxYawAngleDegrees)
                let quality = face.faceCaptureQuality ?? 0.5

                let eval = VisionFaceEvaluation(
                    isFaceDetected: true,
                    isFaceCentered: isCentered,
                    isHeadPoseDirect: isPoseDirect,
                    rollDegrees: rollDeg,
                    yawDegrees: yawDeg,
                    quality: quality
                )

                continuation.resume(returning: eval)
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([faceRequest])
            } catch {
                continuation.resume(returning: VisionFaceEvaluation())
            }
        }
    }
}
