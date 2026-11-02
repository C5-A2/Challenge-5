//
//  UserProfileStorageError.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 02/11/26.
//

import Foundation

/// Errors encountered during UserProfile persistence and SwiftData operations (C5-97).
enum UserProfileStorageError: LocalizedError, Sendable {
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to load user profile: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save user profile: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete user profile: \(error.localizedDescription)"
        case .profileNotFound:
            return "User profile not found in local storage."
        }
    }
}
