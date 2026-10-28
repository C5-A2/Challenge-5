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
    var editingOccasion: OccasionItem? = nil
    var errorMessage: String? = nil
    var isShowingErrorAlert: Bool = false
    
    // MARK: - SwiftData Operations
    
    @discardableResult
    func saveOccasion(
        from detail: OccasionDetail,
        profile: UserProfile? = nil,
        in context: ModelContext
    ) -> OccasionItem {
        let newOccasion = OccasionItem(from: detail)
        context.insert(newOccasion)
        
        // Generate the 5 outfit looks with individual garment rationales
        let activeProfile = profile ?? UserProfile.mockSample
        do {
            let looks = try OutfitGenerationPipeline.shared.generateLooksSync(for: newOccasion, profile: activeProfile)
            newOccasion.generatedLooks = looks
            for look in looks {
                context.insert(look)
                for garment in look.garments {
                    context.insert(garment)
                }
            }
        } catch {
            let errorMsg = error.localizedDescription
            print("\n❌ [HomeViewModel] LLaMA CANNOT BE USED: \(errorMsg)\n")
            self.errorMessage = errorMsg
            self.isShowingErrorAlert = true
        }
        
        do {
            try context.save()
        } catch {
            print("HomeViewModel: Failed to save occasion: \(error.localizedDescription)")
        }
        return newOccasion
    }
    
    func updateOccasion(_ occasion: OccasionItem, with detail: OccasionDetail, in context: ModelContext) {
        occasion.title = detail.title
        occasion.date = detail.date
        occasion.dresscode = detail.dresscode
        occasion.visionKeywords = detail.visions.map(\.rawValue)
        // Always update, so removing every reference photo is saved too.
        occasion.referenceImagesData = detail.referenceImages
        occasion.referenceImageData = detail.referenceImages.first
        do {
            try context.save()
        } catch {
            print("HomeViewModel: Failed to update occasion: \(error.localizedDescription)")
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
