//
//  BodyClassifier.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation

/// Deterministic anthropometric ratio classifier for body shape and torso proportion (C5-94).
///
/// Implements academic morphotype classification criteria (Pandarum et al., 2020) using
/// Bust-to-Waist (B/W), Hip-to-Waist (H/W), and Shoulder-to-Hip ratios to categorize:
/// 1. Primary Body Shape: `Hourglass`, `Pear`, `Rectangle`, `Inverted Triangle`, `Apple`.
/// 2. Vertical Torso Proportion: `Short Torso`, `Balanced`, `Long Torso` via Torso-to-Height Ratio (THR).
public final class BodyClassifier: BodyClassifierProtocol, Sendable {

    public init() {}

    // MARK: - Protocol Implementation

    public func classify(
        bustCm: Double,
        waistCm: Double,
        hipCm: Double,
        shoulderWidthCm: Double? = nil,
        enteredHeightCm: Double = 170.0,
        torsoLengthCm: Double? = nil
    ) -> BodyClassificationResult {
        Self.classify(
            bustCm: bustCm,
            waistCm: waistCm,
            hipCm: hipCm,
            shoulderWidthCm: shoulderWidthCm,
            enteredHeightCm: enteredHeightCm,
            torsoLengthCm: torsoLengthCm
        )
    }

    // MARK: - Static Classification Method

    public static func classify(
        bustCm: Double,
        waistCm: Double,
        hipCm: Double,
        shoulderWidthCm: Double? = nil,
        enteredHeightCm: Double = 170.0,
        torsoLengthCm: Double? = nil
    ) -> BodyClassificationResult {
        let safeWaist = max(10.0, waistCm)
        let safeBust = max(10.0, bustCm)
        let safeHip = max(10.0, hipCm)
        let safeHeight = max(100.0, enteredHeightCm)

        // 1. Compute Primary Ratios
        let bRatio = safeBust / safeWaist
        let hRatio = safeHip / safeWaist

        var shoulderToHipRatio: Double? = nil
        if let shoulder = shoulderWidthCm, shoulder > 0 {
            // Approximate transverse hip diameter from hip circumference (C / π)
            let estimatedHipDiameter = safeHip / Double.pi
            if estimatedHipDiameter > 0 {
                shoulderToHipRatio = shoulder / estimatedHipDiameter
            }
        }

        // 2. Classify Body Shape using exact deterministic anthropometric ratios
        let bodyType: BodyType
        let confidence: Float

        if bRatio > 1.24 && hRatio > 1.20 {
            bodyType = .hourglass
            confidence = 0.95
        } else if hRatio > 1.22 && bRatio <= 1.22 {
            bodyType = .pear
            confidence = 0.94
        } else if bRatio > 1.24 && hRatio <= 1.15 {
            bodyType = .invertedTriangle
            confidence = 0.93
        } else if bRatio < 1.18 && hRatio < 1.18 {
            bodyType = .rectangle
            confidence = 0.91
        } else {
            bodyType = .apple
            confidence = 0.88
        }

        // 3. Classify Torso Balance via Torso-to-Height Ratio (THR)
        let safeTorsoLength: Double
        if let torso = torsoLengthCm, torso > 0 {
            safeTorsoLength = torso
        } else {
            // Standard anthropometric proportion baseline (~31.5% of total height)
            safeTorsoLength = safeHeight * 0.315
        }

        let thr = (safeTorsoLength / safeHeight) * 100.0
        let torsoBalance = TorsoBalance.classify(torsoToHeightRatio: thr)

        // 4. Generate Rationale & Explanations
        let explanation = generateExplanation(
            bodyType: bodyType,
            torsoBalance: torsoBalance,
            bRatio: bRatio,
            hRatio: hRatio,
            thr: thr
        )

        return BodyClassificationResult(
            bodyType: bodyType,
            torsoBalance: torsoBalance,
            bustToWaistRatio: round(bRatio * 100) / 100,
            hipToWaistRatio: round(hRatio * 100) / 100,
            shoulderToHipRatio: shoulderToHipRatio != nil ? round(shoulderToHipRatio! * 100) / 100 : nil,
            torsoToHeightRatio: round(thr * 10) / 10,
            confidence: confidence,
            explanation: explanation,
            actPrinciple: bodyType.actPrinciple
        )
    }

    // MARK: - Private Explanation Generator

    private static func generateExplanation(
        bodyType: BodyType,
        torsoBalance: TorsoBalance,
        bRatio: Double,
        hRatio: Double,
        thr: Double
    ) -> String {
        let bFormatted = String(format: "%.2f", bRatio)
        let hFormatted = String(format: "%.2f", hRatio)
        let thrFormatted = String(format: "%.1f", thr)

        var parts: [String] = []

        switch bodyType {
        case .hourglass:
            parts.append("Your bust (B/W \(bFormatted)) and hip (H/W \(hFormatted)) measurements are proportionally balanced around a well-defined waist.")
        case .pear:
            parts.append("Your hips (H/W \(hFormatted)) are proportionately wider than your upper body (B/W \(bFormatted)), paired with a defined waistline.")
        case .rectangle:
            parts.append("Your silhouette exhibits a straight, athletic proportion with balanced bust, waist, and hip ratios (B/W \(bFormatted), H/W \(hFormatted)).")
        case .invertedTriangle:
            parts.append("Your upper body and shoulders are noticeably broader relative to your narrower hips (B/W \(bFormatted), H/W \(hFormatted)).")
        case .apple:
            parts.append("Your midsection holds natural fullness with soft waist definition relative to your chest and hips (B/W \(bFormatted), H/W \(hFormatted)).")
        }

        parts.append("Your torso-to-height ratio is \(thrFormatted)%, indicating a \(torsoBalance.rawValue) silhouette (\(torsoBalance.thrThresholdDescription)).")

        return parts.joined(separator: " ")
    }
}
