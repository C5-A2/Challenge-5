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
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LibraryViewModel
    @Binding public var selectedTab: CapsuleTabItem
    
    // Action callbacks
    public var onProfileTap: (() -> Void)? = nil
    public var onSelectLook: ((SavedLookItem) -> Void)? = nil
    
    // MARK: - Initializer
    
    public init(
        selectedTab: Binding<CapsuleTabItem> = .constant(.library),
        initialLooks: [SavedLookItem] = SavedLookItem.samples,
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
                        .padding(.top, 40)
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
    }
    
    // MARK: - Subviews
    
    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top Row: Circular Icon Button at Top Right
            HStack {
                Spacer()
                
                CircularIconButton(systemName: "circle") {
                    if let onProfileTap {
                        onProfileTap()
                    } else {
                        print("Profile button tapped")
                    }
                }
            }
            
            // Second Row: Large "Library" Title below the button
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
                    onSelectLook?(look)
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

#Preview("Library View Empty State") {
    LibraryView(
        selectedTab: .constant(.library),
        initialLooks: []
    )
}
