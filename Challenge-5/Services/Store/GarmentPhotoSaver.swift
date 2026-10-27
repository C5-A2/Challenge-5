//
//  GarmentPhotoSaver.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

#if os(iOS)
import CoreGraphics
import Photos
import UIKit

/// Saves a garment crop to the user's photo library ("Save to Photos" in Where to Buy).
///
/// Uses add-only access, so the app can save images without reading the library.
/// Needs `NSPhotoLibraryAddUsageDescription` in the app's Info.plist.
nonisolated enum GarmentPhotoSaver {

    static func save(_ image: CGImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw StoreError.photoLibraryAccessDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: UIImage(cgImage: image))
            }
        } catch {
            throw StoreError.photoSaveFailed
        }
    }
}
#endif
