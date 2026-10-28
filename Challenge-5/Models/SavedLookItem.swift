//
//  SavedLookItem.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import Foundation
import SwiftUI

/// UI representation of a saved/bookmarked look in the Library.
///
/// Bridges directly with `OutfitLook` in SwiftData while providing standalone
/// support with rich mock data for Lofi development and previewing.
public struct SavedLookItem: Identifiable, Hashable, Sendable {
    
    // MARK: - Properties
    
    public let id: UUID
    public var occasionTitle: String
    public var dresscode: String
    public var date: Date
    public var lookIndex: Int
    public var isBookmarked: Bool
    public var fitRationale: String
    
    /// Stored image data for the avatar / outfit look.
    public var lookImageData: Data?
    
    /// Optional asset image name if bundled in Assets.
    public var assetImageName: String?
    
    /// Garments breakdown for this look.
    public var garments: [SavedGarmentItem]
    
    /// Height ratio / card height tier for asymmetric staggered layout (e.g. tall vs standard).
    public var cardHeightRatio: CGFloat
    
    // MARK: - Initializer
    
    public init(
        id: UUID = UUID(),
        occasionTitle: String,
        dresscode: String,
        date: Date = Date(),
        lookIndex: Int = 0,
        isBookmarked: Bool = true,
        fitRationale: String = "",
        lookImageData: Data? = nil,
        assetImageName: String? = nil,
        garments: [SavedGarmentItem] = [],
        cardHeightRatio: CGFloat = 1.35
    ) {
        self.id = id
        self.occasionTitle = occasionTitle
        self.dresscode = dresscode
        self.date = date
        self.lookIndex = lookIndex
        self.isBookmarked = isBookmarked
        self.fitRationale = fitRationale
        self.lookImageData = lookImageData
        self.assetImageName = assetImageName
        self.garments = garments
        self.cardHeightRatio = cardHeightRatio
    }
    
    // MARK: - Bridge Initializer from SwiftData OutfitLook
    
    init(
        outfitLook: OutfitLook,
        occasionTitle: String = "Occasion Outfit",
        dresscode: String = "Smart Casual",
        date: Date = Date(),
        cardHeightRatio: CGFloat = 1.35
    ) {
        self.id = outfitLook.id
        self.occasionTitle = occasionTitle
        self.dresscode = dresscode
        self.date = date
        self.lookIndex = outfitLook.lookIndex
        self.isBookmarked = outfitLook.isBookmarked
        self.fitRationale = outfitLook.fitRationale
        self.lookImageData = outfitLook.lookImageData
        self.assetImageName = nil
        self.garments = outfitLook.garments.map { SavedGarmentItem(from: $0) }
        self.cardHeightRatio = cardHeightRatio
    }
    
    // MARK: - Computed Properties
    
    public var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

/// Standalone garment representation for UI display in Library details.
public struct SavedGarmentItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var category: String
    public var name: String
    public var material: String
    public var colorName: String
    public var hexColor: String
    public var rationale: String = ""
    
    public init(
        id: UUID = UUID(),
        category: String,
        name: String,
        material: String,
        colorName: String,
        hexColor: String,
        rationale: String = ""
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.material = material
        self.colorName = colorName
        self.hexColor = hexColor
        self.rationale = rationale
    }
    
    init(from garment: GarmentItem) {
        self.id = garment.id
        self.category = garment.category.rawValue
        self.name = garment.name
        self.material = garment.material
        self.colorName = garment.colorName
        self.hexColor = garment.hexColor
        self.rationale = garment.rationale
    }
}

// MARK: - Sample Mock Data for Lofi Development

public extension SavedLookItem {
    static let samples: [SavedLookItem] = [
        SavedLookItem(
            id: UUID(),
            occasionTitle: "Cousin's Wedding",
            dresscode: "Formal Garden",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            lookIndex: 0,
            isBookmarked: true,
            fitRationale: "The dark French Terry polo balances shoulder proportions while burgundy tailored trousers elongate the vertical line.",
            garments: [
                SavedGarmentItem(category: "Top", name: "Polo", material: "french terry Cotton", colorName: "Black", hexColor: "#1C1C1E"),
                SavedGarmentItem(category: "Bottom", name: "Straight Chino Trousers", material: "Cotton Twill", colorName: "Burgundy", hexColor: "#581825"),
                SavedGarmentItem(category: "Outer", name: "Suede Harrington Jacket", material: "Brushed Suede", colorName: "Caramel Tan", hexColor: "#8D5B4C")
            ],
            cardHeightRatio: 1.55 // Tall card for left column in staggered layout
        ),
        SavedLookItem(
            id: UUID(),
            occasionTitle: "Gala Dinner",
            dresscode: "Black Tie Optional",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            lookIndex: 1,
            isBookmarked: true,
            fitRationale: "Structured peak lapels broaden the upper torso while high-waisted pleats create a balanced, commanding silhouette.",
            garments: [
                SavedGarmentItem(category: "Outer", name: "Peak Lapel Tuxedo Jacket", material: "Wool Mohair", colorName: "Midnight Navy", hexColor: "#1B2430"),
                SavedGarmentItem(category: "Top", name: "Pleated Dress Shirt", material: "Egyptian Cotton", colorName: "Crisp White", hexColor: "#F8F9FA"),
                SavedGarmentItem(category: "Bottom", name: "Satin Trim Dress Pants", material: "Fine Wool", colorName: "Midnight Navy", hexColor: "#1B2430")
            ],
            cardHeightRatio: 1.15 // Standard card for right column
        ),
        SavedLookItem(
            id: UUID(),
            occasionTitle: "Product Launch Keynote",
            dresscode: "Smart Casual",
            date: Calendar.current.date(byAdding: .day, value: -9, to: Date()) ?? Date(),
            lookIndex: 2,
            isBookmarked: true,
            fitRationale: "Unstructured blazer over a clean merino crew neck softens the chest line while maintaining executive polish.",
            garments: [
                SavedGarmentItem(category: "Outer", name: "Deconstructed Linen Blazer", material: "Linen Wool Blend", colorName: "Slate Grey", hexColor: "#4A5568"),
                SavedGarmentItem(category: "Top", name: "Fine Gauge Crewneck", material: "Extra-fine Merino", colorName: "Off White", hexColor: "#E2E8F0"),
                SavedGarmentItem(category: "Bottom", name: "Pleated Tapered Trousers", material: "Stretch Cotton", colorName: "Charcoal", hexColor: "#2D3748")
            ],
            cardHeightRatio: 1.20 // Standard card
        ),
        SavedLookItem(
            id: UUID(),
            occasionTitle: "Art Gallery Opening",
            dresscode: "Creative Cocktail",
            date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            lookIndex: 0,
            isBookmarked: true,
            fitRationale: "Earth-toned overshirt with relaxed drop-shoulder cut complements undertones and provides comfortable torso drape.",
            garments: [
                SavedGarmentItem(category: "Outer", name: "Boxy Wool Overshirt", material: "Boiled Wool", colorName: "Olive Sage", hexColor: "#556B2F"),
                SavedGarmentItem(category: "Top", name: "Ribbed Mockneck Tee", material: "Organic Ribbed Cotton", colorName: "Ecru", hexColor: "#F5F5DC"),
                SavedGarmentItem(category: "Bottom", name: "Wide Leg Denim", material: "Japanese Raw Selvedge", colorName: "Washed Indigo", hexColor: "#3B5998")
            ],
            cardHeightRatio: 1.50 // Tall card
        ),
        SavedLookItem(
            id: UUID(),
            occasionTitle: "Weekend Country Club Brunch",
            dresscode: "Casual Chic",
            date: Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date(),
            lookIndex: 3,
            isBookmarked: true,
            fitRationale: "Lightweight pastel knit polo with relaxed linen shorts maintains an approachable, warm appearance.",
            garments: [
                SavedGarmentItem(category: "Top", name: "Open Collar Polo", material: "Silk Cotton Blend", colorName: "Cream Sand", hexColor: "#F4EBD9"),
                SavedGarmentItem(category: "Bottom", name: "Pleated Linen Bermuda", material: "Pure French Linen", colorName: "Sage Green", hexColor: "#8A9A86")
            ],
            cardHeightRatio: 1.30 // Balanced card
        )
    ]
}
