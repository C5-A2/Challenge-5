//
//  OccasionOutputViewModel.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI
import SwiftData

enum FitRationaleTab: String, CaseIterable, Identifiable, Sendable {
    case bodyShape = "Body type"
    case colorAnalyze = "Color Analyze"
    case torso = "Torso"
    
    var id: String { rawValue }
}

@Observable
@MainActor
final class OccasionOutputViewModel {
    
    var profile: UserProfile? = nil
    
    var occasion: OccasionItem
    
    var looks: [OutfitLook] = []
    
    var selectedLookIndex: Int = 0
    
    var selectedFitTab: FitRationaleTab = .bodyShape
    
    var isDetailsDrawerExpanded: Bool = false
    
    var isLoading: Bool = false
    
    /// Extracted VLM styling descriptions (1-by-1 per reference photo) displayed as debug output on `OccasionOutputView`.
    var vlmDebugDescriptions: [String] = []
    
    /// Dynamic stage title shown inside `generationLoadingOverlay` ("Analyzing References" -> "Curating Your Looks").
    var loadingStageTitle: String = "Curating Your Looks"
    
    /// Dynamic stage subtitle shown inside `generationLoadingOverlay`.
    var loadingStageSubtitle: String = ""
    
    /// True when this occasion has at least one user-attached reference photo.
    var hasReferencePhotos: Bool {
        !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil
    }
    
    /// True when an additional look is being generated in the background.
    var isGeneratingMore: Bool = false
    
    var isShowingChatModal: Bool = false
    
    var isShowingMoreMenu: Bool = false
    
    var isShowingAddLookModal: Bool = false
    
    /// Shown when saving or unsaving a look fails.
    var bookmarkErrorMessage: String?
    
    /// Garment picked in "On this outfit"; opens the "Where to Buy" sheet (Google Lens) when set.
    var garmentForPurchase: GarmentItem?
    
    /// Cropped garment images for the "On this outfit" thumbnails, by garment ID.
    private(set) var garmentCropImages: [UUID: CGImage] = [:]
    
    /// Injected storage (previews and tests). Without it, the occasion's SwiftData context is used.
    private let injectedSavedLookStorage: (any SavedLookStoring)?
    
    /// Saved-look storage for bookmarks. `nil` when the occasion isn't stored (for example in previews).
    private var savedLookStorage: (any SavedLookStoring)? {
        if let injectedSavedLookStorage {
            return injectedSavedLookStorage
        }
        return occasion.modelContext.map { SavedLookStorageService(modelContext: $0) }
    }
    var errorMessage: String? = nil
    
    var isShowingErrorAlert: Bool = false
    
    /// Total number of carousel items, including the loading card if generating more.
    var totalCarouselCount: Int {
        looks.count + (isGeneratingMore ? 1 : 0)
    }

    /// Index of the loading card when generating more looks.
    var loadingLookIndex: Int? {
        isGeneratingMore ? looks.count : nil
    }

    /// Returns true if the look at the given carousel index is currently loading.
    func isLookLoading(at index: Int) -> Bool {
        isGeneratingMore && index == looks.count
    }

    /// Returns true if the currently selected card is the loading placeholder.
    var isCurrentLookLoading: Bool {
        isLookLoading(at: selectedLookIndex)
    }
    
    var currentLook: OutfitLook? {
        guard looks.indices.contains(selectedLookIndex) else { return nil }
        return looks[selectedLookIndex]
    }
    
    var previousLook: OutfitLook? {
        guard selectedLookIndex > 0 else { return nil }
        return looks[selectedLookIndex - 1]
    }
    
    var nextLook: OutfitLook? {
        guard selectedLookIndex < looks.count - 1 else { return nil }
        return looks[selectedLookIndex + 1]
    }
    
    var isCurrentLookBookmarked: Bool {
        get {
            currentLook?.isBookmarked ?? false
        }
        set {
            setCurrentLookSaved(newValue)
        }
    }
    
    /// Returns true if the current look on stage has a real generated/styled image.
    var isCurrentLookImageGenerated: Bool {
        guard let currentLook,
              let data = currentLook.lookImageData,
              !data.isEmpty,
              !OccasionOutputViewModel.isPlaceholderData(data, lookIndex: currentLook.lookIndex) else {
            return false
        }
        return true
    }
    
    /// Garments of the current look, always left to right: inner top, outer, bottom.
    /// SwiftData doesn't keep relationship order, so they're sorted by category here;
    /// each card shows the name and the crop of the same garment, so they always match.
    var currentGarments: [GarmentItem] {
        (currentLook?.garments ?? []).sortedForOutfitDisplay()
    }
    
    
    /// Uses `looks` when given, otherwise the occasion's stored looks, otherwise mock looks.
    init(
        occasion: OccasionItem,
        looks: [OutfitLook] = [],
        selectedLookIndex: Int = 0,
        savedLookStorage: (any SavedLookStoring)? = nil,
        profile: UserProfile? = nil
    ) {
        self.occasion = occasion
        self.profile = profile
        self.selectedLookIndex = selectedLookIndex
        self.injectedSavedLookStorage = savedLookStorage

        if !looks.isEmpty {
            // Caller-supplied looks (e.g. injected for tests/previews): use them directly.
            for look in looks {
                if let data = look.lookImageData, OccasionOutputViewModel.isPlaceholderData(data, lookIndex: look.lookIndex) {
                    look.lookImageData = nil
                }
            }
            self.looks = looks
            self.isCallerSuppliedLooks = true
            self.isUsingMockPlaceholders = false
            self.isLoading = false
        } else if !occasion.generatedLooks.isEmpty {
            // Previously generated and stored looks: restore them.
            // Clean any dummy mock JPEG placeholder data previously saved by prepareLookForCropping
            for look in occasion.generatedLooks {
                if let data = look.lookImageData, OccasionOutputViewModel.isPlaceholderData(data, lookIndex: look.lookIndex) {
                    look.lookImageData = nil
                }
            }
            self.looks = occasion.generatedLooks.sorted { $0.lookIndex < $1.lookIndex }
            self.isUsingMockPlaceholders = false
            self.isLoading = false
        } else {
            // Show mock placeholders while awaiting on-device LLM generation via .task in the view.
            self.looks = OccasionOutputViewModel.makeMockLooks()
            self.isUsingMockPlaceholders = true
            self.isLoading = true
        }

        if !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil {
            self.vlmDebugDescriptions = ReferenceImageStyleAnalyzer.shared.savedDescriptions(forOccasionID: occasion.id)
        }
        if self.isLoading {
            self.configureInitialLoadingState(resetDescriptions: self.vlmDebugDescriptions.isEmpty)
        }
    }
    
    private var isUsingMockPlaceholders = false
    private var hasStartedInitialGeneration = false
    private(set) var isCallerSuppliedLooks = false

    private func configureInitialLoadingState(resetDescriptions: Bool) {
        let refCount = occasion.referenceImagesData.isEmpty
            ? (occasion.referenceImageData != nil ? 1 : 0)
            : occasion.referenceImagesData.count
        if resetDescriptions {
            vlmDebugDescriptions = []
        }
        if refCount > 0 {
            loadingStageTitle = "Analyzing References"
            loadingStageSubtitle = "Scanning 1 of \(refCount) reference photo\(refCount == 1 ? "" : "s")..."
        } else {
            loadingStageTitle = "Curating Your Looks"
            loadingStageSubtitle = "Styling ensembles tailored to your silhouette and \(occasion.title)..."
        }
    }

    /// Triggered once when the view appears on screen via `.task` to run real VLM + LLM inference.
    func generateLooksIfNeeded(profile: UserProfile? = nil) async {
        guard !hasStartedInitialGeneration else { return }

        // If caller explicitly supplied custom looks (e.g. single look from Library), keep them untouched.
        if isCallerSuppliedLooks {
            self.isLoading = false
            return
        }

        // If previously generated looks are already persisted, restore them.
        if !occasion.generatedLooks.isEmpty {
            for look in occasion.generatedLooks {
                if let data = look.lookImageData, OccasionOutputViewModel.isPlaceholderData(data, lookIndex: look.lookIndex) {
                    look.lookImageData = nil
                }
            }
            self.looks = occasion.generatedLooks.sorted { $0.lookIndex < $1.lookIndex }
            if hasReferencePhotos && vlmDebugDescriptions.isEmpty {
                self.vlmDebugDescriptions = ReferenceImageStyleAnalyzer.shared.savedDescriptions(forOccasionID: occasion.id)
            }
            self.isLoading = false
            return
        }

        // If caller passed real non-mock looks, do not generate.
        if !isUsingMockPlaceholders {
            self.isLoading = false
            return
        }

        hasStartedInitialGeneration = true
        self.isLoading = true
        configureInitialLoadingState(resetDescriptions: true)
        let activeProfile = profile ?? self.profile ?? UserProfile.mockSample
        do {
            let newLooks = try await OutfitGenerationPipeline.shared.generateLooks(
                for: occasion,
                profile: activeProfile
            ) { [weak self] stageTitle, stageSubtitle, descriptions in
                self?.loadingStageTitle = stageTitle
                self?.loadingStageSubtitle = stageSubtitle
                self?.vlmDebugDescriptions = descriptions
            }
            
            if let modelContext = self.occasion.modelContext {
                for look in newLooks {
                    modelContext.insert(look)
                    for garment in look.garments {
                        modelContext.insert(garment)
                    }
                    look.occasion = self.occasion
                }
            }
            let finalDescriptions = ReferenceImageStyleAnalyzer.shared.savedDescriptions(forOccasionID: occasion.id)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                self.vlmDebugDescriptions = finalDescriptions
                self.looks = newLooks
                self.occasion.generatedLooks = newLooks
                self.isUsingMockPlaceholders = false
                self.selectedLookIndex = 0
                self.isLoading = false
                try? self.occasion.modelContext?.save()
            }
            try? self.occasion.modelContext?.save()
        } catch {
            let errorMsg = error.localizedDescription
            print("\n❌ [OccasionOutputViewModel] LLM inference failed (\(LLMResource.activeModelFilename)): \(errorMsg)\n")
            withAnimation {
                self.errorMessage = errorMsg
                // Show the error, so mock placeholders aren't mistaken for generated looks.
                self.isShowingErrorAlert = true
                self.isLoading = false
            }
        }
    }
    
    
    func selectLook(at index: Int) {
        guard index >= 0 && index < totalCarouselCount else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            selectedLookIndex = index
        }
    }
    
    func goToPreviousLook() {
        guard selectedLookIndex > 0 else { return }
        selectLook(at: selectedLookIndex - 1)
    }
    
    func goToNextLook() {
        guard selectedLookIndex < totalCarouselCount - 1 else { return }
        selectLook(at: selectedLookIndex + 1)
    }
    
    /// Saves or unsaves the current look, so it appears in (or leaves) the Library.
    func toggleBookmark() {
        guard let currentLook else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            setCurrentLookSaved(!currentLook.isBookmarked)
        }
    }
    
    /// Stores the bookmark through `SavedLookStoring`. Reverts it if saving fails.
    private func setCurrentLookSaved(_ isSaved: Bool) {
        guard let currentLook else { return }
        // Mock placeholders shown while the AI is still generating are never saved,
        // otherwise they'd be stored as the occasion's looks and the AI would never run for it.
        guard !isUsingMockPlaceholders else { return }
        guard let savedLookStorage else {
            // Occasion isn't stored (previews): keep the bookmark in memory only.
            currentLook.isBookmarked = isSaved
            return
        }
        attachLooksToOccasion()
        do {
            try savedLookStorage.setSaved(isSaved, for: currentLook)
            bookmarkErrorMessage = nil
        } catch {
            currentLook.isBookmarked = !isSaved
            bookmarkErrorMessage = error.localizedDescription
        }
    }
    
    /// Adds looks that aren't stored yet (for example mock looks) to the occasion,
    /// so a saved look keeps its occasion and stays after this screen closes.
    private func attachLooksToOccasion() {
        guard !isCallerSuppliedLooks, !isUsingMockPlaceholders, let modelContext = occasion.modelContext else { return }
        let storedLookIDs = Set(occasion.generatedLooks.map(\.id))
        for look in looks where !storedLookIDs.contains(look.id) {
            modelContext.insert(look)
            for garment in look.garments {
                modelContext.insert(garment)
            }
            occasion.generatedLooks.append(look)
        }
        try? modelContext.save()
    }
    
    /// Updates the visual look image for a given look, links looks to the occasion, and saves to SwiftData.
    func updateLookImage(_ imageData: Data, for look: OutfitLook) {
        look.lookImageData = imageData
        look.imageGeneratedAt = Date()
        attachLooksToOccasion()
        try? occasion.modelContext?.save()
    }
    
    /// Opens "Where to Buy" for a garment of the current look.
    func selectGarmentForPurchase(_ garment: GarmentItem) {
        if let currentLook {
            prepareLookForCropping(currentLook)
        }
        garmentForPurchase = garment
    }
    
    /// Crops every garment of the current look for the "On this outfit" thumbnails.
    /// Uses the same crops (and cache) as the "Where to Buy" sheet.
    /// Without a generated image (no Image Playground image yet) nothing is cropped,
    /// so the cards show placeholders instead of crops of a mock image.
    func loadCurrentGarmentCrops() async {
        guard let look = currentLook, isCurrentLookImageGenerated else { return }
        prepareLookForCropping(look)
        for garment in look.garments {
            garmentCropImages[garment.id] = nil
        }
        guard hasGeneratedImage(look) else { return }
        let crops = await GarmentCropProvider.shared.crops(for: look.garments)
        garmentCropImages.merge(crops.mapValues(\.image)) { _, newImage in newImage }
    }

    /// Whether the look has its own image (not empty, not the mock placeholder).
    func hasGeneratedImage(_ look: OutfitLook) -> Bool {
        guard let data = look.lookImageData else { return false }
        return !OccasionOutputViewModel.isPlaceholderData(data, lookIndex: look.lookIndex)
    }
    
    /// The store crops a garment from its look image, so it needs the garment linked to the look.
    /// Does not overwrite `look.lookImageData` with mock data so the avatar stage keeps the Image Playground placeholder.
    private func prepareLookForCropping(_ look: OutfitLook) {
        for garment in look.garments where garment.outfitLook == nil {
            garment.outfitLook = look
        }
    }
    
    func toggleDetailsDrawer() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isDetailsDrawerExpanded.toggle()
        }
    }
    
    func regenerateLooks(profile: UserProfile? = nil) {
        guard !isLoading else { return }
        let preservedOccasionID = occasion.id
        
        // Remove old non-bookmarked looks from context if persisted, preserving bookmarked looks
        if let context = occasion.modelContext {
            for oldLook in occasion.generatedLooks {
                if oldLook.isBookmarked {
                    oldLook.cachedOccasionTitle = occasion.title
                    oldLook.cachedOccasionDresscode = occasion.dresscode
                    oldLook.cachedOccasionDate = occasion.date
                    oldLook.occasion = nil
                } else {
                    context.delete(oldLook)
                }
            }
        }
        occasion.generatedLooks.removeAll()
        garmentCropImages.removeAll()
        isGeneratingMore = false
        
        // Reset to generating state like a brand new occasion while preserving occasion.id
        withAnimation(.easeInOut(duration: 0.2)) {
            self.selectedLookIndex = 0
            self.looks = OccasionOutputViewModel.makeMockLooks()
            self.isUsingMockPlaceholders = true
            self.isLoading = true
            self.errorMessage = nil
            self.configureInitialLoadingState(resetDescriptions: true)
        }
        
        Task {
            let activeProfile = profile ?? self.profile ?? UserProfile.mockSample
            do {
                let newLooks = try await OutfitGenerationPipeline.shared.generateLooks(
                    for: occasion,
                    profile: activeProfile
                ) { [weak self] stageTitle, stageSubtitle, descriptions in
                    self?.loadingStageTitle = stageTitle
                    self?.loadingStageSubtitle = stageSubtitle
                    self?.vlmDebugDescriptions = descriptions
                }
                if let modelContext = self.occasion.modelContext {
                    for look in newLooks {
                        modelContext.insert(look)
                        for garment in look.garments {
                            modelContext.insert(garment)
                        }
                        look.occasion = self.occasion
                    }
                }
                let finalDescriptions = ReferenceImageStyleAnalyzer.shared.savedDescriptions(forOccasionID: occasion.id)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    self.vlmDebugDescriptions = finalDescriptions
                    self.looks = newLooks
                    self.occasion.generatedLooks = newLooks
                    self.selectedLookIndex = 0
                    self.isUsingMockPlaceholders = false
                    self.isLoading = false
                    try? self.occasion.modelContext?.save()
                }
                try? self.occasion.modelContext?.save()
                print("🔄 [OccasionOutputViewModel] Regenerated \(newLooks.count) looks for same occasion id=\(preservedOccasionID.uuidString) (\(self.occasion.title))")
            } catch {
                let errorMsg = error.localizedDescription
                print("\n❌ [OccasionOutputViewModel] LLM CANNOT BE USED (\(LLMResource.activeModelFilename)): \(errorMsg)\n")
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    self.errorMessage = errorMsg
                    self.isShowingErrorAlert = true
                    self.isLoading = false
                }
            }
        }
    }

    /// Generates one additional look in the background, showing a loading ring in the carousel
    /// while keeping the rest of the screen fully interactive.
    func generateMoreLooks(profile: UserProfile? = nil) {
        guard !isLoading && !isGeneratingMore else { return }
        
        isGeneratingMore = true
        let newIndex = looks.count
        
        // Transition carousel directly to the new loading index
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            selectedLookIndex = newIndex
        }
        
        Task {
            let activeProfile = profile ?? self.profile ?? UserProfile.mockSample
            do {
                let newLook = try await OutfitGenerationPipeline.shared.generateSingleLook(
                    for: occasion,
                    profile: activeProfile,
                    lookIndex: newIndex,
                    existingLooks: self.looks
                )
                
                if let modelContext = self.occasion.modelContext {
                    modelContext.insert(newLook)
                    for garment in newLook.garments {
                        modelContext.insert(garment)
                    }
                }

                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    newLook.occasion = self.occasion
                    if self.occasion.modelContext != nil {
                        self.occasion.generatedLooks.append(newLook)
                    }
                    self.looks.append(newLook)
                    self.occasion.generatedLooks = self.looks
                    self.selectedLookIndex = self.looks.count - 1
                    self.isGeneratingMore = false
                    self.isLoading = false
                    try? self.occasion.modelContext?.save()
                }
            } catch {
                let errorMsg = error.localizedDescription
                print("\n❌ [OccasionOutputViewModel] Failed to generate more looks: \(errorMsg)\n")
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    self.isGeneratingMore = false
                    if self.selectedLookIndex >= self.looks.count {
                        self.selectedLookIndex = max(0, self.looks.count - 1)
                    }
                    self.errorMessage = errorMsg
                    self.isShowingErrorAlert = true
                }
            }
        }
    }

    /// Generates one additional outfit look and appends it to the right of existing looks.
    func generateAdditionalLook(profile: UserProfile? = nil) {
        generateMoreLooks(profile: profile)
    }
}

extension OccasionOutputViewModel {
    
    static func mock() -> OccasionOutputViewModel {
        let occasion = OccasionItem(
            title: "Cousin's Wedding",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            dresscode: "Smart Casual / Cocktail",
            visionKeywords: ["Confident", "Approachable", "Elegant"]
        )
        return OccasionOutputViewModel(occasion: occasion)
    }
    
    static func makeMockLooks() -> [OutfitLook] {
        let look1 = OutfitLook(
            lookIndex: 0,
            fitRationale: "The fitted dark knit with a clean neckline narrows shoulder breadth, while the elongated silhouette and statement necklace draw visual focus toward the vertical centerline.",
            isBookmarked: false
        )
        // Mock garments match what is worn in mock_result_1 (bomber, polo, skinny jeans),
        // so the "Where to Buy" crops and titles describe the same item.
        let top1 = GarmentItem(
            category: .top,
            name: "Polo Shirt",
            material: "Knit Cotton",
            colorName: "Black",
            hexColor: "#1A1A1A"
        )
        let pants1 = GarmentItem(
            category: .bottom,
            name: "Skinny Jeans",
            material: "Stretch Denim",
            colorName: "Burgundy",
            hexColor: "#6B1F2A"
        )
        let shoes1 = GarmentItem(
            category: .outer,
            name: "Bomber Jacket",
            material: "Faux Leather",
            colorName: "Black",
            hexColor: "#0D0D0D"
        )
        look1.garments = [top1, pants1, shoes1]
        
        let look2 = OutfitLook(
            lookIndex: 1,
            fitRationale: "The warm terracotta long coat establishes a striking vertical column, balancing upper proportions with warm autumnal earth tones.",
            isBookmarked: false
        )
        // Matches mock_result_2 (rust coat, mauve blazer, mustard trousers).
        let coat2 = GarmentItem(
            category: .outer,
            name: "Long Wool Coat",
            material: "Wool Blend",
            colorName: "Rust",
            hexColor: "#B5582E"
        )
        let inner2 = GarmentItem(
            category: .top,
            name: "Single-Breasted Blazer",
            material: "Crepe",
            colorName: "Dusty Mauve",
            hexColor: "#8E6A78"
        )
        let pants2 = GarmentItem(
            category: .bottom,
            name: "Slim Trousers",
            material: "Cotton Twill",
            colorName: "Mustard",
            hexColor: "#B88A2E"
        )
        look2.garments = [coat2, inner2, pants2]
        
        let look3 = OutfitLook(
            lookIndex: 2,
            fitRationale: "Soft dusty rose tailoring softens angular shoulder lines, paired with draped fabrics that add gentle feminine fluidity for wedding guest elegance.",
            isBookmarked: false
        )
        // Matches mock_result_3 (mauve coat, rust cropped blazer, olive trousers).
        let coat3 = GarmentItem(
            category: .outer,
            name: "Long Coat",
            material: "Wool Blend",
            colorName: "Dusty Mauve",
            hexColor: "#9C7381"
        )
        let top3 = GarmentItem(
            category: .top,
            name: "Cropped Blazer",
            material: "Wool Crepe",
            colorName: "Rust",
            hexColor: "#B5582E"
        )
        let pants3 = GarmentItem(
            category: .bottom,
            name: "Pleated Trousers",
            material: "Cotton Twill",
            colorName: "Olive",
            hexColor: "#6B6A3A"
        )
        look3.garments = [coat3, top3, pants3]
        
        let look4 = OutfitLook(
            lookIndex: 3,
            fitRationale: "Monochromatic dark tones create an uninterrupted vertical presence, elevating evening cocktail formality effortlessly.",
            isBookmarked: false
        )
        // Copies, not the same objects: a SwiftData garment belongs to one look only,
        // so sharing them would move them away from look 1 (its Library card lost its garment name).
        look4.garments = makeGarmentCopies(of: [top1, pants1, shoes1])
        
        let look5 = OutfitLook(
            lookIndex: 4,
            fitRationale: "Vibrant warmth and tailored structure highlight personal color radiance while maintaining comfortable wedding movement.",
            isBookmarked: false
        )
        look5.garments = makeGarmentCopies(of: [coat2, inner2, pants2])
        
        let mockLooks = [look1, look2, look3, look4, look5]
        return mockLooks
    }
    
    private static let mockLookImageCompressionQuality: CGFloat = 0.8
    
    /// The avatar image for a look (`mock_result_<n>`, same as `AvatarStageView`) as JPEG on white.
    /// A dummy until looks get generated images.
    static func makePlaceholderLookImageData(for lookIndex: Int) -> Data? {
        UIImage(named: "mock_result_\(lookIndex + 1)")
            .map(makeImageOnWhite)?
            .jpegData(compressionQuality: mockLookImageCompressionQuality)
    }
    
    /// Returns true if this data matches the dummy mock JPEG placeholder.
    static func isPlaceholderData(_ data: Data, lookIndex: Int) -> Bool {
        guard let placeholder = makePlaceholderLookImageData(for: lookIndex) else { return false }
        return data == placeholder
    }
    
    /// The mock PNGs have a transparent background, which turns black in a JPEG.
    /// Draws them on white so a dark garment doesn't blend into the background.
    private static func makeImageOnWhite(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = true
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(at: .zero)
        }
    }
    
    /// New garment objects with the same details, for reusing a mock outfit in another look.
    private static func makeGarmentCopies(of garments: [GarmentItem]) -> [GarmentItem] {
        garments.map {
            GarmentItem(
                category: $0.category,
                name: $0.name,
                material: $0.material,
                colorName: $0.colorName,
                hexColor: $0.hexColor
            )
        }
    }
}
