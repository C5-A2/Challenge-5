//
//  LibraryViewModel.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI
import SwiftData
import Observation

/// View model managing saved looks, asymmetric grid presentation,
/// unsave/delete logic, and reference picker selection.
@Observable
public final class LibraryViewModel {
    
    // MARK: - Published Properties
    
    public var savedLooks: [SavedLookItem] = []
    
    // Reference Picker Flow State [C5-105]
    public var selectedReferenceLookIds: Set<UUID> = []
    
    // Filter & Search
    public var searchQuery: String = ""
    public var selectedDresscodeFilter: String? = nil
    
    // Loading State
    public var isLoading: Bool = false
    
    /// Shown when saving or unsaving a look fails.
    public var saveErrorMessage: String? = nil
    
    // Saved-look storage, set by `fetchSavedLooksFromContext(_:)`.
    private var savedLookStorage: (any SavedLookStoring)?
    /// Stored looks behind `savedLooks`, so bookmark changes are saved to SwiftData.
    private var outfitLooksByID: [UUID: OutfitLook] = [:]
    
    // MARK: - Initializer
    
    public init(initialLooks: [SavedLookItem] = SavedLookItem.samples) {
        self.savedLooks = initialLooks
    }
    
    // MARK: - Computed Properties
    
    /// Looks filtered by search query and dresscode
    public var filteredLooks: [SavedLookItem] {
        var result = savedLooks.filter { $0.isBookmarked }
        
        if let filter = selectedDresscodeFilter, !filter.isEmpty {
            result = result.filter { $0.dresscode.localizedCaseInsensitiveContains(filter) }
        }
        
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.filter { look in
                look.occasionTitle.localizedCaseInsensitiveContains(searchQuery) ||
                look.dresscode.localizedCaseInsensitiveContains(searchQuery) ||
                look.garments.contains { $0.name.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
        
        return result
    }
    
    public var isEmpty: Bool {
        filteredLooks.isEmpty
    }
    
    public var totalSavedCount: Int {
        savedLooks.filter { $0.isBookmarked }.count
    }
    
    // MARK: - Bookmark & Delete Actions [C5-102, C5-107]
    
    /// Toggles the bookmark status for a look. If unsaved in LibraryView, animates removal.
    public func toggleBookmark(for look: SavedLookItem) {
        guard let index = savedLooks.firstIndex(where: { $0.id == look.id }) else { return }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            savedLooks[index].isBookmarked.toggle()
        }
        persistSavedState(savedLooks[index].isBookmarked, forLookID: look.id)
    }
    
    /// Unsave and remove a look directly from the library collection
    public func unsaveLook(id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if let index = savedLooks.firstIndex(where: { $0.id == id }) {
                savedLooks[index].isBookmarked = false
                savedLooks.remove(at: index)
            }
        }
        persistSavedState(false, forLookID: id)
    }
    
    /// Saves a bookmark change to SwiftData. Sample looks (no stored look) stay in memory only.
    private func persistSavedState(_ isSaved: Bool, forLookID lookID: UUID) {
        guard let savedLookStorage, let outfitLook = outfitLooksByID[lookID] else { return }
        do {
            try savedLookStorage.setSaved(isSaved, for: outfitLook)
            saveErrorMessage = nil
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Reference Picker Actions [C5-105]
    
    /// Toggle selection of a look when using the reference picker sheet
    public func toggleReferenceSelection(for id: UUID, allowsMultiple: Bool = false) {
        if allowsMultiple {
            if selectedReferenceLookIds.contains(id) {
                selectedReferenceLookIds.remove(id)
            } else {
                selectedReferenceLookIds.insert(id)
            }
        } else {
            if selectedReferenceLookIds.contains(id) {
                selectedReferenceLookIds.removeAll()
            } else {
                selectedReferenceLookIds = [id]
            }
        }
    }
    
    public func isReferenceSelected(id: UUID) -> Bool {
        selectedReferenceLookIds.contains(id)
    }
    
    public var selectedReferenceLooks: [SavedLookItem] {
        savedLooks.filter { selectedReferenceLookIds.contains($0.id) }
    }
    
    public func clearReferenceSelection() {
        selectedReferenceLookIds.removeAll()
    }
    
    // MARK: - Lofi Testing Helpers
    
    /// Re-populates mock looks for Lofi testing when list becomes empty
    public func loadSampleLooks() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.savedLooks = SavedLookItem.samples
        }
    }
    
    // MARK: - SwiftData Integration Hook [C5-100 Ready]
    
    /// The stored occasion behind a saved look and the look's position in it,
    /// so the Output opens the real looks (with their saved state) instead of new mock looks.
    func outputDestination(for look: SavedLookItem) -> (occasion: OccasionItem, lookIndex: Int)? {
        guard let occasion = outfitLooksByID[look.id]?.occasion else { return nil }
        let orderedLooks = occasion.generatedLooks.sorted { $0.lookIndex < $1.lookIndex }
        let lookIndex = orderedLooks.firstIndex { $0.id == look.id } ?? 0
        return (occasion: occasion, lookIndex: lookIndex)
    }
    
    /// Loads bookmarked looks from SwiftData context when available
    public func fetchSavedLooksFromContext(_ context: ModelContext) {
        loadSavedLooks(using: SavedLookStorageService(modelContext: context))
    }
    
    /// Loads saved looks (newest first) through `SavedLookStoring`.
    /// Keeps the sample looks when nothing is saved yet (Lofi testing).
    func loadSavedLooks(using storage: any SavedLookStoring) {
        savedLookStorage = storage
        do {
            let fetched = try storage.fetchSavedLooks()
            // Looks were shown from storage before, so an empty fetch means all were unsaved.
            let didShowStoredLooks = !outfitLooksByID.isEmpty
            outfitLooksByID = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
            if fetched.isEmpty && didShowStoredLooks {
                self.savedLooks = []
            } else if !fetched.isEmpty {
                self.savedLooks = fetched.enumerated().map { index, outfitLook in
                    SavedLookItem(
                        outfitLook: outfitLook,
                        cardHeightRatio: index.isMultiple(of: 2) ? 1.5 : 1.2
                    )
                }
            }
        } catch {
            print("Failed to fetch saved looks from SwiftData: \(error)")
        }
    }
}
