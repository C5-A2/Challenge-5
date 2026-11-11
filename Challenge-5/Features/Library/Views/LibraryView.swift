//
//  LibraryView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI
import SwiftData

/// The primary Library screen displaying saved/bookmarked outfit looks.
///
/// Features an asymmetric staggered grid layout, bookmark toggles,
/// empty state handling, and the floating bottom capsule tab bar.
public struct LibraryView: View {
    
    // MARK: - Environment & State
    
    private struct OutputPresentationItem: Identifiable {
        let id = UUID()
        let occasion: OccasionItem
        let look: OutfitLook
    }
    
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var viewModel: LibraryViewModel
    @State private var outputPresentationItem: OutputPresentationItem? = nil
    @Binding public var selectedTab: CapsuleTabItem
    
    // Action callbacks
    public var onProfileTap: (() -> Void)? = nil
    public var onSelectLook: ((SavedLookItem) -> Void)? = nil
    
    // MARK: - Initializer
    
    public init(
        selectedTab: Binding<CapsuleTabItem> = .constant(.library),
        initialLooks: [SavedLookItem] = [],
        onProfileTap: (() -> Void)? = nil,
        onSelectLook: ((SavedLookItem) -> Void)? = nil
    ) {
        self._selectedTab = selectedTab
        self._viewModel = State(initialValue: LibraryViewModel(initialLooks: initialLooks))
        self.onProfileTap = onProfileTap
        self.onSelectLook = onSelectLook
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Canvas
            AppColors.canvasBackground
                .ignoresSafeArea()
            
            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Bar (Matches Figma: Top Right Circle + Title Below)
                    headerBar
                        .padding(.top, 8)
                    
                    // Main Grid or Empty State
                    if viewModel.isEmpty {
                        LibraryEmptyStateView(
                            onExploreOccasions: {
                                withAnimation {
                                    selectedTab = .occasions
                                }
                            },
                            onAddSampleLooks: {
                                viewModel.loadSampleLooks()
                            }
                        )
                        .padding(.top, 87)
                    } else {
                        staggeredLookGrid
                    }
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                // Bottom padding to ensure content scrolls above the floating capsule tab bar
                .padding(.bottom, AppDimensions.tabBarHeight + 48)
            }
            .scrollIndicators(.hidden)
            
            // Floating Bottom Tab Bar
            CapsuleTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 16)
                .padding(.horizontal, 40)
        }
        .task {
            // Attempt SwiftData context sync if models exist
            viewModel.fetchSavedLooksFromContext(modelContext)
        }
        .fullScreenCover(item: $outputPresentationItem) { item in
            OccasionOutputView(
                viewModel: OccasionOutputViewModel(
                    occasion: item.occasion,
                    looks: [item.look],
                    selectedLookIndex: 0,
                    profile: userProfiles.first ?? UserProfile.mockSample
                ),
                onDismiss: {
                    outputPresentationItem = nil
                    // A look may have been unsaved in the Output, so reload the Library.
                    viewModel.fetchSavedLooksFromContext(modelContext)
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Circular Icon Button at Top Right (Matches OccasionsHomeView)
            HStack(spacing: 12) {
                Spacer()
                
                LiquidGlassCircularButton.profile {
                    if let onProfileTap {
                        onProfileTap()
                    } else {
                        print("Profile button tapped")
                    }
                }
            }
            
            // Second Row: Large "Library" Title below the button (10 px below profile button)
            Text("Library")
                .font(AppTypography.screenHeader)
                .foregroundStyle(AppColors.espressoTitle)
        }
    }
    
    private var staggeredLookGrid: some View {
        AsymmetricStaggeredGrid(items: viewModel.filteredLooks, spacing: 14) { look in
            LibraryCardView(
                look: look,
                onSelect: {
                    if let onSelectLook {
                        onSelectLook(look)
                    } else {
                        // Open only the tapped saved look in OccasionOutputView (1 avatar, no other looks)
                        if let storedLook = viewModel.outfitLook(for: look) {
                            let parentOccasion = storedLook.occasion ?? OccasionItem(
                                title: look.occasionTitle.isEmpty ? "My Occasion" : look.occasionTitle,
                                date: look.date,
                                dresscode: look.dresscode.isEmpty ? "Casual / Smart Casual" : look.dresscode
                            )
                            outputPresentationItem = OutputPresentationItem(
                                occasion: parentOccasion,
                                look: storedLook
                            )
                            return
                        }
                        
                        // Fallback for mock/sample looks without SwiftData entity
                        let tempLook = OutfitLook(
                            lookIndex: look.lookIndex,
                            fitRationale: look.fitRationale,
                            isBookmarked: look.isBookmarked,
                            lookImageData: look.lookImageData
                        )
                        tempLook.garments = look.garments.map { garment in
                            GarmentItem(
                                category: GarmentCategory(rawValue: garment.category) ?? .top,
                                name: garment.name,
                                material: garment.material,
                                colorName: garment.colorName,
                                hexColor: garment.hexColor,
                                rationale: garment.rationale
                            )
                        }
                        let tempOccasion = OccasionItem(
                            title: look.occasionTitle.isEmpty ? "My Occasion" : look.occasionTitle,
                            date: look.date,
                            dresscode: look.dresscode.isEmpty ? "Casual / Smart Casual" : look.dresscode
                        )
                        outputPresentationItem = OutputPresentationItem(
                            occasion: tempOccasion,
                            look: tempLook
                        )
                    }
                },
                onToggleBookmark: {
                    viewModel.toggleBookmark(for: look)
                }
            )
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.filteredLooks)
    }
}

// MARK: - Preview

#Preview("Library View Populated") {
    LibraryView(
        selectedTab: .constant(.library),
        initialLooks: SavedLookItem.samples
    )
}

/// Looks loaded from SwiftData (2 saved looks with images, newest first).
#Preview("Library View - SwiftData") {
    LibraryView(
        selectedTab: .constant(.library),
        initialLooks: []
    )
    .modelContainer(SavedLookSampleData.makeContainer())
}

#Preview("Library View Empty State") {
    LibraryView(
        selectedTab: .constant(.library),
        initialLooks: []
    )
}
