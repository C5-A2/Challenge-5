//
//  BodyPoseAnalyzer.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

/// Vision Framework human body pose landmark estimator (C5-92).
///
/// Detects 19 key anatomical landmarks (shoulders, neck, hips, knees, ankles)
/// from front and side photos using `VNDetectHumanBodyPoseRequest`,
/// evaluates vertical anatomical landmark levels, and maps cross-sectional height slices.
public final class BodyPoseAnalyzer: BodyPoseAnalyzerProtocol, Sendable {

    // MARK: - Initializer

    public init() {}

    // MARK: - Protocol Implementation

    #if canImport(UIKit)
    /// Performs 2D body pose landmark extraction on a full-body photograph.
    public func analyzePose(image: UIImage) async throws -> PoseAnalysisResult {
        try await Self.analyzePoseInternal(image: image)
    }

    /// Static convenience method for direct invocation without instance management.
    public static func analyzePose(image: UIImage) async throws -> PoseAnalysisResult {
        try await analyzePoseInternal(image: image)
    }

    private static func analyzePoseInternal(image: UIImage) async throws -> PoseAnalysisResult {
        let fixedImage = fixOrientation(image: image)
        guard let cgImage = fixedImage.cgImage else {
            throw NSError(
                domain: "BodyPoseAnalyzer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to extract CGImage from photo."]
            )
        }

        let imageWidth = Double(cgImage.width)
        let imageHeight = Double(cgImage.height)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNHumanBodyPoseObservation],
                      let observation = observations.first else {
                    continuation.resume(throwing: NSError(
                        domain: "BodyPoseAnalyzer",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "No person detected in the photo. Please ensure full body is visible within the frame."]
                    ))
                    return
                }

                do {
                    let result = try processObservation(
                        observation,
                        imageWidth: imageWidth,
                        imageHeight: imageHeight
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Observation Processing

    private static func processObservation(
        _ observation: VNHumanBodyPoseObservation,
        imageWidth: Double,
        imageHeight: Double
    ) throws -> PoseAnalysisResult {
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .neck, .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow, .leftWrist, .rightWrist,
            .leftHip, .rightHip, .root,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]

        var joints: [VNHumanBodyPoseObservation.JointName: DetectedBodyJoint] = [:]
        var totalConfidence: Float = 0
        var count: Float = 0

        for name in jointNames {
            if let recognizedPoint = try? observation.recognizedPoint(name), recognizedPoint.confidence > 0.1 {
                // Convert Vision normalized point (0,0 bottom-left) to UIKit point (0,0 top-left)
                let uikitPoint = visionToUIKit(point: recognizedPoint.location)
                joints[name] = DetectedBodyJoint(
                    name: name,
                    normalizedLocation: uikitPoint,
                    confidence: recognizedPoint.confidence
                )
                totalConfidence += recognizedPoint.confidence
                count += 1
            }
        }

        var warnings: [String] = []
        let avgConfidence = count > 0 ? (totalConfidence / count) : 0

        // Find landmark references
        let leftShoulder = joints[.leftShoulder]
        let rightShoulder = joints[.rightShoulder]
        let neck = joints[.neck]
        let nose = joints[.nose]

        let leftHip = joints[.leftHip]
        let rightHip = joints[.rightHip]
        let root = joints[.root]

        let leftAnkle = joints[.leftAnkle]
        let rightAnkle = joints[.rightAnkle]

        // 1. Evaluate Shoulder Level Y
        let shoulderY: Double
        if let ls = leftShoulder, let rs = rightShoulder {
            shoulderY = Double(ls.normalizedLocation.y + rs.normalizedLocation.y) / 2.0
        } else if let s = leftShoulder ?? rightShoulder {
            shoulderY = Double(s.normalizedLocation.y)
        } else if let n = neck {
            shoulderY = Double(n.normalizedLocation.y) + 0.05
            warnings.append("Shoulder landmarks uncertain; estimated from neck position.")
        } else {
            shoulderY = 0.25
            warnings.append("Upper torso landmarks weak.")
        }

        // 2. Evaluate Hip Level Y
        let hipY: Double
        if let lh = leftHip, let rh = rightHip {
            hipY = Double(lh.normalizedLocation.y + rh.normalizedLocation.y) / 2.0
        } else if let h = leftHip ?? rightHip {
            hipY = Double(h.normalizedLocation.y)
        } else if let r = root {
            hipY = Double(r.normalizedLocation.y)
        } else {
            hipY = shoulderY + 0.30
            warnings.append("Pelvis / hip landmarks uncertain; estimated from torso ratio.")
        }

        let torsoHeight = max(0.15, hipY - shoulderY)

        // 3. Anatomical Level Slices
        // Chest level: ~25% down the torso from shoulders
        let chestLevelUIKitY = shoulderY + (torsoHeight * 0.25)

        // Waist level: ~60% down the torso from shoulders (narrowest region between ribcage and pelvis)
        let waistLevelUIKitY = shoulderY + (torsoHeight * 0.60)

        // Hip level: apex of pelvis / greater trochanter (~16% of torso height below hip joints)
        let hipLevelUIKitY = hipY + (torsoHeight * 0.16)

        // 4. Head Top Estimation
        let headTopUIKitY: Double
        if let n = nose, let nk = neck {
            let headSpan = max(0.04, Double(nk.normalizedLocation.y - n.normalizedLocation.y))
            headTopUIKitY = max(0.01, Double(n.normalizedLocation.y) - (headSpan * 1.2))
        } else if let n = nose {
            headTopUIKitY = max(0.01, Double(n.normalizedLocation.y) - 0.08)
        } else if let nk = neck {
            headTopUIKitY = max(0.01, Double(nk.normalizedLocation.y) - 0.16)
        } else {
            headTopUIKitY = max(0.01, shoulderY - 0.18)
            warnings.append("Head top landmark uncertain.")
        }

        // 5. Feet Bottom Estimation
        let feetBottomUIKitY: Double
        if let la = leftAnkle, let ra = rightAnkle {
            let maxAnkleY = max(Double(la.normalizedLocation.y), Double(ra.normalizedLocation.y))
            feetBottomUIKitY = min(0.99, maxAnkleY + 0.035) // Include foot shoe sole
        } else if let a = leftAnkle ?? rightAnkle {
            feetBottomUIKitY = min(0.99, Double(a.normalizedLocation.y) + 0.035)
        } else if let k = joints[.leftKnee] ?? joints[.rightKnee] {
            feetBottomUIKitY = min(0.99, Double(k.normalizedLocation.y) + 0.25)
            warnings.append("Ankles not detected; full body may be cut off at the bottom.")
        } else {
            feetBottomUIKitY = 0.98
            warnings.append("Lower body landmarks not detected; please ensure feet are in frame.")
        }

        let totalNormalizedHeight = max(0.3, feetBottomUIKitY - headTopUIKitY)
        let personHeightPx = totalNormalizedHeight * imageHeight

        // 6. Compute Shoulder Width if both joints detected
        var shoulderWidthPx: Double? = nil
        if let ls = leftShoulder, let rs = rightShoulder {
            let dx = Double(abs(ls.normalizedLocation.x - rs.normalizedLocation.x)) * imageWidth
            shoulderWidthPx = dx
        }

        let hasUpper = (leftShoulder != nil || rightShoulder != nil || neck != nil)
        let hasMid = (leftHip != nil || rightHip != nil)
        let hasLower = (leftAnkle != nil || rightAnkle != nil || joints[.leftKnee] != nil || joints[.rightKnee] != nil)
        let isFullBody = hasUpper && hasMid && hasLower

        if !isFullBody {
            throw NSError(
                domain: "BodyPoseAnalyzer",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Pastikan seluruh tubuh terlihat dari kepala hingga kaki, bukan selfie atau setengah badan."]
            )
        }

        return PoseAnalysisResult(
            joints: joints,
            headTopUIKitY: headTopUIKitY,
            feetBottomUIKitY: feetBottomUIKitY,
            personHeightPx: personHeightPx,
            chestLevelUIKitY: chestLevelUIKitY,
            waistLevelUIKitY: waistLevelUIKitY,
            hipLevelUIKitY: hipLevelUIKitY,
            shoulderWidthPx: shoulderWidthPx,
            averageConfidence: avgConfidence,
            isFullBodyDetected: isFullBody,
            warnings: warnings
        )
    }

    // MARK: - Anatomical Vertical Coordinate Mapping

    /// Maps a vertical coordinate (Y) from the front photo to the corresponding anatomical height on the side photo.
    /// Accounts for variations in distance to camera and framing between front and side captures.
    public static func mapFrontYToSideY(
        frontY: Double,
        frontPose: PoseAnalysisResult,
        sidePose: PoseAnalysisResult?
    ) -> Double {
        guard let sPose = sidePose else {
            return frontY
        }

        let fJoints = frontPose.joints
        let sJoints = sPose.joints

        // Front shoulder Y
        let fLS = fJoints[.leftShoulder]?.normalizedLocation
        let fRS = fJoints[.rightShoulder]?.normalizedLocation
        let fShoulderY: Double
        if let ls = fLS, let rs = fRS {
            fShoulderY = Double(ls.y + rs.y) / 2.0
        } else if let s = fLS ?? fRS {
            fShoulderY = Double(s.y)
        } else {
            fShoulderY = frontPose.chestLevelUIKitY - 0.05
        }

        // Front hip Y
        let fLH = fJoints[.leftHip]?.normalizedLocation
        let fRH = fJoints[.rightHip]?.normalizedLocation
        let fHipY: Double
        if let lh = fLH, let rh = fRH {
            fHipY = Double(lh.y + rh.y) / 2.0
        } else if let h = fLH ?? fRH {
            fHipY = Double(h.y)
        } else {
            fHipY = frontPose.hipLevelUIKitY - 0.02
        }

        let fTorsoHeight = max(0.08, fHipY - fShoulderY)

        // Side shoulder Y
        let sLS = sJoints[.leftShoulder]?.normalizedLocation
        let sRS = sJoints[.rightShoulder]?.normalizedLocation
        let sShoulderY: Double
        if let ls = sLS, let rs = sRS {
            sShoulderY = Double(ls.y + rs.y) / 2.0
        } else if let s = sLS ?? sRS {
            sShoulderY = Double(s.y)
        } else {
            sShoulderY = sPose.chestLevelUIKitY - 0.05
        }

        // Side hip Y
        let sLH = sJoints[.leftHip]?.normalizedLocation
        let sRH = sJoints[.rightHip]?.normalizedLocation
        let sHipY: Double
        if let lh = sLH, let rh = sRH {
            sHipY = Double(lh.y + rh.y) / 2.0
        } else if let h = sLH ?? sRH {
            sHipY = Double(h.y)
        } else {
            sHipY = sPose.hipLevelUIKitY - 0.02
        }

        let sTorsoHeight = max(0.08, sHipY - sShoulderY)

        // Proportionally map within anatomical torso region
        if frontY >= (fShoulderY - 0.08) && frontY <= (fHipY + 0.25) {
            let torsoFraction = (frontY - fShoulderY) / fTorsoHeight
            let sideY = sShoulderY + (torsoFraction * sTorsoHeight)
            return min(0.98, max(0.02, sideY))
        }

        // Fallback proportional mapping across full body height
        let fTotalHeight = max(0.20, frontPose.feetBottomUIKitY - frontPose.headTopUIKitY)
        let sTotalHeight = max(0.20, sPose.feetBottomUIKitY - sPose.headTopUIKitY)

        let bodyFraction = (frontY - frontPose.headTopUIKitY) / fTotalHeight
        let sideY = sPose.headTopUIKitY + (bodyFraction * sTotalHeight)
        return min(0.98, max(0.02, sideY))
    }

    // MARK: - Orientation & Coordinate Helpers

    private static func fixOrientation(image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalized ?? image
    }

    private static func visionToUIKit(point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: 1.0 - point.y)
    }
    #endif
}
