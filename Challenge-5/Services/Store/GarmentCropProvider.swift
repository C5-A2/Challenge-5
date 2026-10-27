//
//  GarmentCropProvider.swift
//  Challenge-5
//
//  Created by Natalie Grace on 26/10/26.
//

import CoreGraphics
import Foundation

/// Gives the crop for a garment of a look, shared by the "On this outfit" thumbnails
/// and the Where to Buy sheet, so each garment is cropped only once.
@MainActor
final class GarmentCropProvider {

    // MARK: - Properties

    static let shared = GarmentCropProvider()

    private let cropper: any GarmentCroppingProtocol
    private let cropCache: GarmentCropCache
    /// Decoded look images by `OutfitLook.id`, so a look image is decoded once for all its garments.
    private var lookImagesByLookID: [UUID: CGImage] = [:]

    // MARK: - Initializer

    /// Pass `nil` for `cropCache` to use `GarmentCropCache.shared`. The shared instance is read
    /// here instead of in a default argument, because default arguments aren't main-actor isolated.
    init(cropper: any GarmentCroppingProtocol = VisionGarmentCropper(), cropCache: GarmentCropCache? = nil) {
        self.cropper = cropper
        self.cropCache = cropCache ?? .shared
    }

    // MARK: - Cropping

    func crop(for garment: GarmentItem) async throws -> GarmentCrop {
        if let cachedCrop = cropCache.crop(forGarmentID: garment.id) {
            return cachedCrop
        }
        guard let look = garment.outfitLook else { throw StoreError.lookImageUnavailable }
        let lookImage = try lookImage(for: look)
        let hasOuterLayer = look.garments.contains { $0.category == .outer }
        let request = GarmentCropRequest(category: garment.category, lookImage: lookImage, hasOuterLayer: hasOuterLayer)
        let crop = try await cropper.makeGarmentCrop(for: request)
        cropCache.store(crop, forGarmentID: garment.id)
        return crop
    }

    // MARK: - Look Image

    /// The decoded look image, cached by look so it's decoded only once.
    func lookImage(for look: OutfitLook) throws -> CGImage {
        if let decodedImage = lookImagesByLookID[look.id] {
            return decodedImage
        }
        guard let data = look.lookImageData else { throw StoreError.lookImageUnavailable }
        guard let decodedImage = LookImageDecoder.makeImage(from: data) else { throw StoreError.lookImageDecodingFailed }
        lookImagesByLookID[look.id] = decodedImage
        return decodedImage
    }
}
