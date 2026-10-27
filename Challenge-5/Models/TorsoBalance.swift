//
//  TorsoBalance.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import Foundation

/// Vertical body proportion classification based on the Torso-to-Height Ratio (THR).
///
/// Standard formula: `THR = (Torso Length / Total Body Height) * 100%`
/// Measurement landmarks: C7 cervical vertebra / shoulder point to crotch / hip line.
///
/// Literature reference: Winter, D. A. (2009). Biomechanics and Motor Control of Human Movement.
public enum TorsoBalance: String, Codable, CaseIterable, Identifiable, Sendable {
    case shortTorso = "Short Torso"
    case balanced = "Balanced"
    case longTorso = "Long Torso"

    public var id: String { rawValue }

    // MARK: - Descriptive Properties

    /// Mathematical Torso-to-Height Ratio (THR) threshold bounds.
    public var thrThresholdDescription: String {
        switch self {
        case .shortTorso:
            return "THR < 30%"
        case .balanced:
            return "30% ≤ THR ≤ 33%"
        case .longTorso:
            return "THR > 33%"
        }
    }

    /// Anatomical definition and proportion explanation.
    public var definition: String {
        switch self {
        case .shortTorso:
            return "Upper torso is proportionately shorter relative to total body height, accompanied by longer legs."
        case .balanced:
            return "Natural balanced 1:1 proportion between the upper torso and leg length."
        case .longTorso:
            return "Upper torso is proportionately longer relative to total body height, with legs appearing shorter."
        }
    }

    /// Visual correction principle (Act) for silhouette balancing.
    public var actPrinciple: String {
        switch self {
        case .shortTorso:
            return "Visually lower the waistline to elongate the upper body silhouette and balance proportionately longer legs."
        case .balanced:
            return "Maintain the body's natural 1:1 proportion between the upper body and the legs."
        case .longTorso:
            return "Visually raise the waistline to shorten the appearance of a long torso and create the illusion of longer legs."
        }
    }

    // MARK: - Classification Helper

    /// Classify torso proportion from computed Torso-to-Height Ratio percentage.
    ///
    /// - Parameter torsoToHeightRatio: Ratio in percentage (e.g. 31.5 for 31.5%).
    /// - Returns: Corresponding `TorsoBalance` classification.
    public static func classify(torsoToHeightRatio: Double) -> TorsoBalance {
        if torsoToHeightRatio < 30.0 {
            return .shortTorso
        } else if torsoToHeightRatio <= 33.0 {
            return .balanced
        } else {
            return .longTorso
        }
    }
}
