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
                hipCircumferenceCm: 94.0
            ),
            styleVision: .confident
        )
    }
}
