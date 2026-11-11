//
//  UserProfile.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import Foundation
import SwiftData

/// Root persistent model storing the user's physical profile, personal color analysis,
/// and facial/body scan capture data.
///
/// Conforms to SwiftData `@Model` and serves as the single source of truth for
/// user attributes feeding into the recommendation engine.
@Model
final class UserProfile {

    // MARK: - Identifiers & Timestamps

    @Attribute(.unique) var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Body & Color Profiling (Ricky — C5-2)

    var colorSeason: ColorSeason?
    var bodyType: BodyType?
    var torsoBalance: TorsoBalance?
    var measurements: BodyMeasurements?
    var styleVision: StyleVision?

    // MARK: - Captured Scan Media (External Storage)

    @Attribute(.externalStorage) var facePhotoData: Data?
    @Attribute(.externalStorage) var frontBodyPhotoData: Data?
    @Attribute(.externalStorage) var sideBodyPhotoData: Data?

    // MARK: - Computed Status Helpers

    /// True when the user has completed all profiling steps (Skin Scan + Body Scan + Measurements).
    var hasCompletedProfileSetup: Bool {
        colorSeason != nil && bodyType != nil && measurements != nil
    }

    /// True when face scan and color season classification are completed.
    var hasCompletedSkinScan: Bool {
        colorSeason != nil
    }

    /// True when front/side body scan and measurements are completed.
    var hasCompletedBodyScan: Bool {
        bodyType != nil && measurements != nil
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        colorSeason: ColorSeason? = nil,
        bodyType: BodyType? = nil,
        torsoBalance: TorsoBalance? = nil,
        measurements: BodyMeasurements? = nil,
        styleVision: StyleVision? = nil,
        facePhotoData: Data? = nil,
        frontBodyPhotoData: Data? = nil,
        sideBodyPhotoData: Data? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.colorSeason = colorSeason
        self.bodyType = bodyType
        self.torsoBalance = torsoBalance
        self.measurements = measurements
        self.styleVision = styleVision
        self.facePhotoData = facePhotoData
        self.frontBodyPhotoData = frontBodyPhotoData
        self.sideBodyPhotoData = sideBodyPhotoData
    }
}

// MARK: - Query & Storage Helpers (C5-97)

extension UserProfile {
    /// Standard fetch descriptor for the primary user profile.
    static var primaryDescriptor: FetchDescriptor<UserProfile> {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\UserProfile.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 1
        return descriptor
    }

    /// Fetches the existing primary profile from the ModelContext, or creates and inserts a new one.
    @MainActor
    static func fetchOrCreate(in context: ModelContext) throws -> UserProfile {
        if let existing = try context.fetch(primaryDescriptor).first {
            return existing
        }
        let newProfile = UserProfile()
        context.insert(newProfile)
        try context.save()
        return newProfile
    }

    /// Updates body measurements, classified body shape, torso balance, and scan photos.
    func updateBodyScan(
        measurements: BodyMeasurements,
        bodyType: BodyType?,
        torsoBalance: TorsoBalance?,
        frontPhotoData: Data? = nil,
        sidePhotoData: Data? = nil
    ) {
        self.measurements = measurements
        self.bodyType = bodyType
        self.torsoBalance = torsoBalance
        if let front = frontPhotoData {
            self.frontBodyPhotoData = front
        }
        if let side = sidePhotoData {
            self.sideBodyPhotoData = side
        }
        self.updatedAt = Date()
    }

    /// Updates skin analysis color season and captured face photo.
    func updateSkinScan(
        colorSeason: ColorSeason,
        facePhotoData: Data? = nil
    ) {
        self.colorSeason = colorSeason
        if let face = facePhotoData {
            self.facePhotoData = face
        }
        self.updatedAt = Date()
    }
}

// MARK: - Sample Preview Data

extension UserProfile {
    /// Mock user profile with complete body and skin attributes for SwiftUI #Preview.
    static var mockSample: UserProfile {
        UserProfile(
            colorSeason: .trueAutumn,
            bodyType: .hourglass,
            torsoBalance: .balanced,
            measurements: BodyMeasurements(
                age: 23,
                weightKg: 58.0,
                heightCm: 168.0,
                usualSize: .m,
                shoulderWidthCm: 39.5,
                bustCircumferenceCm: 89.0,
                waistCircumferenceCm: 68.0,
                hipCircumferenceCm: 94.0,
                torsoLengthCm: 52.9
            ),
            styleVision: .confident
        )
    }
}
