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
    
    @Relationship(deleteRule: .cascade)
    var generatedLooks: [OutfitLook] = []
    
    // MARK: - Computed Properties
    
    var isUpcoming: Bool {
        date > Date()
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
            )
        ]
    }
}
