//
//  OutfitGarmentStripViewModel.swift
//  Challenge-5
//
//  Created by Natalie Grace on 26/10/26.
//

import Foundation
import Observation

/// Crops every garment of a look for the "On this outfit" thumbnails.
@Observable @MainActor
final class OutfitGarmentStripViewModel {

    // MARK: - Properties

    let look: OutfitLook
    private(set) var cropsByGarmentID: [UUID: GarmentCrop] = [:]
    private(set) var unavailableGarmentIDs: Set<UUID> = []

    private let cropProvider: GarmentCropProvider

    /// Garments in body order: outer, top, then bottom.
    var garments: [GarmentItem] {
        let order = GarmentCategory.allCases
        return look.garments.sorted {
            (order.firstIndex(of: $0.category) ?? 0) < (order.firstIndex(of: $1.category) ?? 0)
        }
    }

    // MARK: - Initializer

    /// Pass `nil` for `cropProvider` to use `GarmentCropProvider.shared`.
    init(look: OutfitLook, cropProvider: GarmentCropProvider? = nil) {
        self.look = look
        self.cropProvider = cropProvider ?? .shared
    }

    // MARK: - Actions

    /// Crops the garments one by one; thumbnails appear as each crop finishes.
    func loadCrops() async {
        for garment in garments
        where cropsByGarmentID[garment.id] == nil && !unavailableGarmentIDs.contains(garment.id) {
            do {
                cropsByGarmentID[garment.id] = try await cropProvider.crop(for: garment)
            } catch {
                unavailableGarmentIDs.insert(garment.id)
            }
        }
    }
}
