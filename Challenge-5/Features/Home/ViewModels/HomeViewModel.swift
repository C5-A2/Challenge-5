//
//  HomeViewModel.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import Foundation
import Observation
import SwiftData

/// ViewModel for managing state, modals, and SwiftData operations on the Occasions Home screen.
@Observable @MainActor
final class HomeViewModel {
    
    // MARK: - Modal States
    
    var isShowingNewOccasionSheet: Bool = false
    var isShowingHistorySheet: Bool = false
    var isShowingProfileSheet: Bool = false
    var selectedOccasion: OccasionItem? = nil
    
    // MARK: - SwiftData Operations
    
    func saveOccasion(from detail: OccasionDetail, in context: ModelContext) {
        let newOccasion = OccasionItem(from: detail)
        context.insert(newOccasion)
        do {
            try context.save()
        } catch {
            print("HomeViewModel: Failed to save occasion: \(error.localizedDescription)")
        }
    }
    
    func deleteOccasion(_ occasion: OccasionItem, in context: ModelContext) {
        context.delete(occasion)
        do {
            try context.save()
        } catch {
            print("HomeViewModel: Failed to delete occasion: \(error.localizedDescription)")
        }
    }
}
