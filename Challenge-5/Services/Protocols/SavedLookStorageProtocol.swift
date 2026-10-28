//
//  SavedLookStorageProtocol.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

import Foundation

/// Saves and loads the looks the user bookmarked ("saved looks" in the Library).
///
/// A saved look is an `OutfitLook` with `isBookmarked == true` and a `savedAt` date.
@MainActor
protocol SavedLookStoring {
    /// Saved looks, newest first.
    func fetchSavedLooks() throws -> [OutfitLook]

    /// Saves or unsaves a look. Inserts the look into storage first if it isn't stored yet.
    func setSaved(_ isSaved: Bool, for look: OutfitLook) throws
}
