//
//  OutfitLook.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation
import SwiftData

/// One AI-generated outfit look for an occasion (5 looks per occasion).
@Model
final class OutfitLook {

    // MARK: - Properties

    @Attribute(.unique) var id: UUID = UUID()
    var lookIndex: Int                      // 0..4 for 5 AI-generated looks
    var isBookmarked: Bool = false

    // 3-Fits compliance scores (0.0 to 1.0)
    var bodyShapeScore: Double
    var colorHarmonyScore: Double
    var torsoBalanceScore: Double
    var fitRationale: String

    /// Image of the user wearing this look, shown on the result stage.
    /// The store flow crops garments from this image for visual search.
    @Attribute(.externalStorage) var lookImageData: Data?

    @Relationship(deleteRule: .cascade, inverse: \GarmentItem.outfitLook)
    var garments: [GarmentItem] = []

    // MARK: - Initializer

    init(
        lookIndex: Int,
        bodyShapeScore: Double = 0.0,
        colorHarmonyScore: Double = 0.0,
        torsoBalanceScore: Double = 0.0,
        fitRationale: String = "",
        isBookmarked: Bool = false,
        lookImageData: Data? = nil
    ) {
        self.lookIndex = lookIndex
        self.bodyShapeScore = bodyShapeScore
        self.colorHarmonyScore = colorHarmonyScore
        self.torsoBalanceScore = torsoBalanceScore
        self.fitRationale = fitRationale
        self.isBookmarked = isBookmarked
        self.lookImageData = lookImageData
    }
}
