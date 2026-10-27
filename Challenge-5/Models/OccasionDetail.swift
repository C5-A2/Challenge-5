//
//  OccasionDetail.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 24/10/26.
//

import Foundation

/// Data model representing the input and styling parameters for an occasion.
///
/// Used by the occasion input flow (`OccasionFormSheet`), data processing pipeline,
/// and recommendation engine to capture user preferences and styling reference assets.
public struct OccasionDetail: Identifiable, Codable, Sendable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the occasion detail.
    public var id: UUID
    
    /// Date when the occasion takes place.
    public var date: Date
    
    /// Title of the occasion (e.g. "Gala Dinner", "Product Launch").
    public var title: String
    
    /// Required or intended dress code (e.g. "Formal", "Smart Casual", "Cocktail").
    public var dresscode: String
    
    /// Reference images stored as binary data (JPEG / PNG).
    public var referenceImages: [Data]
    
    /// Desired style visions (emotional impression / mood) for this occasion.
    public var visions: [StyleVision]

    // MARK: - Date Helpers
    
    /// Default date representing tomorrow.
    public static var defaultTomorrowDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        date: Date = OccasionDetail.defaultTomorrowDate,
        title: String = "",
        dresscode: String = "",
        referenceImages: [Data] = [],
        visions: [StyleVision] = []
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.dresscode = dresscode
        self.referenceImages = referenceImages
        self.visions = visions
    }

    // MARK: - Computed Properties

    /// Checks if the occasion has valid parameters:
    /// - `title` must be non-empty (required).
    /// - `date` cannot be in the past (`!isPast`).
    /// - `visions` count is between 0 and 3 (`min 0, max 3`).
    /// - `dresscode` is optional.
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isPast &&
        visions.count <= 3
    }

    /// Whether this occasion date has already passed (prior to today; today is not past).
    public var isPast: Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }

    /// Formatted display string for the occasion date.
    public var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
