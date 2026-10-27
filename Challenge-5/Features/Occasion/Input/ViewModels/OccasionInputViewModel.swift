//
//  OccasionInputViewModel.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

/// ViewModel managing state, validation, and submission for the Occasion Input flow.
///
/// Follows the Observation framework conventions (`@Observable @MainActor`)
/// and validates input for occasion title, date, and dress code.
@Observable 
public final class OccasionInputViewModel {
    
    // MARK: - Date Helpers
    
    /// Default date representing tomorrow.
    public nonisolated static var defaultTomorrowDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    // MARK: - Properties
    
    /// The user-defined title for the occasion (e.g., "Gala Dinner", "Wedding Reception"). Required.
    public var title: String = ""
    
    /// The scheduled date for the occasion. Defaults to tomorrow and cannot be in the past.
    public var date: Date = OccasionInputViewModel.defaultTomorrowDate
    
    /// The specified dress code (e.g., "Formal", "Black Tie", "Smart Casual"). Optional.
    public var dresscode: String = ""
    
    /// Desired emotional style impressions selected by the user. Min 0, Max 3.
    public var selectedVisions: Set<StyleVision> = []
    
    /// Outfit reference photos (JPEG) from the camera, photo library, or saved looks. Optional, Max 3.
    public var referenceImages: [Data] = []
    
    /// Presentation state of the three reference sources (Camera, Open from Photos, From Library).
    public var isShowingReferenceCamera: Bool = false
    public var isShowingReferencePhotoPicker: Bool = false
    public var isShowingReferenceLibrary: Bool = false
    
    /// Photos picked in "Open from Photos", loaded into `referenceImages` by `loadPickedReferencePhotos()`.
    public var referencePhotoPickerItems: [PhotosPickerItem] = []
    public private(set) var isLoadingReferencePhotos: Bool = false
    
    /// Reference camera state. Reset each time the camera opens, and released when it closes.
    public private(set) var referenceCameraService: CameraService?
    public private(set) var capturedReferenceImage: UIImage?
    public private(set) var isCapturingReference: Bool = false
    public private(set) var referenceCameraErrorMessage: String?
    
    /// Controls presentation of the discard confirmation alert when canceling with unsaved changes.
    public var isShowingDiscardAlert: Bool = false
    
    // MARK: - Initial State Tracking (For Unsaved Changes Detection)
    
    private var initialTitle: String
    private var initialDate: Date
    private var initialDresscode: String
    private var initialVisions: Set<StyleVision>
    private var initialReferenceImages: [Data]
    
    // MARK: - Initializers
    
    public init(
        title: String = "",
        date: Date = OccasionInputViewModel.defaultTomorrowDate,
        dresscode: String = "",
        selectedVisions: Set<StyleVision> = [],
        referenceImages: [Data] = []
    ) {
        self.title = title
        self.date = date
        self.dresscode = dresscode
        self.selectedVisions = selectedVisions
        self.referenceImages = referenceImages
        
        self.initialTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialDate = date
        self.initialDresscode = dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialVisions = selectedVisions
        self.initialReferenceImages = referenceImages
    }
    
    public init(from occasion: OccasionDetail) {
        self.title = occasion.title
        self.date = occasion.date
        self.dresscode = occasion.dresscode
        self.selectedVisions = Set(occasion.visions)
        self.referenceImages = occasion.referenceImages
        
        self.initialTitle = occasion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialDate = occasion.date
        self.initialDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialVisions = Set(occasion.visions)
        self.initialReferenceImages = occasion.referenceImages
    }
    
    init(from occasion: OccasionItem) {
        self.title = occasion.title
        self.date = occasion.date
        self.dresscode = occasion.dresscode
        self.selectedVisions = Set(occasion.visions)
        self.referenceImages = occasion.referenceImagesData
        
        self.initialTitle = occasion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialDate = occasion.date
        self.initialDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialVisions = Set(occasion.visions)
        self.initialReferenceImages = occasion.referenceImagesData
    }
    
    // MARK: - Computed Properties
    
    /// Checks whether the occasion date is in the past (prior to today; today is allowed).
    public var isDateInPast: Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
    
    /// Checks whether the required occasion fields are valid:
    /// - Occasion `title` must be non-empty (required).
    /// - `date` cannot be in the past.
    /// - `selectedVisions` count must be between 0 and 3 (min 0, max 3).
    /// - `referenceImages` count must be between 0 and 3 (min 0, max 3).
    /// - `dresscode` is optional.
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isDateInPast &&
        selectedVisions.count <= 3 &&
        referenceImages.count <= ReferencePickerConstants.maximumReferenceCount
    }
    
    /// Indicates whether the user has modified any field from its initial state.
    public var hasUnsavedChanges: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines) != initialTitle ||
        dresscode.trimmingCharacters(in: .whitespacesAndNewlines) != initialDresscode ||
        selectedVisions != initialVisions ||
        referenceImages != initialReferenceImages ||
        !Calendar.current.isDate(date, inSameDayAs: initialDate)
    }
    
    /// Formatted date string for accessibility and display purposes.
    public var formattedDateString: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Whether additional visions can be selected before reaching the maximum limit of 3.
    public var canSelectMoreVisions: Bool {
        selectedVisions.count < 3
    }
    
    /// How many more reference photos can be added before reaching the maximum of 3.
    public var remainingReferenceCount: Int {
        max(0, ReferencePickerConstants.maximumReferenceCount - referenceImages.count)
    }
    
    /// Whether another reference photo can be added.
    public var canAddMoreReferences: Bool {
        remainingReferenceCount > 0
    }
    
    public var hasCapturedReference: Bool {
        capturedReferenceImage != nil
    }
    
    /// Without camera access, `CameraService` would return a test image, so capture is blocked.
    /// The Simulator has no camera, so its test image is allowed there.
    public var canCaptureReference: Bool {
        guard let referenceCameraService, !isCapturingReference else { return false }
        #if targetEnvironment(simulator)
        return referenceCameraService.isRunning
        #else
        return referenceCameraService.permissionGranted
        #endif
    }
    
    // MARK: - Actions
    
    /// Toggles selection state of a given `StyleVision`.
    /// Caps selection at a maximum of 3 items (minimum 0).
    public func toggleVision(_ vision: StyleVision) {
        if selectedVisions.contains(vision) {
            selectedVisions.remove(vision)
        } else {
            guard selectedVisions.count < 3 else { return }
            selectedVisions.insert(vision)
        }
    }
    
    /// Checks if a vision is currently selected.
    public func isVisionSelected(_ vision: StyleVision) -> Bool {
        selectedVisions.contains(vision)
    }
    
    /// Checks whether a vision chip can be tapped (either selected or limit not yet reached).
    public func canSelectVision(_ vision: StyleVision) -> Bool {
        selectedVisions.contains(vision) || selectedVisions.count < 3
    }
    
    // MARK: - Reference Actions
    
    /// Opens the camera, the user's photo library, or the app's saved looks.
    public func selectReferenceSource(_ option: ImageSourceOption) {
        switch option {
        case .camera:
            isShowingReferenceCamera = true
        case .photoLibrary:
            isShowingReferencePhotoPicker = true
        case .savedLibrary:
            isShowingReferenceLibrary = true
        }
    }
    
    /// Adds reference photos after the existing ones, keeping at most 3.
    public func addReferenceImages(_ newImages: [Data]) {
        referenceImages = Array((referenceImages + newImages).prefix(ReferencePickerConstants.maximumReferenceCount))
    }
    
    public func removeReferenceImage(at index: Int) {
        guard referenceImages.indices.contains(index) else { return }
        referenceImages.remove(at: index)
    }
    
    /// Loads the photos picked in "Open from Photos" as reference JPEGs and adds them.
    public func loadPickedReferencePhotos() async {
        let pickedItems = referencePhotoPickerItems
        guard !pickedItems.isEmpty else { return }
        referencePhotoPickerItems = []
        isLoadingReferencePhotos = true
        defer { isLoadingReferencePhotos = false }
        
        var pickedImages: [Data] = []
        for item in pickedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let referenceData = ReferenceImageEncoder.makeJPEGData(from: data) {
                pickedImages.append(referenceData)
            }
        }
        addReferenceImages(pickedImages)
    }
    
    /// Bookmarked looks with an image, shown in "From Library".
    func savedReferenceLooks(from outfitLooks: [OutfitLook]) -> [SavedLookItem] {
        outfitLooks
            .filter { $0.lookImageData != nil }
            .map { SavedLookItem(outfitLook: $0) }
    }
    
    /// Adds the looks picked in "From Library" as reference photos.
    public func addReferenceImages(from savedLooks: [SavedLookItem]) {
        addReferenceImages(savedLooks.compactMap { $0.lookImageData.flatMap(ReferenceImageEncoder.makeJPEGData) })
    }
    
    // MARK: - Reference Camera Actions
    
    /// Starts a fresh camera session on the back camera, since references are usually of other outfits.
    public func startReferenceCamera() async {
        capturedReferenceImage = nil
        referenceCameraErrorMessage = nil
        let cameraService = CameraService()
        referenceCameraService = cameraService
        do {
            try await cameraService.startSession()
            if cameraService.permissionGranted, cameraService.cameraPosition == .front {
                try await cameraService.switchCamera()
            }
        } catch {
            referenceCameraErrorMessage = "Couldn't start the camera."
        }
        #if !targetEnvironment(simulator)
        if !cameraService.permissionGranted {
            referenceCameraErrorMessage = "Camera access is off. Turn it on in Settings, or pick a photo from your gallery."
        }
        #endif
    }
    
    /// Stops the camera session and clears the camera state.
    public func stopReferenceCamera() {
        referenceCameraService?.stopSession()
        referenceCameraService = nil
        capturedReferenceImage = nil
        isCapturingReference = false
        referenceCameraErrorMessage = nil
    }
    
    public func captureReferencePhoto() async {
        guard let referenceCameraService, canCaptureReference else { return }
        isCapturingReference = true
        defer { isCapturingReference = false }
        do {
            capturedReferenceImage = try await referenceCameraService.capturePhoto()
        } catch {
            referenceCameraErrorMessage = "Couldn't take the photo. Try again."
        }
    }
    
    public func retakeReferencePhoto() {
        capturedReferenceImage = nil
    }
    
    /// Adds the captured photo to `referenceImages`. Returns `false` if there is nothing to add.
    @discardableResult
    public func confirmCapturedReference() -> Bool {
        guard let referenceData = capturedReferenceImage?
            .jpegData(compressionQuality: 1)
            .flatMap(ReferenceImageEncoder.makeJPEGData) else { return false }
        addReferenceImages([referenceData])
        return true
    }
    
    /// Adds a photo picked from the camera's gallery button. Returns `false` if it couldn't be loaded.
    @discardableResult
    public func addGalleryReference(_ item: PhotosPickerItem) async -> Bool {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let referenceData = ReferenceImageEncoder.makeJPEGData(from: data) else { return false }
        addReferenceImages([referenceData])
        return true
    }
    
    // MARK: - Submission
    
    /// Builds an `OccasionDetail` model populated with the current form values.
    public func createOccasionDetail() -> OccasionDetail {
        OccasionDetail(
            date: date,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dresscode: dresscode.trimmingCharacters(in: .whitespacesAndNewlines),
            referenceImages: referenceImages,
            visions: Array(selectedVisions)
        )
    }
    
    /// Resets all input fields back to their initial state with tomorrow's date.
    public func reset() {
        title = ""
        date = Self.defaultTomorrowDate
        dresscode = ""
        selectedVisions = []
        referenceImages = []
        referencePhotoPickerItems = []
        isShowingDiscardAlert = false
    }
}
