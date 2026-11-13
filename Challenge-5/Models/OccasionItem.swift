//
//  OccasionItem.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import Foundation
import SwiftData

/// Canonical SwiftData model representing an occasion created by the user.
///
/// Stores title, scheduled date, dresscode, style vision keywords, and reference images.
/// Relationships link to AI-generated looks (`OutfitLook`).
@Model
final class OccasionItem {
    
    // MARK: - Properties
    
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var dresscode: String = ""
    @Attribute(.externalStorage) var referenceImageData: Data? = nil
    var referenceImagesData: [Data] = []
    var visionKeywords: [String] = []
    var customNote: String? = nil
    var createdAt: Date = Date()
    var isCompleted: Bool = false
    
    @Relationship(deleteRule: .nullify, inverse: \OutfitLook.occasion)
    var generatedLooks: [OutfitLook] = []

    /// Versioned snapshot of the user's profile at the time outfits were generated for this occasion.
    @Relationship(deleteRule: .nullify, inverse: \OccasionProfileSnapshot.occasion)
    var profileSnapshot: OccasionProfileSnapshot?
    
    // MARK: - Computed Properties
    
    var isPast: Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
    
    var isUpcoming: Bool {
        !isPast
    }
    
    var visions: [StyleVision] {
        visionKeywords.compactMap { StyleVision(rawValue: $0) }
    }
    
    var dayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var monthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
    
    var formattedDateString: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var dateFormatted: String {
        formattedDateString
    }
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        dresscode: String = "",
        referenceImageData: Data? = nil,
        referenceImagesData: [Data] = [],
        visionKeywords: [String] = [],
        customNote: String? = nil,
        createdAt: Date = Date(),
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.dresscode = dresscode
        self.referenceImageData = referenceImageData
        self.referenceImagesData = referenceImagesData
        self.visionKeywords = visionKeywords
        self.customNote = customNote
        self.createdAt = createdAt
        self.isCompleted = isCompleted
    }
    
    convenience init(from detail: OccasionDetail) {
        self.init(
            id: detail.id,
            title: detail.title,
            date: detail.date,
            dresscode: detail.dresscode,
            referenceImageData: detail.referenceImages.first,
            referenceImagesData: detail.referenceImages,
            visionKeywords: detail.visions.map(\.rawValue)
        )
    }
}

// MARK: - Preview Sample Data

extension OccasionItem {
    static var samples: [OccasionItem] {
        [
            OccasionItem(
                title: "Annual Gala Dinner",
                date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                dresscode: "Black Tie Optional",
                visionKeywords: ["Elegant", "Confident"]
            ),
            OccasionItem(
                title: "Beach Club Brunch",
                date: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
                dresscode: "Resort Casual",
                visionKeywords: ["Playful", "Energetic"]
            ),
            OccasionItem(
                title: "Graduation Ceremony",
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                dresscode: "Smart Formal",
                visionKeywords: ["Confident", "Calm"]
            )
        ]
    }
    
    /// Sample occasions with dates in the past, designed specifically for testing History View.
    static var pastSamples: [OccasionItem] {
        [
            OccasionItem(
                title: "Graduation Ceremony",
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                dresscode: "Smart Formal",
                visionKeywords: ["Confident", "Calm"]
            ),
            OccasionItem(
                title: "Tech Conference Keynote",
                date: Calendar.current.date(byAdding: .day, value: -18, to: Date()) ?? Date(),
                dresscode: "Business Casual",
                visionKeywords: ["Competent", "Powerful"]
            ),
            OccasionItem(
                title: "Friend's Birthday Dinner",
                date: Calendar.current.date(byAdding: .day, value: -32, to: Date()) ?? Date(),
                dresscode: "Cocktail Chic",
                visionKeywords: ["Romantic", "Playful"]
            ),
            OccasionItem(
                title: "Art Gallery Vernissage",
                date: Calendar.current.date(byAdding: .day, value: -54, to: Date()) ?? Date(),
                dresscode: "Creative Modern",
                visionKeywords: ["Mysterious", "Elegant"]
            )
        ]
    }
}

// MARK: - Safe Deletion Preserving Saved Looks
extension OccasionItem {
    /// Deletes this occasion from the context while preserving any bookmarked looks in the Library.
    ///
    /// Non-bookmarked looks are permanently removed to prevent orphaned entities, while bookmarked
    /// looks cache the occasion metadata and are detached so they remain visible in Library.
    func deletePreservingBookmarkedLooks(in context: ModelContext) {
        ReferenceImageStyleAnalyzer.shared.saveDescriptions([], forOccasionID: self.id)
        
        let looksToProcess = generatedLooks
        for look in looksToProcess {
            if look.isBookmarked {
                look.cachedOccasionTitle = self.title
                look.cachedOccasionDresscode = self.dresscode
                look.cachedOccasionDate = self.date
                look.occasion = nil
            } else {
                context.delete(look)
            }
        }
        self.generatedLooks.removeAll()

        if let snapshot = self.profileSnapshot {
            let hasBookmarkedLooks = looksToProcess.contains { $0.isBookmarked }
            snapshot.occasion = nil
            self.profileSnapshot = nil
            if !hasBookmarkedLooks {
                context.delete(snapshot)
            }
        }
        
        context.delete(self)
        try? context.save()
    }
}
