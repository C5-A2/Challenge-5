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
#if canImport(UIKit)
import UIKit
#endif

/// Real-time smart analyzer (C5-83 & C5-123) that processes camera video frames and static images to:
/// 1. Verify bright, natural daylight illumination (`luminance` & bilateral evenness).
/// 2. Enforce strict 3-axis head pose (`yaw`, `roll`, and `pitch` — must face camera directly at eye level, never from above or below).
/// 3. Detect facial obstructions in real time (eyeglasses/sunglasses, face masks, hands, hair/bangs covering forehead or cheeks).
/// 4. Verify bare face with no heavy makeup (lipstick / heavy blush check).
@MainActor
public final class LightingAnalyzer: LightingAnalyzerProtocol {

    // MARK: - Configuration & Thresholds

    /// Require adequate daylight (>= 0.24 normalized luma) and avoid blown-out glare (<= 0.92).
    private let minOptimalLuminance: Double = 0.24
    private let maxOptimalLuminance: Double = 0.92

    /// Balanced 3-axis head pose thresholds (natural direct eye-level alignment without hyper-sensitive jitter).
    private let maxRollAngleDegrees: Double = 15.0
    private let maxYawAngleDegrees: Double = 18.0
    private let maxPitchAngleDegrees: Double = 16.0

    // Geometric alignment targets matching the SwiftUI oval guide
    private let targetCenterX: CGFloat = 0.50
    private let targetCenterY: CGFloat = 0.54
    private let maxHorizontalTolerance: CGFloat = 0.14
    private let maxVerticalTolerance: CGFloat = 0.15
    private let minFaceWidthRatio: CGFloat = 0.22
    private let maxFaceWidthRatio: CGFloat = 0.68
    private let minEyeNoseSymmetry: CGFloat = 0.50

    // Frame throttling (~8 FPS for smooth responsive UI and low thermal/battery load)
    private var isProcessing: Bool = false
    private var lastAnalysisTimestamp: TimeInterval = 0
    private let analysisInterval: TimeInterval = 0.12

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

    private func shouldProcessNextFrame() -> Bool {
        let now = Date().timeIntervalSince1970
        if isProcessing || (now - lastAnalysisTimestamp < analysisInterval) {
            return false
        }
        isProcessing = true
        lastAnalysisTimestamp = now
        return true
    }

    private func finishProcessing() {
        isProcessing = false
    }

    // MARK: - Full Real-Time Frame Analysis

    public func analyzeFrame(_ sampleBuffer: CMSampleBuffer) async -> RealTimeFaceAnalysisResult? {
        guard shouldProcessNextFrame() else {
            return nil
        }

        defer {
            finishProcessing()
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let sceneLuminance = calculateLuminanceFromPixelBuffer(pixelBuffer)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)

        return await evaluateFaceInFrame(
            pixelBuffer: pixelBuffer,
            cgImage: cgImage,
            sceneLuminance: sceneLuminance
        )
    }

    #if canImport(UIKit)
    /// Evaluates a static `UIImage` (captured photo or gallery selection) using the exact same C5-123 criteria.
    public func analyzeStaticImage(_ image: UIImage) async -> RealTimeFaceAnalysisResult {
        guard let cgImage = Self.normalizedCGImage(from: image) else {
            return RealTimeFaceAnalysisResult(
                guidanceText: "Unable to read image for face validation",
                isReadyForOptimalCapture: false
            )
        }
        let sceneLum = Self.calculateLuminanceFromCGImage(cgImage)
        return await evaluateFaceInFrame(
            pixelBuffer: nil,
            cgImage: cgImage,
            sceneLuminance: sceneLum
        )
    }
    #endif

    // MARK: - Core Multi-Stage Evaluation (Pose + Lighting + Occlusion + Bare Face)

    private func evaluateFaceInFrame(
        pixelBuffer: CVPixelBuffer?,
        cgImage: CGImage?,
        sceneLuminance: Double
    ) async -> RealTimeFaceAnalysisResult {
        let faceEval = await detectFacePoseAndObstructions(pixelBuffer: pixelBuffer, cgImage: cgImage)

        // Combine scene luminance with actual facial skin luminance if a face is present
        let effectiveLuminance = faceEval.faceLuminance ?? sceneLuminance

        let lightingStatus: LightingStatus
        if effectiveLuminance < minOptimalLuminance {
            lightingStatus = .tooDark
        } else if effectiveLuminance > maxOptimalLuminance {
            lightingStatus = .tooBright
        } else if faceEval.isUnevenlyLit {
            lightingStatus = .backlit
        } else {
            lightingStatus = .optimal
        }

        let isLightingOK = (lightingStatus == .optimal)
        let isDetected = faceEval.isFaceDetected
        let isCentered = faceEval.isFaceCentered
        let isAngleOK = faceEval.isHeadPoseDirect
        let isUnobstructed = faceEval.isFaceUnobstructed
        let isBareFace = faceEval.isBareFace

        let guidanceText: String
        let isReady: Bool

        if !isDetected {
            guidanceText = "Position face within the oval guide"
            isReady = false
        } else if let obstruction = faceEval.obstructionReason {
            guidanceText = obstruction
            isReady = false
        } else if let poseMsg = faceEval.poseSpecificGuidance {
            guidanceText = poseMsg
            isReady = false
        } else if !isCentered {
            guidanceText = "Center your face inside the oval guide"
            isReady = false
        } else if !isAngleOK {
            guidanceText = "Face camera directly at eye level"
            isReady = false
        } else if !isLightingOK {
            guidanceText = lightingStatus.statusText
            isReady = false
        } else if !isBareFace {
            guidanceText = "Makeup detected — bare face required"
            isReady = false
        } else {
            guidanceText = "Face clear, direct & bright daylight ✅"
            isReady = true
        }

        return RealTimeFaceAnalysisResult(
            luminance: effectiveLuminance,
            lightingStatus: lightingStatus,
            isFaceDetected: isDetected,
            isFaceCentered: isCentered,
            isHeadPoseDirect: isAngleOK,
            isFaceUnobstructed: isUnobstructed,
            isBareFace: isBareFace,
            rollAngleDegrees: faceEval.rollDegrees,
            yawAngleDegrees: faceEval.yawDegrees,
            pitchAngleDegrees: faceEval.pitchDegrees,
            captureQuality: faceEval.quality,
            obstructionReason: faceEval.obstructionReason,
            guidanceText: guidanceText,
            isReadyForOptimalCapture: isReady
        )
    }

    // MARK: - Vision Face, 3-Axis Pose & Occlusion Detection

    private struct VisionFaceEvaluation {
        var isFaceDetected: Bool = false
        var isFaceCentered: Bool = false
        var isHeadPoseDirect: Bool = false
        var isFaceUnobstructed: Bool = false
        var isBareFace: Bool = true
        var isUnevenlyLit: Bool = false
        var faceLuminance: Double? = nil
        var rollDegrees: Double = 0.0
        var yawDegrees: Double = 0.0
        var pitchDegrees: Double = 0.0
        var quality: Float = 0.0
        var obstructionReason: String? = nil
        var poseSpecificGuidance: String? = nil
    }

    private func detectFacePoseAndObstructions(
        pixelBuffer: CVPixelBuffer?,
        cgImage: CGImage?
    ) async -> VisionFaceEvaluation {
        await withCheckedContinuation { continuation in
            let landmarksRequest = VNDetectFaceLandmarksRequest()
            let classifyRequest = VNClassifyImageRequest()
            let handPoseRequest = VNDetectHumanHandPoseRequest()
            handPoseRequest.maximumHandCount = 2

            let handler: VNImageRequestHandler?
            if let cgImage {
                handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            } else if let pixelBuffer {
                handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            } else {
                continuation.resume(returning: VisionFaceEvaluation())
                return
            }

            do {
                try handler?.perform([landmarksRequest, classifyRequest, handPoseRequest])
            } catch {
                do {
                    try handler?.perform([landmarksRequest, classifyRequest])
                } catch {
                    continuation.resume(returning: VisionFaceEvaluation())
                    return
                }
            }

            guard let observations = landmarksRequest.results,
                  !observations.isEmpty,
                  let face = observations.max(by: {
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

            // 1. Distance & Centering relative to Oval Guide
            let isDistanceTooFar = (faceWidth < self.minFaceWidthRatio)
            let isDistanceTooClose = (faceWidth > self.maxFaceWidthRatio)
            let isDistanceOK = !isDistanceTooFar && !isDistanceTooClose

            let diffX = midX - self.targetCenterX
            let diffY = midY - self.targetCenterY
            let isCenteredX = abs(diffX) <= self.maxHorizontalTolerance
            let isCenteredY = abs(diffY) <= self.maxVerticalTolerance
            let isCentered = isCenteredX && isCenteredY && isDistanceOK

            // 2. Check Vision Classifier & Hand Pose Detector for Hand / Eyewear / Mask / Face Covering
            var glassesClassifierConfidence: Float = 0.0
            var maskClassifierConfidence: Float = 0.0
            var handClassifierConfidence: Float = 0.0
            if let classifications = classifyRequest.results {
                for item in classifications {
                    let id = item.identifier.lowercased()
                    if id.contains("sunglass") || id.contains("eyeglass") || id.contains("spectacle") || id.contains("goggle") || id.contains("glasses") {
                        glassesClassifierConfidence = max(glassesClassifierConfidence, item.confidence)
                    }
                    if id.contains("mask") || id.contains("respirator") || id.contains("bandana") || id.contains("veil") || id.contains("scarf") || id.contains("helmet") {
                        maskClassifierConfidence = max(maskClassifierConfidence, item.confidence)
                    }
                    if id.contains("hand") || id.contains("finger") || id.contains("palm") || id.contains("fist") || id.contains("gesture") || id.contains("thumb") {
                        handClassifierConfidence = max(handClassifierConfidence, item.confidence)
                    }
                }
            }

            // Detect Human Hand / Fingers via VNDetectHumanHandPoseRequest (only if hand is actually over the face)
            var isHandDetectedInFrame = false
            let faceMaskRect = box.insetBy(dx: -box.width * 0.05, dy: -box.height * 0.05)
            if let handObservations = handPoseRequest.results, !handObservations.isEmpty {
                for hand in handObservations {
                    if let points = try? hand.recognizedPoints(.all) {
                        let confidentJoints = points.values.filter { $0.confidence >= 0.35 }
                        let jointsOnFace = confidentJoints.filter { pt in
                            faceMaskRect.contains(CGPoint(x: pt.location.x, y: pt.location.y))
                        }
                        if jointsOnFace.count >= 2 {
                            isHandDetectedInFrame = true
                            break
                        }
                    }
                }
            }

            // 3. Verify All Essential Facial Landmarks Exist (Eyes, Eyebrows, Nose, Mouth, Contour)
            guard let landmarks = face.landmarks,
                  let leftEye = landmarks.leftEye, leftEye.pointCount >= 4,
                  let rightEye = landmarks.rightEye, rightEye.pointCount >= 4,
                  let leftEyebrow = landmarks.leftEyebrow, leftEyebrow.pointCount >= 3,
                  let rightEyebrow = landmarks.rightEyebrow, rightEyebrow.pointCount >= 3,
                  let nose = landmarks.nose, nose.pointCount >= 3,
                  let outerLips = landmarks.outerLips, outerLips.pointCount >= 6,
                  let innerLips = landmarks.innerLips, innerLips.pointCount >= 4,
                  let contour = landmarks.faceContour, contour.pointCount >= 10 else {
                continuation.resume(returning: VisionFaceEvaluation(
                    isFaceDetected: true,
                    isFaceCentered: isCentered,
                    isHeadPoseDirect: false,
                    isFaceUnobstructed: false,
                    obstructionReason: "Face obstructed — uncover eyes, nose, and mouth"
                ))
                return
            }

            if landmarks.confidence < 0.45 {
                continuation.resume(returning: VisionFaceEvaluation(
                    isFaceDetected: true,
                    isFaceCentered: isCentered,
                    isHeadPoseDirect: false,
                    isFaceUnobstructed: false,
                    obstructionReason: "Face partially covered — remove glasses, mask, or hair"
                ))
                return
            }

            // 4. 3-Axis Head Pose Calculation (Roll, Yaw, Pitch — "Jangan dari bawah atau atas")
            let leftEyeCenter = self.averagePoint(of: leftEye.normalizedPoints)
            let rightEyeCenter = self.averagePoint(of: rightEye.normalizedPoints)
            let noseCenter = self.averagePoint(of: nose.normalizedPoints)
            let mouthCenter = self.averagePoint(of: outerLips.normalizedPoints)

            // Roll (head tilt left/right)
            let dx = rightEyeCenter.x - leftEyeCenter.x
            let dy = rightEyeCenter.y - leftEyeCenter.y
            let rollDeg = abs(atan2(dy, dx) * 180.0 / .pi)

            // Yaw (turning head left/right)
            let distToLeft = abs(noseCenter.x - leftEyeCenter.x)
            let distToRight = abs(rightEyeCenter.x - noseCenter.x)
            let minEyeDist = min(distToLeft, distToRight)
            let maxEyeDist = max(distToLeft, distToRight)
            let symmetryRatio = maxEyeDist > 0 ? (minEyeDist / maxEyeDist) : 0.0

            var visionYawDeg = 0.0
            if let yaw = face.yaw {
                visionYawDeg = abs(yaw.doubleValue * 180.0 / .pi)
            }

            // Pitch (camera from below / chin up vs camera from above / chin down)
            var visionPitchDeg = 0.0
            var hasVisionPitch = false
            if #available(iOS 15.0, *), let pitch = face.pitch {
                visionPitchDeg = pitch.doubleValue * 180.0 / .pi
                hasVisionPitch = true
            }

            // Geometric vertical pitch ratio: (eyeLineY - noseBottomY) / (noseBottomY - mouthCenterY)
            let eyeMidY = (leftEyeCenter.y + rightEyeCenter.y) * 0.5
            let noseMinY = nose.normalizedPoints.map(\.y).min() ?? noseCenter.y
            let eyeToNose = max(0.01, eyeMidY - noseMinY)
            let noseToMouth = max(0.01, noseMinY - mouthCenter.y)
            let verticalPitchRatio = Double(eyeToNose / noseToMouth)

            // Detect camera held steeply from below or above
            let isLookingFromBelow = (hasVisionPitch && visionPitchDeg > self.maxPitchAngleDegrees) || (verticalPitchRatio < 0.78)
            let isLookingFromAbove = (hasVisionPitch && visionPitchDeg < -self.maxPitchAngleDegrees) || (verticalPitchRatio > 2.75)
            let isPitchOK = !isLookingFromBelow && !isLookingFromAbove

            let isRollOK = (rollDeg <= self.maxRollAngleDegrees)
            let isSymmetryOK = (symmetryRatio >= self.minEyeNoseSymmetry)
            let isYawOK = (visionYawDeg <= self.maxYawAngleDegrees)
            let isPoseDirect = isRollOK && isSymmetryOK && isYawOK && isPitchOK

            // 5. Pixel-Level Smart Obstruction & Bare-Face Inspection (Hand, Glasses, Mask, Hair, Makeup)
            var obstructionReason: String? = nil
            var isBareFace = true
            var isUnevenlyLit = false
            var computedFaceLuma: Double? = nil

            if isHandDetectedInFrame || handClassifierConfidence >= 0.60 {
                obstructionReason = "Hand detected — please remove your hand from your face"
            } else if maskClassifierConfidence >= 0.55 {
                obstructionReason = "Mask or face cover detected — uncover your face"
            } else if glassesClassifierConfidence >= 0.65 {
                obstructionReason = "Glasses detected — please remove eyewear"
            }

            if let cgImage {
                let skinCheck = Self.inspectFacialRegions(
                    in: cgImage,
                    faceBox: box,
                    leftEye: leftEye.normalizedPoints,
                    rightEye: rightEye.normalizedPoints,
                    leftEyebrow: leftEyebrow.normalizedPoints,
                    rightEyebrow: rightEyebrow.normalizedPoints,
                    nose: nose.normalizedPoints,
                    outerLips: outerLips.normalizedPoints,
                    glassesClassifierConfidence: glassesClassifierConfidence,
                    maskClassifierConfidence: maskClassifierConfidence,
                    handClassifierConfidence: handClassifierConfidence
                )
                computedFaceLuma = skinCheck.averageFaceLuminance
                isUnevenlyLit = skinCheck.isUnevenlyLit
                isBareFace = skinCheck.isBareFace

                if obstructionReason == nil {
                    obstructionReason = skinCheck.obstructionMessage
                }
            }

            // 6. Prioritized Guidance Message
            var specificGuidance: String? = nil
            if isDistanceTooFar {
                specificGuidance = "Move closer to fit the oval guide"
            } else if isDistanceTooClose {
                specificGuidance = "Move slightly further back"
            } else if !isCenteredX {
                specificGuidance = (diffX < 0) ? "Move face slightly right" : "Move face slightly left"
            } else if !isCenteredY {
                specificGuidance = (diffY < 0) ? "Move face higher in the oval" : "Move face lower in the oval"
            } else if isLookingFromBelow {
                specificGuidance = "Angle too low — hold camera straight at eye level"
            } else if isLookingFromAbove {
                specificGuidance = "Angle too high — hold camera straight at eye level"
            } else if !isRollOK {
                specificGuidance = "Keep your head straight and upright"
            } else if !isSymmetryOK || !isYawOK {
                specificGuidance = "Face the camera directly — do not turn sideways"
            }

            let effectivePitchDeg: Double = {
                if hasVisionPitch { return visionPitchDeg }
                if isLookingFromBelow { return 16.0 }
                if isLookingFromAbove { return -16.0 }
                return 0.0
            }()

            let eval = VisionFaceEvaluation(
                isFaceDetected: true,
                isFaceCentered: isCentered,
                isHeadPoseDirect: isPoseDirect,
                isFaceUnobstructed: (obstructionReason == nil),
                isBareFace: isBareFace,
                isUnevenlyLit: isUnevenlyLit,
                faceLuminance: computedFaceLuma,
                rollDegrees: rollDeg,
                yawDegrees: max(visionYawDeg, (1.0 - symmetryRatio) * 45.0),
                pitchDegrees: effectivePitchDeg,
                quality: face.faceCaptureQuality ?? 0.7,
                obstructionReason: obstructionReason,
                poseSpecificGuidance: specificGuidance
            )

            continuation.resume(returning: eval)
        }
    }

    // MARK: - Regional Pixel Inspection (Hand, Glasses, Mask, Hair Bangs, Makeup & Lighting Symmetry)

    private struct RegionalInspectionResult {
        let averageFaceLuminance: Double
        let isUnevenlyLit: Bool
        let isBareFace: Bool
        let obstructionMessage: String?
    }

    private struct PatchStats {
        let r: Double
        let g: Double
        let b: Double
        let luma: Double      // Normalized [0...1]
        let cb: Double        // YCbCr Blue-difference [0...255]
        let cr: Double        // YCbCr Red-difference [0...255]
        let stdDevLuma: Double
        let darkFraction: Double
        let brightFraction: Double

        var isPlausibleHumanSkin: Bool {
            // Human skin across all Fitzpatrick types in YCbCr and RGB
            let ycbcrOK = (cb >= 70.0 && cb <= 136.0) && (cr >= 129.0 && cr <= 182.0)
            let rgbOrderOK = (r > g * 0.94) && (r > b * 1.02)
            return ycbcrOK && rgbOrderOK && luma >= 0.14 && luma <= 0.95
        }
    }

    private static func inspectFacialRegions(
        in cgImage: CGImage,
        faceBox: CGRect,
        leftEye: [CGPoint],
        rightEye: [CGPoint],
        leftEyebrow: [CGPoint],
        rightEyebrow: [CGPoint],
        nose: [CGPoint],
        outerLips: [CGPoint],
        glassesClassifierConfidence: Float,
        maskClassifierConfidence: Float,
        handClassifierConfidence: Float
    ) -> RegionalInspectionResult {
        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)

        func toPixel(_ pt: CGPoint) -> CGPoint {
            let vx = faceBox.origin.x + pt.x * faceBox.width
            let vy = faceBox.origin.y + pt.y * faceBox.height
            return CGPoint(x: vx * imgW, y: (1.0 - vy) * imgH)
        }

        let leftEyeCenter = average(of: leftEye)
        let rightEyeCenter = average(of: rightEye)
        let leftBrowCenter = average(of: leftEyebrow)
        let rightBrowCenter = average(of: rightEyebrow)
        let noseCenter = average(of: nose)
        let lipCenter = average(of: outerLips)
        let noseMinY = nose.map(\.y).min() ?? noseCenter.y
        let lipMinY = outerLips.map(\.y).min() ?? (lipCenter.y - 0.04)
        let leftEyeMinY = leftEye.map(\.y).min() ?? (leftEyeCenter.y - 0.025)
        let rightEyeMinY = rightEye.map(\.y).min() ?? (rightEyeCenter.y - 0.025)
        let leftEyeInnerX = leftEye.map(\.x).max() ?? (leftEyeCenter.x + 0.05)
        let rightEyeInnerX = rightEye.map(\.x).min() ?? (rightEyeCenter.x - 0.05)

        // 1. Key anatomical sample coordinates
        let foreheadNorm = CGPoint(
            x: (leftBrowCenter.x + rightBrowCenter.x) * 0.5,
            y: min(0.91, ((leftBrowCenter.y + rightBrowCenter.y) * 0.5) + 0.11)
        )
        let leftCheekNorm = CGPoint(
            x: (leftEyeCenter.x * 0.55) + (noseCenter.x * 0.45),
            y: (leftEyeCenter.y * 0.40) + (noseMinY * 0.60)
        )
        let rightCheekNorm = CGPoint(
            x: (rightEyeCenter.x * 0.55) + (noseCenter.x * 0.45),
            y: (rightEyeCenter.y * 0.40) + (noseMinY * 0.60)
        )
        let chinNorm = CGPoint(
            x: lipCenter.x,
            y: max(0.07, lipMinY - 0.07)
        )

        // Narrow nasal bridge points strictly between inner eye corners (avoids eyelashes/canthus)
        let bridgeMidX = (leftEyeInnerX + rightEyeInnerX) * 0.5
        let bridgeMidY = (leftEyeCenter.y + rightEyeCenter.y) * 0.5
        let noseBridgeCenterNorm = CGPoint(x: bridgeMidX, y: bridgeMidY)
        let noseBridgeUpperNorm = CGPoint(x: bridgeMidX, y: bridgeMidY + 0.032)
        let noseBridgeLowerNorm = CGPoint(x: bridgeMidX, y: bridgeMidY - 0.032)

        // Under-eye orbital points (below eyelashes, where glasses lower rim / sunglasses lens sit)
        let underLeftEyeNorm = CGPoint(
            x: leftEyeCenter.x,
            y: (leftEyeMinY * 0.58) + (leftCheekNorm.y * 0.42)
        )
        let underRightEyeNorm = CGPoint(
            x: rightEyeCenter.x,
            y: (rightEyeMinY * 0.58) + (rightCheekNorm.y * 0.42)
        )

        let patchRadius = max(5.0, min(22.0, faceBox.width * imgW * 0.032))
        let innerEyeGapPx = max(8.0, abs(rightEyeInnerX - leftEyeInnerX) * faceBox.width * imgW)
        let bridgeRadius = max(3.5, min(10.0, innerEyeGapPx * 0.18))

        guard let forehead = samplePatchStats(in: cgImage, center: toPixel(foreheadNorm), radius: patchRadius),
              let leftCheek = samplePatchStats(in: cgImage, center: toPixel(leftCheekNorm), radius: patchRadius),
              let rightCheek = samplePatchStats(in: cgImage, center: toPixel(rightCheekNorm), radius: patchRadius),
              let chin = samplePatchStats(in: cgImage, center: toPixel(chinNorm), radius: patchRadius * 0.85),
              let noseTip = samplePatchStats(in: cgImage, center: toPixel(noseCenter), radius: patchRadius * 0.80),
              let lips = samplePatchStats(in: cgImage, center: toPixel(lipCenter), radius: patchRadius * 0.80),
              let leftEyePatch = samplePatchStats(in: cgImage, center: toPixel(leftEyeCenter), radius: patchRadius * 0.72),
              let rightEyePatch = samplePatchStats(in: cgImage, center: toPixel(rightEyeCenter), radius: patchRadius * 0.72),
              let nasalBridge = samplePatchStats(in: cgImage, center: toPixel(noseBridgeCenterNorm), radius: bridgeRadius),
              let bridgeUpper = samplePatchStats(in: cgImage, center: toPixel(noseBridgeUpperNorm), radius: bridgeRadius),
              let bridgeLower = samplePatchStats(in: cgImage, center: toPixel(noseBridgeLowerNorm), radius: bridgeRadius),
              let underLeftEye = samplePatchStats(in: cgImage, center: toPixel(underLeftEyeNorm), radius: patchRadius * 0.65),
              let underRightEye = samplePatchStats(in: cgImage, center: toPixel(underRightEyeNorm), radius: patchRadius * 0.65) else {
            return RegionalInspectionResult(
                averageFaceLuminance: 0.5,
                isUnevenlyLit: false,
                isBareFace: true,
                obstructionMessage: nil
            )
        }

        let cheekLuma = (leftCheek.luma + rightCheek.luma) * 0.5
        let cheekCr = (leftCheek.cr + rightCheek.cr) * 0.5
        let cheekCb = (leftCheek.cb + rightCheek.cb) * 0.5
        let avgFaceLuma = (cheekLuma * 0.55) + (forehead.luma * 0.25) + (chin.luma * 0.20)

        // Check bilateral lighting symmetry (only flag strong one-sided shadow)
        let isUnevenlyLit = abs(leftCheek.luma - rightCheek.luma) > 0.25

        // A1. Check Skin-Colored Hand / Finger Occlusion (requires strong evidence to avoid false alarms on natural features)
        let leftEyeLooksLikeSkinCover = (leftEyePatch.luma > cheekLuma * 0.92 && leftEyePatch.stdDevLuma < 0.032)
            || leftEyePatch.stdDevLuma < 0.024
        let rightEyeLooksLikeSkinCover = (rightEyePatch.luma > cheekLuma * 0.92 && rightEyePatch.stdDevLuma < 0.032)
            || rightEyePatch.stdDevLuma < 0.024

        let cheekLumaAsymmetry = abs(leftCheek.luma - rightCheek.luma)
        let cheekStdDevAsymmetry = abs(leftCheek.stdDevLuma - rightCheek.stdDevLuma)
        let hasSharpObstructionEdge = leftCheek.stdDevLuma > 0.155
            || rightCheek.stdDevLuma > 0.155
            || forehead.stdDevLuma > 0.165
            || chin.stdDevLuma > 0.165
        let hasUnilateralCheekCover = (cheekLumaAsymmetry > 0.24 && cheekStdDevAsymmetry > 0.075)
            || (!leftCheek.isPlausibleHumanSkin && cheekLumaAsymmetry > 0.18)
            || (!rightCheek.isPlausibleHumanSkin && cheekLumaAsymmetry > 0.18)

        if leftEyeLooksLikeSkinCover || rightEyeLooksLikeSkinCover || hasSharpObstructionEdge || hasUnilateralCheekCover || handClassifierConfidence >= 0.55 {
            return RegionalInspectionResult(
                averageFaceLuminance: avgFaceLuma,
                isUnevenlyLit: isUnevenlyLit,
                isBareFace: true,
                obstructionMessage: "Hand or object covering face — keep face completely clear"
            )
        }

        // A2. Check Mask / Non-Skin Object Covering Lower Face (Nose, Mouth, or Chin)
        let lowerFaceColorDiff = hypot(chin.cr - cheekCr, chin.cb - cheekCb)
        let noseColorDiff = hypot(noseTip.cr - cheekCr, noseTip.cb - cheekCb)
        let lowerFaceLumaDiff = abs(chin.luma - cheekLuma)
        let isMaskCoveringLowerFace = (!chin.isPlausibleHumanSkin && lowerFaceColorDiff > 12.0)
            || (!noseTip.isPlausibleHumanSkin && noseColorDiff > 12.0)
            || lowerFaceColorDiff > 15.0
            || noseColorDiff > 15.0
            || lowerFaceLumaDiff > 0.25
            || (maskClassifierConfidence >= 0.24 && (lowerFaceColorDiff > 10.0 || !chin.isPlausibleHumanSkin))

        if isMaskCoveringLowerFace {
            return RegionalInspectionResult(
                averageFaceLuminance: avgFaceLuma,
                isUnevenlyLit: isUnevenlyLit,
                isBareFace: true,
                obstructionMessage: "Face covered — remove mask, hand, or object"
            )
        }

        // B. Check Eyeglasses / Sunglasses (Zero-False-Positive Multi-Factor Verification)
        // 1. Sunglasses: both under-eye orbital zones are covered by dark non-skin lenses
        let isDarkSunglasses = !underLeftEye.isPlausibleHumanSkin
            && !underRightEye.isPlausibleHumanSkin
            && underLeftEye.luma < cheekLuma * 0.52
            && underRightEye.luma < cheekLuma * 0.52

        // 2. Horizontal frame bridge bar step across the narrow nasal bridge strip
        let bridgeNeighborLuma = (bridgeUpper.luma + bridgeLower.luma) * 0.5
        let bridgeVerticalStep = abs(nasalBridge.luma - bridgeNeighborLuma)
        let bridgeToNoseColorDiff = hypot(nasalBridge.cr - noseTip.cr, nasalBridge.cb - noseTip.cb)

        let hasDistinctBridgeBar = (!nasalBridge.isPlausibleHumanSkin && (bridgeVerticalStep > 0.14 || bridgeToNoseColorDiff > 16.0 || nasalBridge.darkFraction > 0.42))
            || (bridgeVerticalStep > 0.20 && nasalBridge.stdDevLuma > 0.13)

        let hasBilateralUnderEyeRim = (underLeftEye.stdDevLuma > 0.135 && underRightEye.stdDevLuma > 0.135)
            && ((underLeftEye.darkFraction > 0.30 && underRightEye.darkFraction > 0.30)
                || (!underLeftEye.isPlausibleHumanSkin && !underRightEye.isPlausibleHumanSkin))

        // Require either dark sunglasses, strong physical frame across both bridge + rims, or Vision classifier + physical frame confirmation
        let isWearingGlasses = isDarkSunglasses
            || (hasDistinctBridgeBar && hasBilateralUnderEyeRim)
            || (glassesClassifierConfidence >= 0.26 && (hasDistinctBridgeBar || hasBilateralUnderEyeRim || nasalBridge.stdDevLuma > 0.125))

        if isWearingGlasses {
            return RegionalInspectionResult(
                averageFaceLuminance: avgFaceLuma,
                isUnevenlyLit: isUnevenlyLit,
                isBareFace: true,
                obstructionMessage: "Glasses detected — please remove eyewear"
            )
        }

        // C. Check Hair / Bangs Covering Forehead or Cheeks
        let foreheadToCheekLumaDiff = cheekLuma - forehead.luma
        let foreheadColorDiff = hypot(forehead.cr - cheekCr, forehead.cb - cheekCb)
        let hairOnForehead = (!forehead.isPlausibleHumanSkin && (foreheadToCheekLumaDiff > 0.18 || forehead.darkFraction > 0.35 || foreheadColorDiff > 15.0))
            || forehead.darkFraction > 0.48
            || foreheadToCheekLumaDiff > 0.30
        let hairOnCheeks = (!leftCheek.isPlausibleHumanSkin && leftCheek.darkFraction > 0.32)
            || (!rightCheek.isPlausibleHumanSkin && rightCheek.darkFraction > 0.32)

        if hairOnForehead || hairOnCheeks {
            return RegionalInspectionResult(
                averageFaceLuminance: avgFaceLuma,
                isUnevenlyLit: isUnevenlyLit,
                isBareFace: true,
                obstructionMessage: "Hair covering face — tie or pull hair back"
            )
        }

        // D. Check Bare Face (No Heavy Lipstick or Blush Makeup)
        let lipRednessDelta = lips.cr - cheekCr
        let cheekToForeheadRednessDelta = cheekCr - ((forehead.cr + chin.cr) * 0.5)
        let hasHeavyMakeup = (lipRednessDelta > 30.0) || (cheekToForeheadRednessDelta > 16.0)

        return RegionalInspectionResult(
            averageFaceLuminance: avgFaceLuma,
            isUnevenlyLit: isUnevenlyLit,
            isBareFace: !hasHeavyMakeup,
            obstructionMessage: hasHeavyMakeup ? "Makeup detected — please scan with a bare face" : nil
        )
    }

    private static func samplePatchStats(in cgImage: CGImage, center: CGPoint, radius: CGFloat) -> PatchStats? {
        let bounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let rawRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        let rect = rawRect.intersection(bounds)
        guard !rect.isNull, rect.width >= 2, rect.height >= 2,
              let cropped = cgImage.cropping(to: rect) else { return nil }

        let w = cropped.width
        let h = cropped.height
        let count = w * h
        guard count > 0 else { return nil }

        var raw = [UInt8](repeating: 0, count: count * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let ctx = CGContext(
            data: &raw,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: w, height: h))

        var sumR = 0.0
        var sumG = 0.0
        var sumB = 0.0
        var sumLuma = 0.0
        var lumas: [Double] = []
        lumas.reserveCapacity(count)
        var darkCount = 0
        var brightCount = 0

        for i in 0..<count {
            let r = Double(raw[i * 4])
            let g = Double(raw[i * 4 + 1])
            let b = Double(raw[i * 4 + 2])
            let y = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0

            sumR += r
            sumG += g
            sumB += b
            sumLuma += y
            lumas.append(y)

            if y < 0.25 { darkCount += 1 }
            if y > 0.88 { brightCount += 1 }
        }

        let n = Double(count)
        let meanR = sumR / n
        let meanG = sumG / n
        let meanB = sumB / n
        let meanLuma = sumLuma / n

        var varianceSum = 0.0
        for y in lumas {
            let d = y - meanLuma
            varianceSum += d * d
        }
        let stdDev = sqrt(varianceSum / n)

        let cb = 128.0 - (0.168736 * meanR) - (0.331264 * meanG) + (0.500000 * meanB)
        let cr = 128.0 + (0.500000 * meanR) - (0.418688 * meanG) - (0.081312 * meanB)

        return PatchStats(
            r: meanR,
            g: meanG,
            b: meanB,
            luma: meanLuma,
            cb: cb,
            cr: cr,
            stdDevLuma: stdDev,
            darkFraction: Double(darkCount) / n,
            brightFraction: Double(brightCount) / n
        )
    }

    // MARK: - Luminance Calculation Helpers

    private func calculateLuminance(from sampleBuffer: CMSampleBuffer) -> Double {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return 0.5
        }
        return calculateLuminanceFromPixelBuffer(pixelBuffer)
    }

    private func calculateLuminanceFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        if CVPixelBufferIsPlanar(pixelBuffer) && CVPixelBufferGetPlaneCount(pixelBuffer) >= 1 {
            guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return 0.5 }
            let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
            let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)

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

    private static func calculateLuminanceFromCGImage(_ cgImage: CGImage) -> Double {
        let w = min(64, cgImage.width)
        let h = min(64, cgImage.height)
        guard w > 0, h > 0 else { return 0.5 }
        var raw = [UInt8](repeating: 0, count: w * h * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let ctx = CGContext(
            data: &raw,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return 0.5 }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        var sum = 0.0
        let total = w * h
        for i in 0..<total {
            let r = Double(raw[i * 4])
            let g = Double(raw[i * 4 + 1])
            let b = Double(raw[i * 4 + 2])
            sum += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        }
        return sum / Double(total)
    }

    #if canImport(UIKit)
    private static func normalizedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cg = image.cgImage {
            return cg
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return rendered.cgImage
    }
    #endif

    private func averagePoint(of points: [CGPoint]) -> CGPoint {
        Self.average(of: points)
    }

    private static func average(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sumX = points.reduce(CGFloat.zero) { $0 + $1.x }
        let sumY = points.reduce(CGFloat.zero) { $0 + $1.y }
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
}
