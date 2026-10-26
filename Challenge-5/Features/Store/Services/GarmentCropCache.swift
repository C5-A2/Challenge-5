//
//  GarmentCropCache.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation

/// Keeps garment crops in memory by `GarmentItem.id`, so the same garment
/// isn't cropped again when the user reopens Where to Buy (C5-64).
@MainActor
final class GarmentCropCache {

    // MARK: - Properties

    static let shared = GarmentCropCache()

    private var cropsByGarmentID: [UUID: CGImage] = [:]

    // MARK: - Access

    func crop(forGarmentID garmentID: UUID) -> CGImage? {
        cropsByGarmentID[garmentID]
    }

    func store(_ crop: CGImage, forGarmentID garmentID: UUID) {
        cropsByGarmentID[garmentID] = crop
    }

    func removeAll() {
        cropsByGarmentID.removeAll()
    }
}
