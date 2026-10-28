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

    // MARK: - Display Name

    public var displayName: String {
        switch self {
        case .shortTorso:
            return "Short Torso"
        case .balanced:
            return "Balanced Torso"
        case .longTorso:
            return "Long Torso"
        }
    }

    // MARK: - Garment Ruleset Model

    /// Ruleset detailing garment recommendations and cuts for torso proportion balancing.
    public struct SuitableGarments: Sendable, Hashable, Codable {
        /// Recommended top garments, necklines, cuts, outerwear, and styling avoidances.
        public let top: String

        /// Recommended bottom garments, trousers, skirts, dresses, and styling avoidances.
        public let bottom: String

        public init(top: String, bottom: String) {
            self.top = top
            self.bottom = bottom
        }
    }

    // MARK: - Descriptive Properties & Ruleset

    /// Definition based on Torso-to-Height Ratio (THR) threshold bounds.
    public var definition: String {
        switch self {
        case .shortTorso:
            return "Torso-to-Height Ratio (THR) < 30%"
        case .balanced:
            return "30% ≤ Torso-to-Height Ratio (THR) ≤ 33%"
        case .longTorso:
            return "Torso-to-Height Ratio (THR) > 33%"
        }
    }

    /// Mathematical Torso-to-Height Ratio (THR) threshold bounds abbreviation (e.g. "THR < 30%").
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
    public var anatomicalDescription: String {
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
    public var act: String {
        switch self {
        case .shortTorso:
            return "Visually lower the waistline to elongate the upper body silhouette and balance proportionately longer legs."
        case .balanced:
            return "Maintain the body's natural 1:1 proportion between the upper body and the legs."
        case .longTorso:
            return "Visually raise the waistline to shorten the appearance of a long torso and create the illusion of longer legs."
        }
    }

    /// Visual correction principle (Act) for silhouette balancing (alias for `act`).
    public var actPrinciple: String {
        act
    }

    /// Suitable garments ruleset for upper and lower body.
    public var suitableGarments: SuitableGarments {
        switch self {
        case .shortTorso:
            return SuitableGarments(
                top: "Untucked tops, longline tops, tunics, curved-hem cuts, V-necklines, vertical stripes, and long outerwear (blazers or cardigans falling past the hip line). (Avoid: crop tops, full tuck-ins)",
                bottom: "Mid-rise and low-rise pants or skirts (without wide waistbands), drop-waist dresses, and straight-cut shift dresses without waist seams. (Avoid: high-waist bottoms, empire-waist dresses)"
            )
        case .balanced:
            return SuitableGarments(
                top: "Regular-fit tops hitting right at the hip bone, half-tucks (French tuck), and classic hip-length blazers or jackets. (Avoid: extreme asymmetrical cuts that distort the natural waistline)",
                bottom: "Mid-rise to standard high-rise trousers or skirts, A-line dresses, wrap dresses, and belted dresses with belts aligned with the natural waist."
            )
        case .longTorso:
            return SuitableGarments(
                top: "Full tuck-in tops, crop tops, peplum silhouettes, horizontal stripes, boat necklines, and cropped outerwear (cropped jackets, boleros, or short blazers ending right at the waist). (Avoid: untucked longline tops or tunics)",
                bottom: "High-rise / high-waist pants or skirts, wide-leg, flare, or paperbag silhouettes, empire-waist dresses (waistline directly beneath the bust), and high-waisted fit-and-flare dresses. (Avoid: low-rise bottoms, drop-waist dresses)"
            )
        }
    }

    /// Convenience accessor for suitable tops and outerwear.
    public var suitableTops: String {
        suitableGarments.top
    }

    /// Convenience accessor for suitable bottoms and dresses.
    public var suitableBottoms: String {
        suitableGarments.bottom
    }

    // MARK: - LLM System Prompt & Context

    /// Generates structured prompt context for LLM recommendation prompts (aligned with StyleVision).
    public var systemPrompt: String {
        """
        Torso Balance: \(displayName)
        Definition: \(definition)
        Act: \(act)
        Suitable Garments:
        - Top: \(suitableGarments.top)
        - Bottom: \(suitableGarments.bottom)
        """
    }

    /// Generates structured prompt context for LLM recommendation prompts (matching StyleVision's `llmPromptContext`).
    public var llmPromptContext: String {
        systemPrompt
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
