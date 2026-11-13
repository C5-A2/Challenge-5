//
//  OccasionProfileSnapshot.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 13/11/26.
//

import Foundation
import SwiftData

/// Point-in-time SwiftData snapshot of the user's profile attributes used when
/// generating outfits for an `OccasionItem`.
///
/// Preserves body type, bust/waist/hip measurements, color analysis, torso balance,
/// upper body & leg lengths, torso ratio, and their explanations so past occasions
/// and saved looks continue to reflect the profile version used at generation time,
/// even after `UserProfile` is updated.
@Model
final class OccasionProfileSnapshot {

    // MARK: - Versioning & Metadata

    @Attribute(.unique) var id: UUID = UUID()
    var capturedAt: Date = Date()
    var sourceProfileID: UUID?
    var profileUpdatedAt: Date?

    // MARK: - Body Shape & Measurements

    var bodyType: BodyType?
    var bustCm: Double
    var waistCm: Double
    var hipsCm: Double

    // MARK: - Color Analysis

    var colorSeason: ColorSeason?
    var colorAnalysisExplanation: String
    @Attribute(.externalStorage) var facePhotoData: Data?

    // MARK: - Torso Balance & Proportions

    var torsoBalance: TorsoBalance?
    var upperBodyLengthCm: Double
    var legLengthCm: Double
    var torsoRatioPercentage: Double
    var torsoBalanceExplanation: String

    // MARK: - Relationships

    var occasion: OccasionItem?

    @Relationship(deleteRule: .nullify, inverse: \OutfitLook.profileSnapshot)
    var looks: [OutfitLook] = []

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        sourceProfileID: UUID? = nil,
        profileUpdatedAt: Date? = nil,
        bodyType: BodyType? = nil,
        bustCm: Double,
        waistCm: Double,
        hipsCm: Double,
        colorSeason: ColorSeason? = nil,
        colorAnalysisExplanation: String,
        facePhotoData: Data? = nil,
        torsoBalance: TorsoBalance? = nil,
        upperBodyLengthCm: Double,
        legLengthCm: Double,
        torsoRatioPercentage: Double,
        torsoBalanceExplanation: String
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.sourceProfileID = sourceProfileID
        self.profileUpdatedAt = profileUpdatedAt
        self.bodyType = bodyType
        self.bustCm = bustCm
        self.waistCm = waistCm
        self.hipsCm = hipsCm
        self.colorSeason = colorSeason
        self.colorAnalysisExplanation = colorAnalysisExplanation
        self.facePhotoData = facePhotoData
        self.torsoBalance = torsoBalance
        self.upperBodyLengthCm = upperBodyLengthCm
        self.legLengthCm = legLengthCm
        self.torsoRatioPercentage = torsoRatioPercentage
        self.torsoBalanceExplanation = torsoBalanceExplanation
    }

    /// Captures a point-in-time snapshot from a `UserProfile`.
    convenience init(from profile: UserProfile, capturedAt: Date = Date()) {
        let measurements = profile.measurements ?? UserProfile.mockSample.measurements!
        let resolvedBodyType = profile.bodyType ?? .hourglass
        let resolvedColorSeason = profile.colorSeason ?? .trueAutumn
        let resolvedTorsoBalance = profile.torsoBalance ?? .balanced

        self.init(
            capturedAt: capturedAt,
            sourceProfileID: profile.id,
            profileUpdatedAt: profile.updatedAt,
            bodyType: resolvedBodyType,
            bustCm: measurements.resolvedBustCircumferenceCm,
            waistCm: measurements.resolvedWaistCircumferenceCm,
            hipsCm: measurements.resolvedHipCircumferenceCm,
            colorSeason: resolvedColorSeason,
            colorAnalysisExplanation: resolvedColorSeason.definition,
            facePhotoData: profile.facePhotoData,
            torsoBalance: resolvedTorsoBalance,
            upperBodyLengthCm: measurements.resolvedTorsoLengthCm,
            legLengthCm: measurements.resolvedLegLengthCm,
            torsoRatioPercentage: measurements.torsoToHeightPercentage,
            torsoBalanceExplanation: "\(resolvedTorsoBalance.suitableGarments.top) \(resolvedTorsoBalance.suitableGarments.bottom)"
        )
    }
}

