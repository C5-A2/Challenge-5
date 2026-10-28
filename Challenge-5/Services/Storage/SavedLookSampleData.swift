//
//  SavedLookSampleData.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

import Foundation
import SwiftData

/// In-memory SwiftData sample for previewing the save → Library → reference flow.
/// One occasion with the 5 mock looks of `OccasionOutputViewModel` (garments + images).
@MainActor
enum SavedLookSampleData {

    // MARK: - Constants

    private static let savedIntervalSeconds: TimeInterval = 60 * 60

    // MARK: - Builders

    /// - Parameter savedLookCount: How many of the 5 looks start as saved (bookmarked).
    static func makeContainer(savedLookCount: Int = 2) -> ModelContainer {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: OccasionItem.self, OutfitLook.self, GarmentItem.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Couldn't create the saved look sample container: \(error)")
        }

        let context = container.mainContext
        let occasion = OccasionItem(
            title: "Cousin's Wedding",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            dresscode: "Smart Casual / Cocktail",
            visionKeywords: ["Confident", "Approachable", "Elegant"]
        )
        context.insert(occasion)

        // Same mock looks as the Output (with garments and images), so Library cards show garment names.
        for look in OccasionOutputViewModel.makeMockLooks() {
            let isSaved = look.lookIndex < savedLookCount
            look.isBookmarked = isSaved
            if isSaved {
                look.savedAt = Date().addingTimeInterval(-Double(look.lookIndex) * savedIntervalSeconds)
            }
            context.insert(look)
            occasion.generatedLooks.append(look)
        }

        do {
            try context.save()
        } catch {
            fatalError("Couldn't save the saved look sample data: \(error)")
        }
        return container
    }

    /// The sample occasion stored in `container`.
    static func occasion(in container: ModelContainer) -> OccasionItem {
        guard let occasion = try? container.mainContext.fetch(FetchDescriptor<OccasionItem>()).first else {
            fatalError("Saved look sample container has no occasion.")
        }
        return occasion
    }
}
