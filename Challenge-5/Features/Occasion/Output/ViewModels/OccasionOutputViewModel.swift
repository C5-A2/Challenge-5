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
            currentLook?.isBookmarked = newValue
        }
    }
    
    var currentGarments: [GarmentItem] {
        currentLook?.garments ?? []
    }
    
    
    init(
        occasion: OccasionItem,
        looks: [OutfitLook] = [],
        selectedLookIndex: Int = 0,
        profile: UserProfile? = nil
    ) {
        self.occasion = occasion
        self.profile = profile
        if !looks.isEmpty {
            self.looks = looks
        } else if !occasion.generatedLooks.isEmpty {
            self.looks = occasion.generatedLooks.sorted { $0.lookIndex < $1.lookIndex }
        } else {
            do {
                let activeProfile = profile ?? UserProfile.mockSample
                self.looks = try OutfitGenerationPipeline.shared.generateLooksSync(
                    for: occasion,
                    profile: activeProfile
                )
            } catch {
                let errorMsg = error.localizedDescription
                print("\n❌ [OccasionOutputViewModel] LLaMA CANNOT BE USED: \(errorMsg)\n")
                self.errorMessage = errorMsg
                self.isShowingErrorAlert = true
            }
        }
        self.selectedLookIndex = selectedLookIndex
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
    
    func toggleBookmark() {
        guard let currentLook else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            currentLook.isBookmarked.toggle()
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
            isBookmarked: true
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
        look4.garments = [top1, pants1, shoes1]
        
        let look5 = OutfitLook(
            lookIndex: 4,
            fitRationale: "Vibrant warmth and tailored structure highlight personal color radiance while maintaining comfortable wedding movement.",
            isBookmarked: false
        )
        look5.garments = [coat2, inner2, pants2]
        
        return [look1, look2, look3, look4, look5]
    }
}
