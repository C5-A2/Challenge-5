//
//  HumanDetector.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

/// Classification of human body facing angle orientation.
public enum BodyFacingOrientation: String, Sendable, CaseIterable {
    case front = "Front"
    case side = "Side"
    case uncertain = "Uncertain"
}

/// Verification result of human presence, full body framing, and facing angle orientation.
public struct HumanDetectionResult: Sendable {
    public let isHumanPresent: Bool
    public let isFullBody: Bool
    public let orientation: BodyFacingOrientation
    public let isOrientationMatch: Bool
    public let message: String
    public let confidence: Float

    public init(
        isHumanPresent: Bool,
        isFullBody: Bool,
        orientation: BodyFacingOrientation,
        isOrientationMatch: Bool,
        message: String,
        confidence: Float
    ) {
        self.isHumanPresent = isHumanPresent
        self.isFullBody = isFullBody
        self.orientation = orientation
        self.isOrientationMatch = isOrientationMatch
        self.message = message
        self.confidence = confidence
    }
}

/// Vision-based human presence, full-body validation, and orientation detection service.
///
/// Implements pre-analysis validation to reject selfies, close-ups, half-body shots,
/// and misaligned postures before passing photos to segmentation and dimensional estimators.
public struct HumanDetector: Sendable {

    #if canImport(UIKit)
    /// Performs human presence, full-body visibility, and angle orientation verification on an image.
    public static func detectHuman(
        image: UIImage,
        expectedType: BodyFacingOrientation
    ) async -> HumanDetectionResult {
        let fixedImage = ImageOrientationHelper.fixOrientation(image: image)
        guard let cgImage = fixedImage.cgImage else {
            return HumanDetectionResult(
                isHumanPresent: false,
                isFullBody: false,
                orientation: .uncertain,
                isOrientationMatch: false,
                message: "Gagal memproses orientasi gambar.",
                confidence: 0
            )
        }

        // 1. Ekstraksi koordinat sendi tubuh (Skeletal Landmarks)
        let joints = await extractBodyJoints(cgImage: cgImage)

        // 2. Deteksi Bounding Box Manusia
        let humanRectangles = await detectHumanRectangles(cgImage: cgImage)

        let hasJoints = (joints != nil && !joints!.isEmpty)
        let hasBoundingBox = !humanRectangles.isEmpty

        // Jika tidak ada manusia sama sekali
        guard hasJoints || hasBoundingBox else {
            return HumanDetectionResult(
                isHumanPresent: false,
                isFullBody: false,
                orientation: .uncertain,
                isOrientationMatch: false,
                message: "Tidak ada orang yang terdeteksi di dalam foto.",
                confidence: 0
            )
        }

        guard let joints = joints else {
            return HumanDetectionResult(
                isHumanPresent: true,
                isFullBody: false,
                orientation: .uncertain,
                isOrientationMatch: false,
                message: "Kerangka tubuh tidak terdeteksi jelas. Pastikan seluruh tubuh terlihat dari kepala hingga kaki.",
                confidence: 0.1
            )
        }

        // 3. Validasi Full-Body (Eliminasi Selfie & Potongan Setengah Badan)
        let ls = joints[.leftShoulder]
        let rs = joints[.rightShoulder]
        let neck = joints[.neck]
        let nose = joints[.nose]

        let lh = joints[.leftHip]
        let rh = joints[.rightHip]
        let root = joints[.root]

        let lk = joints[.leftKnee]
        let rk = joints[.rightKnee]
        let la = joints[.leftAnkle]
        let ra = joints[.rightAnkle]

        let hasUpper = (ls?.confidence ?? 0 > 0.15) || (rs?.confidence ?? 0 > 0.15) || (neck?.confidence ?? 0 > 0.15) || (nose?.confidence ?? 0 > 0.15)
        let hasMid = (lh?.confidence ?? 0 > 0.15) || (rh?.confidence ?? 0 > 0.15) || (root?.confidence ?? 0 > 0.15)
        let hasLower = (la?.confidence ?? 0 > 0.15) || (ra?.confidence ?? 0 > 0.15) || (lk?.confidence ?? 0 > 0.15) || (rk?.confidence ?? 0 > 0.15)

        // Untuk pemindaian tubuh, kepala/leher, pinggul, dan kaki harus terdeteksi
        guard hasUpper && hasMid && hasLower else {
            return HumanDetectionResult(
                isHumanPresent: true,
                isFullBody: false,
                orientation: .uncertain,
                isOrientationMatch: false,
                message: "Pastikan seluruh tubuh terlihat dari kepala hingga kaki, bukan selfie atau setengah badan.",
                confidence: 0.25
            )
        }

        // 4. Klasifikasi Orientasi Sudut Hadap (Front vs Side)
        let orientation = classifyFacingOrientation(joints: joints)

        let confidences = joints.values.map { $0.confidence }
        let avgConfidence = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Float(confidences.count)

        // 5. Pencocokan dengan Sudut Hadap yang Diharapkan
        switch expectedType {
        case .front:
            if orientation == .front {
                return HumanDetectionResult(
                    isHumanPresent: true,
                    isFullBody: true,
                    orientation: .front,
                    isOrientationMatch: true,
                    message: "Foto tampak depan terverifikasi.",
                    confidence: avgConfidence
                )
            } else if orientation == .side {
                return HumanDetectionResult(
                    isHumanPresent: true,
                    isFullBody: true,
                    orientation: .side,
                    isOrientationMatch: false,
                    message: "Foto terdeteksi tampak samping. Mohon menghadap lurus ke kamera.",
                    confidence: avgConfidence
                )
            } else {
                return HumanDetectionResult(
                    isHumanPresent: true,
                    isFullBody: true,
                    orientation: .uncertain,
                    isOrientationMatch: false,
                    message: "Sudut hadap depan belum jelas. Pastikan berdiri tegak lurus menghadap kamera.",
                    confidence: avgConfidence
                )
            }

        case .side:
            if orientation == .side {
                return HumanDetectionResult(
                    isHumanPresent: true,
                    isFullBody: true,
                    orientation: .side,
                    isOrientationMatch: true,
                    message: "Foto tampak samping terverifikasi.",
                    confidence: avgConfidence
                )
            } else if orientation == .front {
                return HumanDetectionResult(
                    isHumanPresent: true,
                    isFullBody: true,
                    orientation: .front,
                    isOrientationMatch: false,
                    message: "Foto terdeteksi tampak depan. Mohon berputar 90° menghadap ke samping.",
                    confidence: avgConfidence
                )
            } else {
                return HumanDetectionResult(
                    isHumanPresent: true,
                    isFullBody: true,
                    orientation: .uncertain,
                    isOrientationMatch: false,
                    message: "Sudut hadap samping belum jelas. Pastikan berputar 90° menghadap ke samping profil.",
                    confidence: avgConfidence
                )
            }

        case .uncertain:
            return HumanDetectionResult(
                isHumanPresent: true,
                isFullBody: true,
                orientation: orientation,
                isOrientationMatch: true,
                message: "Sudut hadap: \(orientation.rawValue).",
                confidence: avgConfidence
            )
        }
    }

    // MARK: - Facing Orientation Classifier (CobaBodyScan Section 3.3)

    public static func classifyFacingOrientation(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> BodyFacingOrientation {
        let ls = joints[.leftShoulder]
        let rs = joints[.rightShoulder]
        let lh = joints[.leftHip]
        let rh = joints[.rightHip]

        let hasLeftShoulder = ls?.confidence ?? 0 > 0.18
        let hasRightShoulder = rs?.confidence ?? 0 > 0.18
        let hasBothShoulders = hasLeftShoulder && hasRightShoulder

        let hasLeftHip = lh?.confidence ?? 0 > 0.18
        let hasRightHip = rh?.confidence ?? 0 > 0.18
        let hasBothHips = hasLeftHip && hasRightHip

        // 1. Hitung perkiraan tinggi torso vertikal
        var torsoHeight = 0.25
        let shoulderY: Double? = {
            if hasBothShoulders, let ls = ls, let rs = rs {
                return Double(ls.location.y + rs.location.y) / 2.0
            } else if let s = (hasLeftShoulder ? ls : rs) {
                return Double(s.location.y)
            }
            return nil
        }()

        let hipY: Double? = {
            if hasBothHips, let lh = lh, let rh = rh {
                return Double(lh.location.y + rh.location.y) / 2.0
            } else if let h = (hasLeftHip ? lh : rh) {
                return Double(h.location.y)
            }
            return nil
        }()

        if let sy = shoulderY, let hy = hipY, abs(sy - hy) > 0.05 {
            torsoHeight = abs(sy - hy)
        }

        // 2. Hitung rasio rentang lebar bahu horizontal terhadap tinggi torso
        var shoulderRatio: Double = 0.0
        if hasBothShoulders, let ls = ls, let rs = rs {
            let dx = abs(Double(ls.location.x - rs.location.x))
            shoulderRatio = dx / torsoHeight
        }

        // 3. Hitung rasio rentang lebar pinggul horizontal terhadap tinggi torso
        var hipRatio: Double = 0.0
        if hasBothHips, let lh = lh, let rh = rh {
            let dx = abs(Double(lh.location.x - rh.location.x))
            hipRatio = dx / torsoHeight
        }

        // 4. Periksa fitur wajah
        let hasLeftEye = joints[.leftEye]?.confidence ?? 0 > 0.20
        let hasRightEye = joints[.rightEye]?.confidence ?? 0 > 0.20
        let hasBothEyes = hasLeftEye && hasRightEye
        let hasOnlyOneEye = (hasLeftEye && !hasRightEye) || (!hasLeftEye && hasRightEye)

        let hasLeftEar = joints[.leftEar]?.confidence ?? 0 > 0.20
        let hasRightEar = joints[.rightEar]?.confidence ?? 0 > 0.20
        let hasOnlyOneEar = (hasLeftEar && !hasRightEar) || (!hasLeftEar && hasRightEar)

        // KRITERIA KLASIFIKASI:
        // A. Indikator Kuat Tampak Depan
        if hasBothShoulders && shoulderRatio >= 0.38 && (hasBothEyes || hipRatio >= 0.24) {
            return .front
        }

        // B. Indikator Kuat Tampak Samping (Profil 90°)
        if shoulderRatio < 0.25 && (shoulderRatio > 0 || hasOnlyOneEye || hasOnlyOneEar) {
            return .side
        }
        if (!hasBothShoulders) && (hasOnlyOneEye || hasOnlyOneEar) {
            return .side
        }

        // C. Evaluasi Sekunder
        if hasBothShoulders && shoulderRatio >= 0.34 {
            return .front
        }
        if shoulderRatio < 0.28 && (hipRatio < 0.22 || hasOnlyOneEar) {
            return .side
        }

        return .uncertain
    }

    // MARK: - Private Vision Requests

    private static func detectHumanRectangles(cgImage: CGImage) async -> [VNHumanObservation] {
        await withCheckedContinuation { continuation in
            let request = VNDetectHumanRectanglesRequest { request, _ in
                let observations = request.results as? [VNHumanObservation] ?? []
                continuation.resume(returning: observations)
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    private static func extractBodyJoints(cgImage: CGImage) async -> [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]? {
        await withCheckedContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, _ in
                guard let observations = request.results as? [VNHumanBodyPoseObservation],
                      let observation = observations.first else {
                    continuation.resume(returning: nil)
                    return
                }

                var jointsDict: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]
                let jointNames: [VNHumanBodyPoseObservation.JointName] = [
                    .nose, .leftEye, .rightEye, .leftEar, .rightEar,
                    .neck, .leftShoulder, .rightShoulder,
                    .leftElbow, .rightElbow, .leftWrist, .rightWrist,
                    .leftHip, .rightHip, .root,
                    .leftKnee, .rightKnee,
                    .leftAnkle, .rightAnkle
                ]

                for name in jointNames {
                    if let point = try? observation.recognizedPoint(name) {
                        jointsDict[name] = point
                    }
                }
                continuation.resume(returning: jointsDict)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    #endif
}
