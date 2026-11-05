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
    }
    
    private var isUsingMockPlaceholders = false
    private var hasStartedInitialGeneration = false
    private(set) var isCallerSuppliedLooks = false

    /// Triggered once when the view appears on screen via `.task` to run real LLM inference.
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
        let activeProfile = profile ?? self.profile ?? UserProfile.mockSample
        do {
            let newLooks = try await OutfitGenerationPipeline.shared.generateLooks(
                for: occasion,
                profile: activeProfile
            )
            
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                self.looks = newLooks
                self.occasion.generatedLooks = newLooks
                self.isUsingMockPlaceholders = false
                self.selectedLookIndex = 0
                self.isLoading = false
            }
        } catch {
            let errorMsg = error.localizedDescription
            print("\n❌ [OccasionOutputViewModel] LLM inference failed (\(LLMResource.activeModelFilename)): \(errorMsg)\n")
            withAnimation {
                self.errorMessage = errorMsg
                self.isLoading = false
            }
        }
    }
    
    
    func selectLook(at index: Int) {
        guard looks.indices.contains(index) else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            selectedLookIndex = index
        }
    }
    
    func goToPreviousLook() {
        guard selectedLookIndex > 0 else { return }
        selectLook(at: selectedLookIndex - 1)
    }
    
    func goToNextLook() {
        guard selectedLookIndex < looks.count - 1 else { return }
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
        guard !isCallerSuppliedLooks, occasion.modelContext != nil else { return }
        let storedLookIDs = Set(occasion.generatedLooks.map(\.id))
        for look in looks where !storedLookIDs.contains(look.id) {
            occasion.generatedLooks.append(look)
        }
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
    func loadCurrentGarmentCrops() async {
        guard let look = currentLook else { return }
        prepareLookForCropping(look)
        let crops = await GarmentCropProvider.shared.crops(for: look.garments)
        garmentCropImages.merge(crops.mapValues(\.image)) { _, newImage in newImage }
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
        isLoading = true
        errorMessage = nil
        
        Task {
            let activeProfile = profile ?? UserProfile.mockSample
            do {
                let newLooks = try await OutfitGenerationPipeline.shared.generateLooks(for: occasion, profile: activeProfile)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    self.looks = newLooks
                    self.occasion.generatedLooks = newLooks
                    self.selectedLookIndex = 0
                    self.isLoading = false
                }
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

    /// Generates one additional outfit look and appends it to the right of existing looks.
    func generateAdditionalLook(profile: UserProfile? = nil) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            let activeProfile = profile ?? self.profile ?? UserProfile.mockSample
            do {
                let newLook = try await OutfitGenerationPipeline.shared.generateSingleLook(
                    for: occasion,
                    profile: activeProfile,
                    existingLooks: self.looks
                )

                if let modelContext = occasion.modelContext {
                    modelContext.insert(newLook)
                    for garment in newLook.garments {
                        modelContext.insert(garment)
                    }
                }

                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    self.looks.append(newLook)
                    self.occasion.generatedLooks = self.looks
                    self.selectedLookIndex = self.looks.count - 1
                    self.isLoading = false
                }
            } catch {
                let errorMsg = error.localizedDescription
                print("\n❌ [OccasionOutputViewModel] Failed to generate additional look: \(errorMsg)\n")
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    self.errorMessage = errorMsg
                    self.isShowingErrorAlert = true
                    self.isLoading = false
                }
            }
        }
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
        // Dummy look images (same assets as the avatar stage), so saved mock looks
        // show in the Library and in "From Library" references. Replace with generated images.
        for look in mockLooks {
            look.lookImageData = makePlaceholderLookImageData(for: look.lookIndex)
        }
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
