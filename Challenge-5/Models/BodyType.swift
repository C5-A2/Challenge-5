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

    // MARK: - Garment Ruleset Model

    /// Ruleset detailing suitable garments and cuts across key clothing categories for this body shape.
    public struct SuitableGarments: Sendable, Hashable, Codable {
        /// Recommended necklines and collars.
        public let necklines: String

        /// Recommended sleeves and shoulder cuts.
        public let sleeves: String

        /// Recommended tops, shirts, and jackets/coats.
        public let topsAndJackets: String

        /// Recommended trousers, pants, and jeans.
        public let bottoms: String

        /// Recommended skirts and dresses.
        public let skirtsAndDresses: String

        /// Recommended shorts, playsuits, and jumpsuits.
        public let shortsAndJumpsuits: String

        public init(
            necklines: String,
            sleeves: String,
            topsAndJackets: String,
            bottoms: String,
            skirtsAndDresses: String,
            shortsAndJumpsuits: String
        ) {
            self.necklines = necklines
            self.sleeves = sleeves
            self.topsAndJackets = topsAndJackets
            self.bottoms = bottoms
            self.skirtsAndDresses = skirtsAndDresses
            self.shortsAndJumpsuits = shortsAndJumpsuits
        }
    }

    // MARK: - Descriptive Properties & Ruleset

    /// Anatomical definition and proportion characteristics.
    public var definition: String {
        switch self {
        case .pear:
            return "The hips, thighs, and bottom are wider than the bust and shoulders, paired with a defined waist and proportionately slim arms and shoulders. Weight gain is typically visible first around the hips, thighs, and lower midriff."
        case .hourglass:
            return "Hip and bust measurements are nearly equal in size, accompanied by a significantly narrower, well-defined waist, slightly rounded shoulders, and balanced legs. Weight is distributed evenly throughout the body."
        case .rectangle:
            return "Characterized by equal bust, waist, and hip measurements, a straight shoulder line and ribcage, a lack of curves, and an undefined waist."
        case .invertedTriangle:
            return "Shoulders and/or bust are noticeably wider than the narrower hips and flat bottom, accompanied by a straight torso, little-to-no waist definition, and slim legs."
        case .apple:
            return "Characterized by a full chest/bust, narrow hips, a flat bottom, and fullness concentrated around the midsection with an undefined waistline and slender limbs/legs."
        }
    }

    /// Visual correction principle (Act) for proportional dressing.
    public var act: String {
        switch self {
        case .pear:
            return "Draw visual attention upward toward the upper body and defined waist. Add visual volume to the shoulders and bust area while de-emphasizing and skimming over fuller hips and thighs."
        case .hourglass:
            return "Follow and highlight the natural silhouette by proportionally dressing top and bottom while accentuating the small waist, avoiding boxy cuts that hide the waist or unbalance the frame."
        case .rectangle:
            return "Break up the straight silhouette to define the waist. Either proportionally add volume and details to both the upper and lower body, or visually pull in the waist with belts and nipped garments."
        case .invertedTriangle:
            return "Soften and play down the broad shoulder line and upper body. Add visual volume, curves, and interest around the hips and bottom while creating waist definition."
        case .apple:
            return "De-emphasize the fuller midsection, pull in the waist visually right below the bust, draw attention upward to the bust/neckline or downward to the legs, and add fullness to the lower body."
        }
    }

    /// Visual correction principle (Act) for proportional dressing (alias for `act`).
    public var actPrinciple: String {
        act
    }

    /// Suitable garments ruleset across all key clothing categories.
    public var suitableGarments: SuitableGarments {
        switch self {
        case .pear:
            return SuitableGarments(
                necklines: "Lower, wide necklines (square, bateau, Sabrina, off-shoulder); embellishments like cowl collars, big collars, lace trims, and ruffles.",
                sleeves: "Short wide sleeves (flutter, bell, batwing); tapered long sleeves with shoulder-enhancing cuts (puff, cap sleeves, shoulder pads).",
                topsAndJackets: "Fitted or nipped-in tops; horizontal stripes across the bust/shoulders; cropped jackets ending at the waist; mid-thigh coats, belted trench coats, and A-line coats.",
                bottoms: "Mid- to high-waisted flat-front trousers; straight-leg, bootcut, trouser-cut, or flare jeans in dark denim with clean, uncluttered hip pockets.",
                skirtsAndDresses: "Lightly gathered A-line or bias-cut skirts hitting at the knee or calf; A-line and fit-and-flare (X-line) dresses.",
                shortsAndJumpsuits: "Tailored, high-waisted wide-leg shorts; jumpsuits with bright, patterned, or detailed tops and dark, straight or flaring leg bottoms."
            )
        case .hourglass:
            return SuitableGarments(
                necklines: "Slightly rounded necklines (oval, deep oval, jewel); lower and wider necklines (scoop, sweetheart); slimming V-necks.",
                sleeves: "Fitted sleeves and set-in sleeves; light cap sleeves balanced with proper bottoms.",
                topsAndJackets: "Fitted or nipped shirts, wrap tops, and belted tops; form-fitting or belted single-breasted jackets ending at the hipbone; tailored trench coats, coachmen coats, and A-line coats.",
                bottoms: "Mid- or high-waisted trousers and jeans; wide-leg, loose-fitting, bootcut, flare, or slightly tapered styles without bulky pockets/embellishments on the hips.",
                skirtsAndDresses: "High-waisted pencil skirts; flip, bias, A-line, full circle, or tulip skirts; nipped/belted dresses, wrap dresses, and full-skirt dresses ending at knee-length or longer.",
                shortsAndJumpsuits: "High-waisted shorts with contoured waistbands; form-fitting, belted jumpsuits with simple, flared legs."
            )
        case .rectangle:
            return SuitableGarments(
                necklines: "Round necklines (scoop, jewel); lower wide necklines (wide V-, slash, sweetheart); embellished necklines (big collars, lace trims, ruffles); narrow necklines (turtlenecks, mandarin, crew, funnel, halter).",
                sleeves: "Loose, wide sleeves (flared, princess, puff, flutter); embellished, cuffed, or rolled-up sleeves.",
                topsAndJackets: "Nipped, belted, or draped tops finishing at the hip level; tops with bust frills, bibs, or pockets; belted/nipped jackets extending below the waist; double-breasted jackets; long coats with waist belts.",
                bottoms: "Low- to mid-rise trousers and jeans; flared cuts (bootcut, wide leg, flare) with hip/thigh details like pleats, pockets, or whiskering.",
                skirtsAndDresses: "Flared or detailed skirts (box pleat, bubble, panelled, layered, full circle, trumpet); tapered knee-length pencil skirts; empire line, princess seam, wrap, or tailored shift dresses.",
                shortsAndJumpsuits: "Low- or mid-waisted patterned shorts with pockets, pleats, or scallops; high-waisted tie-waist flared shorts; belted or drawstring wide-leg jumpsuits and playsuits with sleeve details."
            )
        case .invertedTriangle:
            return SuitableGarments(
                necklines: "Deep and narrow necklines (deep V-neck, scoop, U-neck); asymmetric necklines; halter necks.",
                sleeves: "Tight, tapered short sleeves; dropped shoulder points and shoulder slits; soft flaring long sleeves (raglan, kimono, dolman); wide straps.",
                topsAndJackets: "Collarless or small-collared tops extending past the hip line in dark colors; wrap tops; nipped/belted or straight single-breasted jackets extending past the hips with hip pockets/details; belted, flared coats.",
                bottoms: "Trousers and jeans in light or bright colors with details (front/back pockets, rips, distress, patterns); wide-leg, palazzo, cargo, flare, bootcut, culotte, or boyfriend styles.",
                skirtsAndDresses: "Skirts that flare from the hips (A-line, pleated, bias-cut, tulip, tiered, ballerina, full) in bright colors or horizontal patterns; A-line, shift, or wrap dresses flaring at the hips; strapless dresses.",
                shortsAndJumpsuits: "Wide, baggy, pleated, or printed shorts; deep V-neck wide-leg jumpsuits with defined waists or belt details."
            )
        case .apple:
            return SuitableGarments(
                necklines: "Low and wide necklines (low V-neck, deep scoop) that break up the chest vertically; embellished necklines.",
                sleeves: "Detailed sleeves (slits, gathers, cuffs, draped fabrics); loose flared sleeves; cap sleeves or shoulder pads.",
                topsAndJackets: "Wrap tops flaring at the hip; untucked tops ending below the hipline with diagonal lines or big prints; open draped cardigans; single-breasted structured jackets/blazers finishing at the hipbone; long single-breasted coats.",
                bottoms: "Low- to mid-rise flat-front trousers and jeans with wide waistbands; wide-leg, bootcut, or flared cuts with side or cargo pockets.",
                skirtsAndDresses: "Full, flared, A-line, panelled, or bias-cut skirts hitting at the knee or calf; A-line, empire-line, bias-cut, or wrap dresses with medium-to-wide belts worn above the natural waist.",
                shortsAndJumpsuits: "Mid- to high-rise flat-front loose knee-length shorts; short wrap playsuits or empire high-waisted jumpsuits in flowy fabrics."
            )
        }
    }

    // MARK: - Direct Convenience Accessors

    /// Recommended necklines and collars.
    public var suitableNecklines: String {
        suitableGarments.necklines
    }

    /// Recommended sleeves and shoulder cuts.
    public var suitableSleeves: String {
        suitableGarments.sleeves
    }

    /// Recommended tops, shirts, and jackets/coats.
    public var suitableTopsAndJackets: String {
        suitableGarments.topsAndJackets
    }

    /// Recommended trousers, pants, and jeans.
    public var suitableBottoms: String {
        suitableGarments.bottoms
    }

    /// Recommended skirts and dresses.
    public var suitableSkirtsAndDresses: String {
        suitableGarments.skirtsAndDresses
    }

    /// Recommended shorts, playsuits, and jumpsuits.
    public var suitableShortsAndJumpsuits: String {
        suitableGarments.shortsAndJumpsuits
    }

    // MARK: - LLM System Prompt & Context

    /// Generates structured prompt context for LLM recommendation prompts (aligned with StyleVision).
    public var systemPrompt: String {
        """
        Body Type: \(displayName)
        Definition: \(definition)
        Act: \(act)
        Suitable Garments:
        - Necklines: \(suitableGarments.necklines)
        - Sleeves: \(suitableGarments.sleeves)
        - Tops & Jackets: \(suitableGarments.topsAndJackets)
        - Bottoms: \(suitableGarments.bottoms)
        - Skirts & Dresses: \(suitableGarments.skirtsAndDresses)
        - Shorts & Jumpsuits: \(suitableGarments.shortsAndJumpsuits)
        """
    }

    /// Generates structured prompt context for LLM recommendation prompts (matching StyleVision's `llmPromptContext`).
    public var llmPromptContext: String {
        systemPrompt
    }
}
