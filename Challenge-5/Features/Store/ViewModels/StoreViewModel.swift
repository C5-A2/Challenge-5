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
/// Flow: crop the garment from the look image, ask for upload consent once, upload the crop,
/// then open Google Lens. Marketplace keyword search (Tokopedia, Shopee, Zalora) is always available.
@Observable @MainActor
final class StoreViewModel {

    // MARK: - Types

    /// How the crop reaches Google Lens.
    nonisolated enum VisualSearchMethod: Equatable {
        /// Upload to imgbb, then open the Lens URL in Safari.
        case hostedImage
        /// Post the crop directly to Google Lens in `WKWebView` (no imgbb).
        case directUpload
    }

    nonisolated enum VisualSearchState: Equatable {
        case idle
        case cropping
        case uploading
        case ready(lensURL: URL)
        /// Image search can't be used for this garment; marketplace search still works.
        case unavailable(message: String)
        /// A step failed and can be retried.
        case failed(message: String)
    }

    // MARK: - Properties

    let garment: GarmentItem
    let searchKeyword: String
    let marketplaceLinks: [MarketplaceSearchLink]

    /// The cropped garment, shown so the user can check which part will be searched.
    private(set) var garmentCrop: CGImage?
    private(set) var visualSearchState: VisualSearchState = .idle
    var isShowingUploadConsent: Bool = false
    /// Set when a direct Google Lens upload is ready to show in the web view.
    var directLensPage: DirectLensPage?
    /// The method of the latest image search, used by consent and retry.
    private(set) var pendingSearchMethod: VisualSearchMethod = .hostedImage

    private let cropper: any GarmentCroppingProtocol
    private let uploader: any ImageUploadingProtocol
    private let cropCache: GarmentCropCache
    private let userDefaults: UserDefaults

    /// Image search needs the image of the user wearing the look.
    var canSearchByImage: Bool {
        garment.outfitLook?.lookImageData != nil
    }

    private var hasOuterLayer: Bool {
        garment.outfitLook?.garments.contains { $0.category == .outer } ?? false
    }

    var uploadConsentMessage: String {
        switch pendingSearchMethod {
        case .hostedImage:
            let minutes = StoreConstants.Upload.expirationSeconds / 60
            return "To find similar items, the cropped garment image is uploaded to imgbb for \(minutes) minutes and searched with Google Lens."
        case .directUpload:
            return "To find similar items, the cropped garment image is sent to Google Lens."
        }
    }

    private var hasGrantedUploadConsent: Bool {
        userDefaults.bool(forKey: StoreConstants.Consent.hasGrantedImageUploadKey)
    }

    // MARK: - Initializer

    init(
        garment: GarmentItem,
        cropper: any GarmentCroppingProtocol = VisionGarmentCropper(),
        uploader: any ImageUploadingProtocol = ImgbbImageUploader(),
        cropCache: GarmentCropCache = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.garment = garment
        self.cropper = cropper
        self.uploader = uploader
        self.cropCache = cropCache
        self.userDefaults = userDefaults
        let keyword = StoreSearchKeyword.makeKeyword(
            name: garment.name,
            material: garment.material,
            colorName: garment.colorName
        )
        self.searchKeyword = keyword
        self.marketplaceLinks = MarketplaceSearchLinkBuilder.makeLinks(for: keyword)
    }

    // MARK: - Actions

    /// Crops the garment from the look image. Reuses a cached crop when there is one.
    func prepareGarmentCrop() async {
        guard garmentCrop == nil else { return }
        if let cachedCrop = cropCache.crop(forGarmentID: garment.id) {
            garmentCrop = cachedCrop
            return
        }
        guard let lookImageData = garment.outfitLook?.lookImageData else {
            visualSearchState = .unavailable(message: StoreError.lookImageUnavailable.localizedDescription)
            return
        }
        guard let lookImage = LookImageDecoder.makeImage(from: lookImageData) else {
            visualSearchState = .unavailable(message: StoreError.lookImageDecodingFailed.localizedDescription)
            return
        }

        visualSearchState = .cropping
        let request = GarmentCropRequest(category: garment.category, lookImage: lookImage, hasOuterLayer: hasOuterLayer)
        do {
            let crop = try await cropper.makeGarmentCrop(for: request)
            cropCache.store(crop, forGarmentID: garment.id)
            garmentCrop = crop
            visualSearchState = .idle
        } catch {
            visualSearchState = .unavailable(message: error.localizedDescription)
        }
    }

    /// Starts image search, asking for upload consent the first time (C5-74).
    func requestVisualSearch(using method: VisualSearchMethod) async {
        pendingSearchMethod = method
        guard hasGrantedUploadConsent else {
            isShowingUploadConsent = true
            return
        }
        await startVisualSearch(using: method)
    }

    func grantUploadConsent() async {
        userDefaults.set(true, forKey: StoreConstants.Consent.hasGrantedImageUploadKey)
        isShowingUploadConsent = false
        await startVisualSearch(using: pendingSearchMethod)
    }

    func declineUploadConsent() {
        isShowingUploadConsent = false
        visualSearchState = .unavailable(message: "Image search is off. You can still search on the marketplaces below.")
    }

    /// Call after the Google Lens page is shown, so the next tap uploads a fresh crop
    /// (the previous upload expires after a few minutes).
    func markLensPageOpened() {
        visualSearchState = .idle
    }

    // MARK: - Private

    private func startVisualSearch(using method: VisualSearchMethod) async {
        switch method {
        case .hostedImage:
            await startHostedImageSearch()
        case .directUpload:
            await startDirectUploadSearch()
        }
    }

    private func startDirectUploadSearch() async {
        if garmentCrop == nil {
            await prepareGarmentCrop()
        }
        guard let crop = garmentCrop else { return }
        do {
            directLensPage = DirectLensPage(request: try LensDirectUploadRequestBuilder.makeRequest(for: crop))
            visualSearchState = .idle
        } catch {
            visualSearchState = .failed(message: error.localizedDescription)
        }
    }

    private func startHostedImageSearch() async {
        guard uploader.isConfigured else {
            visualSearchState = .unavailable(message: StoreError.uploadNotConfigured.localizedDescription)
            return
        }
        if garmentCrop == nil {
            await prepareGarmentCrop()
        }
        guard let crop = garmentCrop else { return }

        visualSearchState = .uploading
        do {
            let imageURL = try await uploader.uploadImage(crop)
            let lensURL = try GoogleLensURLBuilder.makeLensURL(forImageAt: imageURL)
            visualSearchState = .ready(lensURL: lensURL)
        } catch {
            visualSearchState = .failed(message: error.localizedDescription)
        }
    }
}
