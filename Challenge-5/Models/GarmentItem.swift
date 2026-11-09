//
//  GarmentItem.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation
import SwiftData

/// A single garment inside a generated outfit look, shown on a flanking garment card.
///
/// Used by the result stage (`FlankingGarmentCard`) and the store flow (`WhereToBuySheet`),
/// which crops this garment from the look image and searches it with Google Lens.
@Model
final class GarmentItem {

    // MARK: - Properties

    @Attribute(.unique) var id: UUID = UUID()
    var category: GarmentCategory
    var name: String                        // e.g. "Skinny Jeans"
    var material: String                    // e.g. "French Terry Cotton"
    var colorName: String                   // e.g. "Burgundy red"
    var hexColor: String                    // e.g. "#800020"
    var rationale: String = ""              // Explains why this specific garment cut works on user's body silhouette
    var playgroundPrompt: String? = nil     // Direct visual prompt for Apple Image Playground

    /// The look this garment belongs to. Lets the store flow read the look image for cropping.
    var outfitLook: OutfitLook?

    // MARK: - Initializer

    init(
        category: GarmentCategory,
        name: String,
        material: String,
        colorName: String,
        hexColor: String,
        rationale: String = "",
        playgroundPrompt: String? = nil
    ) {
        self.category = category
        self.name = name
        self.material = material
        self.colorName = colorName
        self.hexColor = hexColor
        self.rationale = rationale
        self.playgroundPrompt = playgroundPrompt
    }
}

/// Where a garment is worn on the body. `top` is the inner top layer under an `outer` piece.
nonisolated enum GarmentCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case outer = "Outer"
    case top = "Top"
    case bottom = "Bottom"
    /// One-piece garment worn instead of a top and a bottom (dress, jumpsuit).
    case dress = "Dress"

    var id: String { rawValue }

    /// Order of the "On this outfit" cards, left to right: inner top (or dress), outer, bottom.
    static let outfitDisplayOrder: [GarmentCategory] = [.top, .dress, .outer, .bottom]

    /// Position in `outfitDisplayOrder`, for sorting.
    var outfitDisplayPosition: Int {
        Self.outfitDisplayOrder.firstIndex(of: self) ?? Self.outfitDisplayOrder.count
    }

    /// Words in an AI category label (or garment name) that point to each category.
    /// Dress is checked first, so "Shirt Dress" or "Coat Dress" is read as a dress.
    private static let generatedLabelKeywords: [(category: GarmentCategory, keywords: [String])] = [
        (.dress, ["dress", "jumpsuit", "gown", "romper", "playsuit", "one-piece", "swimsuit", "monokini"]),
        (.outer, ["outer", "jacket", "coat", "blazer", "cardigan", "bomber", "parka", "trench", "cover-up", "kimono"]),
        (.bottom, ["bottom", "pants", "trousers", "jeans", "skirt", "shorts", "chinos", "culottes", "leggings"]),
        (.top, ["top", "inner", "shirt", "blouse", "tee", "polo", "knit", "sweater", "tank", "camisole", "turtleneck"])
    ]

    /// Reads a category from the AI's label, which isn't always exactly "Outer" / "Top" / "Bottom"
    /// ("Outerwear", "Inner", "Pants"). `nil` for pieces outside the categories (shoes, accessories),
    /// instead of treating them as a top, which made the crop and the label not match.
    init?(generatedLabel: String) {
        let label = generatedLabel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let exactCategory = GarmentCategory.allCases.first(where: { $0.rawValue.lowercased() == label }) {
            self = exactCategory
            return
        }
        guard let match = Self.generatedLabelKeywords.first(where: { entry in
            entry.keywords.contains { label.contains($0) }
        }) else { return nil }
        self = match.category
    }
}

// MARK: - Outfit Display Order

extension Array where Element == GarmentItem {
    /// Left to right like the "On this outfit" cards: inner top (or dress), outer, bottom.
    /// SwiftData doesn't keep relationship order, so garments are sorted before showing them.
    func sortedForOutfitDisplay() -> [GarmentItem] {
        sorted { $0.category.outfitDisplayPosition < $1.category.outfitDisplayPosition }
    }
}
