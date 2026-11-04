//
//  UserProfileStorageService.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 02/11/26.
//

import Foundation
import SwiftData

/// SwiftData implementation of `UserProfileStoring` (C5-97).
/// Manages querying, creating, and updating the singular primary `UserProfile`.
@MainActor
final class UserProfileStorageService: UserProfileStoring {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - UserProfileStoring

    func fetchProfile() throws -> UserProfile? {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\UserProfile.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 1

        do {
            let profiles = try modelContext.fetch(descriptor)
            return profiles.first
        } catch {
            throw UserProfileStorageError.fetchFailed(underlying: error)
        }
    }

    func getOrCreateProfile() throws -> UserProfile {
        if let existing = try fetchProfile() {
            return existing
        }

        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        do {
            try modelContext.save()
            return newProfile
        } catch {
            throw UserProfileStorageError.saveFailed(underlying: error)
        }
    }

    @discardableResult
    func saveBodyScanResult(
        measurements: BodyMeasurements,
        bodyType: BodyType?,
        torsoBalance: TorsoBalance?,
        frontPhotoData: Data?,
        sidePhotoData: Data?
    ) throws -> UserProfile {
        let profile = try getOrCreateProfile()
        profile.measurements = measurements
        profile.bodyType = bodyType
        profile.torsoBalance = torsoBalance

        if let front = frontPhotoData {
            profile.frontBodyPhotoData = front
        }
        if let side = sidePhotoData {
            profile.sideBodyPhotoData = side
        }
        profile.updatedAt = Date()

        do {
            try modelContext.save()
            return profile
        } catch {
            throw UserProfileStorageError.saveFailed(underlying: error)
        }
    }

    @discardableResult
    func saveSkinScanResult(
        colorSeason: ColorSeason,
        facePhotoData: Data?
    ) throws -> UserProfile {
        let profile = try getOrCreateProfile()
        profile.colorSeason = colorSeason

        if let face = facePhotoData {
            profile.facePhotoData = face
        }
        profile.updatedAt = Date()

        do {
            try modelContext.save()
            return profile
        } catch {
            throw UserProfileStorageError.saveFailed(underlying: error)
        }
    }

    @discardableResult
    func saveStyleVision(_ styleVision: StyleVision) throws -> UserProfile {
        let profile = try getOrCreateProfile()
        profile.styleVision = styleVision
        profile.updatedAt = Date()

        do {
            try modelContext.save()
            return profile
        } catch {
            throw UserProfileStorageError.saveFailed(underlying: error)
        }
    }

    func clearProfile() throws {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try modelContext.fetch(descriptor)
            for p in profiles {
                modelContext.delete(p)
            }
            try modelContext.save()
        } catch {
            throw UserProfileStorageError.deleteFailed(underlying: error)
        }
    }
}

/// In-memory mock storage for SwiftUI Previews and testing (C5-97).
@MainActor
final class MockUserProfileStorage: UserProfileStoring {

    private var profile: UserProfile?

    init(initialProfile: UserProfile? = nil) {
        self.profile = initialProfile
    }

    func fetchProfile() throws -> UserProfile? {
        profile
    }

    func getOrCreateProfile() throws -> UserProfile {
        if let existing = profile { return existing }
        let newP = UserProfile()
        self.profile = newP
        return newP
    }

    @discardableResult
    func saveBodyScanResult(
        measurements: BodyMeasurements,
        bodyType: BodyType?,
        torsoBalance: TorsoBalance?,
        frontPhotoData: Data?,
        sidePhotoData: Data?
    ) throws -> UserProfile {
        let p = try getOrCreateProfile()
        p.measurements = measurements
        p.bodyType = bodyType
        p.torsoBalance = torsoBalance
        p.frontBodyPhotoData = frontPhotoData
        p.sideBodyPhotoData = sidePhotoData
        p.updatedAt = Date()
        self.profile = p
        return p
    }

    @discardableResult
    func saveSkinScanResult(
        colorSeason: ColorSeason,
        facePhotoData: Data?
    ) throws -> UserProfile {
        let p = try getOrCreateProfile()
        p.colorSeason = colorSeason
        p.facePhotoData = facePhotoData
        p.updatedAt = Date()
        self.profile = p
        return p
    }

    @discardableResult
    func saveStyleVision(_ styleVision: StyleVision) throws -> UserProfile {
        let p = try getOrCreateProfile()
        p.styleVision = styleVision
        p.updatedAt = Date()
        self.profile = p
        return p
    }

    func clearProfile() throws {
        self.profile = nil
    }
}
