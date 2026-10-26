//
//  StoreSampleData.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation
import SwiftData

/// Dummy looks for testing the store flow before real generated looks exist.
///
/// The two sample photos are placeholders for local testing only.
/// Replace them with the team's own generated look images before release.
@MainActor
enum StoreSampleData {

    // MARK: - Types

    private struct SampleLook {
        let lookIndex: Int
        let imageName: String
        let imageExtension: String
        let garments: [SampleGarment]
    }

    private struct SampleGarment {
        let category: GarmentCategory
        let name: String
        let material: String
        let colorName: String
        let hexColor: String
    }

    // MARK: - Public Data

    /// In-memory container holding the sample looks and garments.
    static let container: ModelContainer = makeContainer()

    static var looks: [OutfitLook] {
        let descriptor = FetchDescriptor<OutfitLook>(sortBy: [SortDescriptor(\.lookIndex)])
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }

    /// The bottom of the first sample look.
    static var sampleGarment: GarmentItem {
        looks.first?.garments.first { $0.category == .bottom }
            ?? GarmentItem(category: .bottom, name: "Skinny Jeans", material: "Jeans",
                           colorName: "Burgundy red", hexColor: "#800020")
    }

    // MARK: - Sample Definitions

    private static let sampleLooks: [SampleLook] = [
        SampleLook(
            lookIndex: 0,
            imageName: "store-sample-denim-look",
            imageExtension: "jpeg",
            garments: [
                SampleGarment(category: .outer, name: "Monogram Denim Jacket", material: "Denim",
                              colorName: "Blue", hexColor: "#3B5B8C"),
                SampleGarment(category: .top, name: "Crew Neck T-Shirt", material: "Cotton",
                              colorName: "White", hexColor: "#FFFFFF"),
                SampleGarment(category: .bottom, name: "Monogram Denim Trousers", material: "Denim",
                              colorName: "Blue", hexColor: "#3B5B8C")
            ]
        ),
        SampleLook(
            lookIndex: 1,
            imageName: "store-sample-polo-look",
            imageExtension: "jpg",
            garments: [
                SampleGarment(category: .top, name: "Rugby Stripe Polo", material: "Cotton",
                              colorName: "Navy white", hexColor: "#1F2A44"),
                SampleGarment(category: .bottom, name: "Chino Pants", material: "Cotton Twill",
                              colorName: "Beige", hexColor: "#D8CBB0")
            ]
        )
    ]

    // MARK: - Builders

    private static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: OutfitLook.self, GarmentItem.self, configurations: configuration)
        } catch {
            fatalError("Couldn't create the store sample container: \(error)")
        }

        let context = container.mainContext
        for sampleLook in sampleLooks {
            let look = OutfitLook(
                lookIndex: sampleLook.lookIndex,
                lookImageData: imageData(named: sampleLook.imageName, withExtension: sampleLook.imageExtension)
            )
            context.insert(look)
            for sampleGarment in sampleLook.garments {
                let garment = GarmentItem(
                    category: sampleGarment.category,
                    name: sampleGarment.name,
                    material: sampleGarment.material,
                    colorName: sampleGarment.colorName,
                    hexColor: sampleGarment.hexColor
                )
                context.insert(garment)
                look.garments.append(garment)
            }
        }
        return container
    }

    private static func imageData(named name: String, withExtension fileExtension: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else { return nil }
        return try? Data(contentsOf: url)
    }
}
