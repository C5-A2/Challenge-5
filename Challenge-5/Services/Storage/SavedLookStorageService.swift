//
//  SavedLookStorageService.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

import Foundation
import SwiftData

/// Stores saved looks in SwiftData by updating `OutfitLook.isBookmarked` and `OutfitLook.savedAt`.
@MainActor
final class SavedLookStorageService: SavedLookStoring {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - SavedLookStoring

    func fetchSavedLooks() throws -> [OutfitLook] {
        let descriptor = FetchDescriptor<OutfitLook>(
            predicate: #Predicate<OutfitLook> { $0.isBookmarked },
            sortBy: [SortDescriptor(\OutfitLook.savedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw SavedLookStorageError.fetchFailed(underlying: error)
        }
    }

    func setSaved(_ isSaved: Bool, for look: OutfitLook) throws {
        if look.modelContext == nil {
            modelContext.insert(look)
        }
        look.isBookmarked = isSaved
        look.savedAt = isSaved ? Date() : nil
        do {
            try modelContext.save()
        } catch {
            throw SavedLookStorageError.saveFailed(underlying: error)
        }
    }
}

/// Keeps saved looks in memory only. For previews and tests.
@MainActor
final class MockSavedLookStorage: SavedLookStoring {

    // MARK: - Properties

    private var looks: [OutfitLook]

    // MARK: - Initializer

    init(looks: [OutfitLook] = []) {
        self.looks = looks
    }

    // MARK: - SavedLookStoring

    func fetchSavedLooks() throws -> [OutfitLook] {
        looks
            .filter(\.isBookmarked)
            .sorted { ($0.savedAt ?? .distantPast) > ($1.savedAt ?? .distantPast) }
    }

    func setSaved(_ isSaved: Bool, for look: OutfitLook) throws {
        if !looks.contains(where: { $0.id == look.id }) {
            looks.append(look)
        }
        look.isBookmarked = isSaved
        look.savedAt = isSaved ? Date() : nil
    }
}
