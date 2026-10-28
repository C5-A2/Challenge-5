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
    
    var currentGarments: [GarmentItem] {
        currentLook?.garments ?? []
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
            self.looks = looks
        } else if !occasion.generatedLooks.isEmpty {
            // Previously generated and stored looks: restore them.
            self.looks = occasion.generatedLooks.sorted { $0.lookIndex < $1.lookIndex }
        } else {
            // No looks yet — show mock placeholders and kick off real async LLaMA generation.
            // generateLooksSync now throws to prevent silent static-template fallback.
            self.looks = OccasionOutputViewModel.makeMockLooks()
            self.isLoading = true
            Task { [weak self] in
                guard let self else { return }
                let activeProfile = profile ?? UserProfile.mockSample
                do {
                    let newLooks = try await OutfitGenerationPipeline.shared.generateLooks(
                        for: occasion,
                        profile: activeProfile
                    )
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        self.looks = newLooks
                        self.selectedLookIndex = 0
                        self.isLoading = false
                    }
                } catch {
                    let errorMsg = error.localizedDescription
                    print("\n❌ [OccasionOutputViewModel] LLaMA inference failed: \(errorMsg)\n")
                    withAnimation {
                        self.errorMessage = errorMsg
                        self.isShowingErrorAlert = true
                        self.isLoading = false
                    }
                }
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
        guard occasion.modelContext != nil else { return }
        let storedLookIDs = Set(occasion.generatedLooks.map(\.id))
        for look in looks where !storedLookIDs.contains(look.id) {
            occasion.generatedLooks.append(look)
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
                print("\n❌ [OccasionOutputViewModel] LLaMA CANNOT BE USED: \(errorMsg)\n")
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
        let top1 = GarmentItem(
            category: .top,
            name: "Ribbed Mockneck Top",
            material: "Fine Merino Wool",
            colorName: "Midnight Black",
            hexColor: "#1A1A1A"
        )
        let pants1 = GarmentItem(
            category: .bottom,
            name: "Tailored Cigarette Pants",
            material: "Stretch Crepe",
            colorName: "Jet Black",
            hexColor: "#111111"
        )
        let shoes1 = GarmentItem(
            category: .outer,
            name: "Pointed Ankle Boots",
            material: "Polished Calfskin",
            colorName: "Obsidian",
            hexColor: "#0D0D0D"
        )
        look1.garments = [top1, pants1, shoes1]
        
        let look2 = OutfitLook(
            lookIndex: 1,
            fitRationale: "The warm terracotta long coat establishes a striking vertical column, balancing upper proportions with warm autumnal earth tones.",
            isBookmarked: false
        )
        let coat2 = GarmentItem(
            category: .outer,
            name: "Tailored Duster Coat",
            material: "Double-Faced Wool",
            colorName: "Terracotta Ochre",
            hexColor: "#C36B3D"
        )
        let inner2 = GarmentItem(
            category: .top,
            name: "Cashmere Crewneck",
            material: "Cashmere Blend",
            colorName: "Warm Umber",
            hexColor: "#4A3222"
        )
        let pants2 = GarmentItem(
            category: .bottom,
            name: "Wide Pleated Trousers",
            material: "Fluid Gabardine",
            colorName: "Rich Caramel",
            hexColor: "#82502E"
        )
        look2.garments = [coat2, inner2, pants2]
        
        let look3 = OutfitLook(
            lookIndex: 2,
            fitRationale: "Soft dusty rose tailoring softens angular shoulder lines, paired with draped fabrics that add gentle feminine fluidity for wedding guest elegance.",
            isBookmarked: false
        )
        let coat3 = GarmentItem(
            category: .outer,
            name: "Fluid Cocoon Coat",
            material: "Virgin Wool Blend",
            colorName: "Dusty Mauve",
            hexColor: "#8E5D67"
        )
        let top3 = GarmentItem(
            category: .top,
            name: "Draped Silk Blouse",
            material: "Mulberry Silk",
            colorName: "Pale Blush",
            hexColor: "#E8D7D8"
        )
        let pants3 = GarmentItem(
            category: .bottom,
            name: "Straight Leg Chinos",
            material: "Fine Twill",
            colorName: "Deep Plum",
            hexColor: "#5E454B"
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
            look.lookImageData = UIImage(named: "mock_result_\(look.lookIndex + 1)")?
                .jpegData(compressionQuality: mockLookImageCompressionQuality)
        }
        return mockLooks
    }
    
    private static let mockLookImageCompressionQuality: CGFloat = 0.8
    
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
