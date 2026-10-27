//
//  StoreServiceMocks.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation

/// Returns the whole look image instead of a crop. For previews and tests.
nonisolated struct MockGarmentCropper: GarmentCroppingProtocol {
    func makeGarmentCrop(for request: GarmentCropRequest) async throws -> GarmentCrop {
        GarmentCrop(image: request.lookImage)
    }
}
