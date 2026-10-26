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
    func makeGarmentCrop(for request: GarmentCropRequest) async throws -> CGImage {
        request.lookImage
    }
}

/// Pretends to upload and returns a fixed URL without using the network. For previews and tests.
nonisolated struct MockImageUploader: ImageUploadingProtocol {
    var isConfigured: Bool { true }

    func uploadImage(_ image: CGImage) async throws -> URL {
        guard let url = URL(string: "https://example.com/sample-garment.jpg") else {
            throw StoreError.uploadFailed
        }
        return url
    }
}
