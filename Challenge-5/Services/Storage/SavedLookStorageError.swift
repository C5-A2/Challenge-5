//
//  SavedLookStorageError.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

import Foundation

/// Errors when saving or loading saved looks, shown to the user through ViewModel state.
nonisolated enum SavedLookStorageError: LocalizedError {
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Couldn't load your saved looks. Try again."
        case .saveFailed:
            return "Couldn't update the saved look. Try again."
        }
    }
}
