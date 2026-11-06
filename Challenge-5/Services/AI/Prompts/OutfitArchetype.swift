//
//  OutfitArchetype.swift
//  Challenge-5
//
//  Created by Natalie Grace on 04/11/26.
//

import Foundation

// MARK: - Outfit Structure

/// The pieces a look is made of. Chosen per look, so the 5 looks don't all have an outer, a top and a bottom.
nonisolated enum OutfitStructure: String, Sendable, CaseIterable {
    case outerTopBottom
    case topBottom
    case dress
    case dressWithOuter

    /// The garment categories of this structure, in the order the model must output them.
    var categories: [GarmentCategory] {
        switch self {
        case .outerTopBottom: [.outer, .top, .bottom]
        case .topBottom: [.top, .bottom]
        case .dress: [.dress]
        case .dressWithOuter: [.dress, .outer]
        }
    }

    var hasDress: Bool {
        categories.contains(.dress)
    }

    /// How the structure is described to the model.
    var promptDescription: String {
        switch self {
        case .outerTopBottom:
            "An outer layer (jacket, blazer, coat, cardigan or similar) over a top, with a bottom."
        case .topBottom:
            "A top and a bottom only, no outer layer."
        case .dress:
            "One dress or jumpsuit only, no top, bottom or outer layer."
        case .dressWithOuter:
            "A dress or jumpsuit with an outer layer over it, no separate top or bottom."
        }
    }
}

// MARK: - Outfit Archetype

/// The creative direction of each of the 5 looks, so they differ in style, not only in color.
///
/// The occasion, the Indonesian setting (tropical climate, local wardrobe), body shape and personality
/// (style vision + the user's taste) guide every look as a baseline; each direction adds its own focus:
/// - Look 1 `referenceMatch`: recreates the user's reference photos (or a signature look without them).
/// - Look 2 `localTouch`: one Indonesian element (batik, tenun, kebaya...) styled in a modern way.
/// - Look 3 `colorStory`: color-led: a deliberate tonal, monochrome or color-blocked palette story.
/// - Look 4 `surpriseMe`: a bold style direction the user wouldn't pick herself.
/// - Look 5 `lookMore`: the style vision ("I want to look more...") pushed to the maximum.
///
/// Looks generated later ("generate more") cycle through the same 5 directions.
nonisolated enum OutfitArchetype: Int, Sendable, CaseIterable {
    case referenceMatch
    case localTouch
    case colorStory
    case surpriseMe
    case lookMore

    // MARK: - Sampling Values

    /// Grounded looks (reference, local touch) stay lower; creative looks go higher.
    private static let referenceMatchTemperature: Float = 0.35
    private static let localTouchTemperature: Float = 0.55
    private static let colorStoryTemperature: Float = 0.60
    private static let surpriseMeTemperature: Float = 0.90
    private static let lookMoreTemperature: Float = 0.70
    private static let groundedTopP: Float = 0.90
    private static let creativeTopP: Float = 0.95

    // MARK: - Initializer

    /// The direction for a look: looks 0...4 get one each, later looks cycle through them again.
    init(lookIndex: Int) {
        let cases = Self.allCases
        self = cases[((lookIndex % cases.count) + cases.count) % cases.count]
    }

    // MARK: - Properties

    /// Name shown to the model and stored as the look's archetype.
    func title(hasReference: Bool, hasVision: Bool) -> String {
        switch self {
        case .referenceMatch: hasReference ? "Reference Match" : "Signature Look"
        case .localTouch: "Local Touch"
        case .colorStory: "Color Story"
        case .surpriseMe: "Surprise Me"
        case .lookMore: hasVision ? "Look More" : "Statement Look"
        }
    }

    var temperature: Float {
        switch self {
        case .referenceMatch: Self.referenceMatchTemperature
        case .localTouch: Self.localTouchTemperature
        case .colorStory: Self.colorStoryTemperature
        case .surpriseMe: Self.surpriseMeTemperature
        case .lookMore: Self.lookMoreTemperature
        }
    }

    var topP: Float {
        switch self {
        case .referenceMatch, .localTouch: Self.groundedTopP
        case .colorStory, .surpriseMe, .lookMore: Self.creativeTopP
        }
    }

    /// Only the surprise look may use one accent color outside the seasonal palette.
    var allowsOffPaletteAccent: Bool {
        self == .surpriseMe
    }

    /// The pieces for this look. The reference look follows the photos; the other looks
    /// take structures that differ from it, so the set mixes layered looks, separates and dresses.
    func structure(referenceStructure: OutfitStructure?) -> OutfitStructure {
        switch self {
        case .referenceMatch:
            return referenceStructure ?? .outerTopBottom
        case .localTouch:
            return .topBottom
        case .colorStory:
            return .outerTopBottom
        case .surpriseMe:
            return referenceStructure?.hasDress == true ? .topBottom : .dress
        case .lookMore:
            return referenceStructure == .dressWithOuter ? .outerTopBottom : .dressWithOuter
        }
    }
}
