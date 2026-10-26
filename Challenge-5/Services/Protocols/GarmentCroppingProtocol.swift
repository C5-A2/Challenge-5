//
//  GarmentCroppingProtocol.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics

/// What the store flow needs to crop one garment out of a look image.
nonisolated struct GarmentCropRequest: Sendable {

    // MARK: - Properties

    let category: GarmentCategory
    /// Image of the user wearing the look.
    let lookImage: CGImage
    /// `true` when the look also has an outer piece, so a `.top` crop must target the inner layer.
    let hasOuterLayer: Bool
}

/// Crops a single garment (outer, top, or bottom) from a look image for visual search.
nonisolated protocol GarmentCroppingProtocol: Sendable {
    func makeGarmentCrop(for request: GarmentCropRequest) async throws -> CGImage
}
