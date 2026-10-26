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
/// which builds image and keyword searches from this garment.
@Model
final class GarmentItem {

    // MARK: - Properties

    @Attribute(.unique) var id: UUID = UUID()
    var category: GarmentCategory
    var name: String                        // e.g. "Skinny Jeans"
    var material: String                    // e.g. "French Terry Cotton"
    var colorName: String                   // e.g. "Burgundy red"
    var hexColor: String                    // e.g. "#800020"
    //var purchaseURLString: String?          // deep link to e-commerce store

    /// The look this garment belongs to. Lets the store flow read the look image for cropping.
    var outfitLook: OutfitLook?

    // MARK: - Initializer

    init(
        category: GarmentCategory,
        name: String,
        material: String,
        colorName: String,
        hexColor: String,
        purchaseURLString: String? = nil
    ) {
        self.category = category
        self.name = name
        self.material = material
        self.colorName = colorName
        self.hexColor = hexColor
       // self.purchaseURLString = purchaseURLString
    }
}

/// Where a garment is worn on the body. `top` is the inner top layer under an `outer` piece.
nonisolated enum GarmentCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case outer = "Outer"
    case top = "Top"
    case bottom = "Bottom"

    var id: String { rawValue }
}
