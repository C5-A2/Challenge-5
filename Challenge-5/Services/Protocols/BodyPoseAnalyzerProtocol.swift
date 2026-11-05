//
//  BodyPoseAnalyzerProtocol.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

/// A single anatomical joint detected by Apple Vision Framework.
public struct DetectedBodyJoint: Sendable {
    public let name: VNHumanBodyPoseObservation.JointName
    /// Normalized point in UIKit coordinates: (0,0) is top-left, (1,1) is bottom-right.
    public let normalizedLocation: CGPoint
    public let confidence: Float

    public init(name: VNHumanBodyPoseObservation.JointName, normalizedLocation: CGPoint, confidence: Float) {
        self.name = name
        self.normalizedLocation = normalizedLocation
        self.confidence = confidence
    }
}

/// Comprehensive output from 2D human body pose estimation.
public struct PoseAnalysisResult: Sendable {
    public let joints: [VNHumanBodyPoseObservation.JointName: DetectedBodyJoint]
    public let headTopUIKitY: Double
    public let feetBottomUIKitY: Double
    public let personHeightPx: Double
    public let chestLevelUIKitY: Double
    public let waistLevelUIKitY: Double
    public let hipLevelUIKitY: Double
    public let shoulderWidthPx: Double?
    public let averageConfidence: Float
    public let isFullBodyDetected: Bool
    public let warnings: [String]

    public init(
        joints: [VNHumanBodyPoseObservation.JointName: DetectedBodyJoint],
        headTopUIKitY: Double,
        feetBottomUIKitY: Double,
        personHeightPx: Double,
        chestLevelUIKitY: Double,
        waistLevelUIKitY: Double,
        hipLevelUIKitY: Double,
        shoulderWidthPx: Double?,
        averageConfidence: Float,
        isFullBodyDetected: Bool,
        warnings: [String]
    ) {
        self.joints = joints
        self.headTopUIKitY = headTopUIKitY
        self.feetBottomUIKitY = feetBottomUIKitY
        self.personHeightPx = personHeightPx
        self.chestLevelUIKitY = chestLevelUIKitY
        self.waistLevelUIKitY = waistLevelUIKitY
        self.hipLevelUIKitY = hipLevelUIKitY
        self.shoulderWidthPx = shoulderWidthPx
        self.averageConfidence = averageConfidence
        self.isFullBodyDetected = isFullBodyDetected
        self.warnings = warnings
    }
}

/// Service protocol for Apple Vision Framework human body pose detection (C5-92).
public protocol BodyPoseAnalyzerProtocol: Sendable {
    #if canImport(UIKit)
    func analyzePose(image: UIImage) async throws -> PoseAnalysisResult
    #endif
}
