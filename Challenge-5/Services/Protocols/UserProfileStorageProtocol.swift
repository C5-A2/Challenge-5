//
//  UserProfileStorageProtocol.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 02/11/26.
//

import Foundation
import SwiftData

/// Storage protocol for managing user physical profile, skin analysis, body measurements,
/// and scan photos in SwiftData local storage (C5-97).
@MainActor
protocol UserProfileStoring: Sendable {
    /// Fetches the current primary user profile, returning nil if no profile exists yet.
    func fetchProfile() throws -> UserProfile?

    /// Fetches the existing primary profile or creates and inserts a new one into storage.
    func getOrCreateProfile() throws -> UserProfile

    /// Persists completed body scan results (measurements, body type, torso balance, and photos).
    @discardableResult
    func saveBodyScanResult(
        measurements: BodyMeasurements,
        bodyType: BodyType?,
        torsoBalance: TorsoBalance?,
        frontPhotoData: Data?,
        sidePhotoData: Data?
    ) throws -> UserProfile

    /// Persists completed skin scan results (color season and face photo).
    @discardableResult
    func saveSkinScanResult(
        colorSeason: ColorSeason,
        facePhotoData: Data?
    ) throws -> UserProfile

    /// Persists selected style vision / character.
    @discardableResult
    func saveStyleVision(_ styleVision: StyleVision) throws -> UserProfile

    /// Clears or resets the user's stored profile attributes.
    func clearProfile() throws
}
