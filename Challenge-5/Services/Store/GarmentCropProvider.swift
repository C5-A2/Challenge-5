//
//  GarmentCropProvider.swift
//  Challenge-5
//
//  Created by Natalie Grace on 26/10/26.
//

import CoreGraphics
import Foundation

/// Gives the crop for a garment of a look, shared by the "On this outfit" cards (Output)
/// and the Where to Buy sheet, so each garment is cropped only once.
@MainActor
final class GarmentCropProvider {

    // MARK: - Properties

    static let shared = GarmentCropProvider()

    private let cropper: any GarmentCroppingProtocol
    private let cropCache: GarmentCropCache
    /// Decoded look images by `OutfitLook.id`, so a look image is decoded once for all its garments.
    private var lookImagesByLookID: [UUID: CGImage] = [:]
    /// The image data each decoded look image came from, to notice when a look gets a new image.
    private var lookImageDataByLookID: [UUID: Data] = [:]

    // MARK: - Initializer

    /// Pass `nil` for `cropCache` to use `GarmentCropCache.shared`. The shared instance is read
    /// here instead of in a default argument, because default arguments aren't main-actor isolated.
    init(cropper: any GarmentCroppingProtocol = VisionGarmentCropper(), cropCache: GarmentCropCache? = nil) {
        self.cropper = cropper
        self.cropCache = cropCache ?? .shared
    }

    // MARK: - Cropping

    func crop(for garment: GarmentItem) async throws -> GarmentCrop {
        if let look = garment.outfitLook {
            discardCropsIfLookImageChanged(for: look)
        }
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

    /// Crops of several garments by garment ID. A garment that can't be cropped is left out,
    /// so its card keeps the placeholder.
    func crops(for garments: [GarmentItem]) async -> [UUID: GarmentCrop] {
        var cropsByGarmentID: [UUID: GarmentCrop] = [:]
        for garment in garments {
            cropsByGarmentID[garment.id] = try? await crop(for: garment)
        }
        return cropsByGarmentID
    }

    // MARK: - Look Image

    /// The decoded look image, cached by look so it's decoded only once.
    /// Only the look's own image is used (no mock placeholder): a look without a generated
    /// image can't be cropped, so its cards keep the placeholder icon.
    func lookImage(for look: OutfitLook) throws -> CGImage {
        discardCropsIfLookImageChanged(for: look)
        if let decodedImage = lookImagesByLookID[look.id] {
            return decodedImage
        }
        guard let data = look.lookImageData else { throw StoreError.lookImageUnavailable }
        guard let decodedImage = LookImageDecoder.makeImage(from: data) else { throw StoreError.lookImageDecodingFailed }
        lookImagesByLookID[look.id] = decodedImage
        lookImageDataByLookID[look.id] = data
        return decodedImage
    }

    /// When the look image changed since it was decoded (Image Playground generated a new one),
    /// the decoded image and the garments' crops are dropped, so new crops come from the new image.
    private func discardCropsIfLookImageChanged(for look: OutfitLook) {
        guard let decodedFromData = lookImageDataByLookID[look.id],
              decodedFromData != look.lookImageData else { return }
        lookImagesByLookID[look.id] = nil
        lookImageDataByLookID[look.id] = nil
        cropCache.removeCrops(forGarmentIDs: look.garments.map(\.id))
    }
}
