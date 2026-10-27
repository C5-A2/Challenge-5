//
//  BodyType.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import Foundation

/// Primary body shape classification based on shoulder, bust, waist, and hip proportions.
///
/// Serves as the core domain type for the body scanning flow (`BodyAnalysisResultView`)
/// and the recommendation engine's Body Shape Fit score (`bodyShapeScore`).
public enum BodyType: String, Codable, CaseIterable, Identifiable, Sendable {
    case pear = "Pear"
    case hourglass = "Hourglass"
    case rectangle = "Rectangle"
    case invertedTriangle = "Inverted Triangle"
    case apple = "Apple"

    public var id: String { rawValue }

    // MARK: - Descriptive Properties

    public var displayName: String {
        switch self {
        case .pear: return "Pear Shape (Triangle)"
        case .hourglass: return "Hourglass Shape"
        case .rectangle: return "Rectangle Shape (Athletic)"
        case .invertedTriangle: return "Inverted Triangle Shape"
        case .apple: return "Apple Shape (Round)"
        }
    }

    /// Anatomical definition and proportion characteristics.
    public var definition: String {
        switch self {
        case .pear:
            return "The hips, thighs, and bottom are wider than the bust and shoulders, paired with a defined waist and proportionately slim arms and shoulders."
        case .hourglass:
            return "Hip and bust measurements are nearly equal in size, accompanied by a significantly narrower, well-defined waist, slightly rounded shoulders, and balanced legs."
        case .rectangle:
            return "Characterized by equal bust, waist, and hip measurements, a straight shoulder line and ribcage, a lack of curves, and an undefined waist."
        case .invertedTriangle:
            return "Shoulders and/or bust are noticeably wider than the narrower hips and flat bottom, accompanied by a straight torso, little-to-no waist definition, and slim legs."
        case .apple:
            return "Characterized by a full chest/bust, narrow hips, a flat bottom, and fullness concentrated around the midsection with an undefined waistline and slender limbs/legs."
        }
    }

    /// Visual correction principle (Act) for proportional dressing.
    public var actPrinciple: String {
        switch self {
        case .pear:
            return "Draw visual attention upward toward the upper body and defined waist. Add visual volume to the shoulders and bust area while de-emphasizing fuller hips and thighs."
        case .hourglass:
            return "Follow and highlight the natural silhouette by proportionally dressing top and bottom while accentuating the small waist, avoiding boxy cuts that hide the waist."
        case .rectangle:
            return "Break up the straight silhouette to define the waist. Either proportionally add volume to both the upper and lower body, or visually pull in the waist with belts."
        case .invertedTriangle:
            return "Soften and play down the broad shoulder line and upper body. Add visual volume, curves, and interest around the hips and bottom while creating waist definition."
        case .apple:
            return "De-emphasize the fuller midsection, pull in the waist visually right below the bust, draw attention upward to the neckline or downward to the legs."
        }
    }
}
