//
//  BodyClassifierProtocol.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation

/// Comprehensive output from body shape and torso balance ratio classification (C5-94).
public struct BodyClassificationResult: Sendable, Equatable {
    /// Classified primary body morphotype.
    public let bodyType: BodyType
    /// Classified vertical torso proportion.
    public let torsoBalance: TorsoBalance

    /// Bust-to-Waist ratio (B/W).
    public let bustToWaistRatio: Double
    /// Hip-to-Waist ratio (H/W).
    public let hipToWaistRatio: Double
    /// Optional Shoulder-to-Hip ratio (S/H).
    public let shoulderToHipRatio: Double?
    /// Torso-to-Height Ratio (THR) percentage.
    public let torsoToHeightRatio: Double

    /// Confidence score (0.0 to 1.0) of the classification.
    public let confidence: Float
    /// Summary explanation of anatomical proportions and visual characteristics.
    public let explanation: String
    /// Recommended styling principle (Act) for silhouette balancing.
    public let actPrinciple: String

    public init(
        bodyType: BodyType,
        torsoBalance: TorsoBalance,
        bustToWaistRatio: Double,
        hipToWaistRatio: Double,
        shoulderToHipRatio: Double?,
        torsoToHeightRatio: Double,
        confidence: Float,
        explanation: String,
        actPrinciple: String
    ) {
        self.bodyType = bodyType
        self.torsoBalance = torsoBalance
        self.bustToWaistRatio = bustToWaistRatio
        self.hipToWaistRatio = hipToWaistRatio
        self.shoulderToHipRatio = shoulderToHipRatio
        self.torsoToHeightRatio = torsoToHeightRatio
        self.confidence = confidence
        self.explanation = explanation
        self.actPrinciple = actPrinciple
    }
}

/// Service protocol for deterministic body shape and torso balance classification (C5-94).
public protocol BodyClassifierProtocol: Sendable {
    func classify(
        bustCm: Double,
        waistCm: Double,
        hipCm: Double,
        shoulderWidthCm: Double?,
        enteredHeightCm: Double,
        torsoLengthCm: Double?
    ) -> BodyClassificationResult
}
