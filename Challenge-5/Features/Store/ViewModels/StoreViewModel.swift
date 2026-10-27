//
//  StoreViewModel.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation
import Observation

/// Drives the "Where to Buy" flow for one garment of a generated look (C5-65).
///
/// Flow: crop the garment from the look image, ask for upload consent once,
/// then show Google Lens results for the crop.
@Observable @MainActor
final class StoreViewModel {

    // MARK: - Types

    nonisolated enum VisualSearchState: Equatable {
        case idle
        case cropping
        /// Image search can't be used for this garment.
        case unavailable(message: String)
        /// A step failed and can be retried.
        case failed(message: String)
    }

    // MARK: - Properties

    let garment: GarmentItem
    /// Sheet title, for example "Black Polo French Terry Cotton".
    let sheetTitle: String

    /// The cropped garment that is sent to Google Lens.
    private(set) var garmentCrop: GarmentCrop?
    private(set) var visualSearchState: VisualSearchState = .idle
    var isShowingUploadConsent: Bool = false
    /// Set when the Google Lens upload is ready to show in the web view.
    var lensPage: LensPage?
    /// Result of "Save to Photos", shown in an alert.
    private(set) var photoSaveMessage: String?
    var isShowingPhotoSaveResult: Bool = false

    private let cropProvider: GarmentCropProvider
    private let userDefaults: UserDefaults

    private var hasGrantedUploadConsent: Bool {
        userDefaults.bool(forKey: StoreConstants.Consent.hasGrantedImageUploadKey)
    }

    // MARK: - Initializer

    /// Pass `nil` for `cropProvider` to use `GarmentCropProvider.shared`.
    init(
        garment: GarmentItem,
        cropProvider: GarmentCropProvider? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.garment = garment
        self.cropProvider = cropProvider ?? .shared
        self.userDefaults = userDefaults
        self.sheetTitle = GarmentTitleBuilder.makeTitle(from: [garment.colorName, garment.name, garment.material])
    }

    // MARK: - Actions

    /// Crops the garment, then opens Google Lens right away when the user already allowed uploads.
    func loadInitialContent() async {
        await prepareGarmentCrop()
        #if os(iOS)
        if hasGrantedUploadConsent, garmentCrop != nil, lensPage == nil {
            await startLensSearch()
        }
        #endif
    }

    /// Starts the Google Lens search, asking for upload consent the first time (C5-74).
    func requestLensSearch() async {
        guard hasGrantedUploadConsent else {
            isShowingUploadConsent = true
            return
        }
        await startLensSearch()
    }

    func grantUploadConsent() async {
        userDefaults.set(true, forKey: StoreConstants.Consent.hasGrantedImageUploadKey)
        isShowingUploadConsent = false
        await startLensSearch()
    }

    func declineUploadConsent() {
        isShowingUploadConsent = false
        visualSearchState = .unavailable(message: "Image search is off. Tap Search with Google Lens to allow it.")
    }

    /// Saves the garment crop to the photo library ("Save to Photos").
    func saveGarmentCropToPhotos() async {
        #if os(iOS)
        guard let crop = garmentCrop else { return }
        do {
            try await GarmentPhotoSaver.save(crop.image)
            photoSaveMessage = "Saved to Photos."
        } catch {
            photoSaveMessage = error.localizedDescription
        }
        isShowingPhotoSaveResult = true
        #endif
    }

    // MARK: - Private

    /// Crops the garment from the look image. Reuses a cached crop when there is one.
    private func prepareGarmentCrop() async {
        guard garmentCrop == nil else { return }
        visualSearchState = .cropping
        do {
            garmentCrop = try await cropProvider.crop(for: garment)
            visualSearchState = .idle
        } catch {
            visualSearchState = .unavailable(message: error.localizedDescription)
        }
    }

    private func startLensSearch() async {
        if garmentCrop == nil {
            await prepareGarmentCrop()
        }
        guard let crop = garmentCrop else { return }
        do {
            lensPage = LensPage(request: try LensUploadRequestBuilder.makeRequest(for: crop.image))
            visualSearchState = .idle
        } catch {
            visualSearchState = .failed(message: error.localizedDescription)
        }
    }
}
