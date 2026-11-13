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
    /// When the user saved (bookmarked) this look. `nil` when it isn't saved. Library shows newest first.
    var savedAt: Date?

    var fitRationale: String

    /// Image of the user wearing this look, shown on the result stage.
    /// The store flow crops garments from this image for visual search.
    @Attribute(.externalStorage) var lookImageData: Data?
    
    /// Timestamp when the visual look image was last generated/styled.
    var imageGeneratedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \GarmentItem.outfitLook)
    var garments: [GarmentItem] = []

    /// The occasion this look was generated for. Lets the Library show the occasion title.
    var occasion: OccasionItem?

    /// Versioned profile snapshot used when this look was generated.
    /// Kept on the look so bookmarked looks in Library retain their profile version even if the occasion is deleted.
    var profileSnapshot: OccasionProfileSnapshot?

    /// Cached metadata from the parent occasion so that if the occasion is deleted,
    /// the saved look in Library still retains its occasion title, dresscode, and date.
    var cachedOccasionTitle: String?
    var cachedOccasionDresscode: String?
    var cachedOccasionDate: Date?

    // MARK: - Initializer

    init(
        lookIndex: Int,
        fitRationale: String = "",
        isBookmarked: Bool = false,
        lookImageData: Data? = nil,
        imageGeneratedAt: Date? = nil
    ) {
        self.lookIndex = lookIndex
        self.fitRationale = fitRationale
        self.isBookmarked = isBookmarked
        self.lookImageData = lookImageData
        self.imageGeneratedAt = imageGeneratedAt
    }
}
