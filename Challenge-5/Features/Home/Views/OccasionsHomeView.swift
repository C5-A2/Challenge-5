//
//  OccasionsHomeView.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import SwiftUI
import SwiftData

/// The primary Occasions screen displaying user-scheduled occasions.
///
/// Matches the design specifications:
/// - Top right circular buttons: History (`clock.arrow.circlepath`) and Profile (`circle`).
/// - Large bold "Occasions" header.
/// - Scrollable list of occasions with signature metallic folder cards.
/// - Placeholder folder card when no occasions exist (exact match to Figma mockup).
/// - Floating black (+) button to add a new occasion.
/// - Persistent SwiftData storage via `@Model OccasionItem` and `@Query`.
/// - Floating bottom capsule tab bar.
struct OccasionsHomeView: View {
    
    // MARK: - Environment & SwiftData Query
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OccasionItem.date, order: .forward) private var occasions: [OccasionItem]
    @Query private var userProfiles: [UserProfile]
    
    // MARK: - Navigation & Tab State
    
    @Binding var selectedTab: CapsuleTabItem
    
    // MARK: - Local ViewModel
    
    @State private var viewModel = HomeViewModel()
    
    // MARK: - Action Callbacks
    
    var onHistoryTap: (() -> Void)? = nil
    var onProfileTap: (() -> Void)? = nil
    var onSelectOccasion: ((OccasionItem) -> Void)? = nil
    
    // MARK: - Initializer
    
    init(
        selectedTab: Binding<CapsuleTabItem> = .constant(.occasions),
        onHistoryTap: (() -> Void)? = nil,
        onProfileTap: (() -> Void)? = nil,
        onSelectOccasion: ((OccasionItem) -> Void)? = nil
    ) {
        self._selectedTab = selectedTab
        self.onHistoryTap = onHistoryTap
        self.onProfileTap = onProfileTap
        self.onSelectOccasion = onSelectOccasion
    }
    
    // MARK: - Computed Properties
    
    /// Filtered list of upcoming or active occasions for the main home feed.
    private var activeOccasions: [OccasionItem] {
        occasions.filter { !$0.isPast }
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Background Canvas
            AppColors.canvasBackground
                .ignoresSafeArea()
            
            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Bar (History, Profile icons + Large Title)
                    headerBar
                        .padding(.top, 8)
                    
                    // Occasion Cards List or Empty State (no card)
                    if activeOccasions.isEmpty {
                        emptyStateView
                    } else {
                        occasionsList
                    }
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                // Bottom padding to ensure content clears floating FAB and TabBar
                .padding(.bottom, AppDimensions.tabBarHeight + 80)
            }
            .scrollIndicators(.hidden)
            
            // Floating Action Button (+) above Tab Bar
            floatingAddButton
            
            // Floating Bottom Capsule Tab Bar
            CapsuleTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 16)
                .padding(.horizontal, 40)
        }
        .sheet(isPresented: $viewModel.isShowingHistorySheet) {
            OccasionsHistoryView()
        }
        .fullScreenCover(item: $viewModel.selectedOccasion) { occasion in
            OccasionOutputView(
                occasion: occasion,
                onDismiss: {
                    viewModel.selectedOccasion = nil
                },
                onEditOccasion: { occasionToEdit in
                    viewModel.selectedOccasion = nil
                    viewModel.editingOccasion = occasionToEdit
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    /// Top header bar with history and profile circular buttons and large "Occasions" title.
    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top Row: Circular Icon Buttons at Top Right
            HStack(spacing: 12) {
                Spacer()
                
                // History Button (Opens OccasionsHistoryView)
                CircularIconButton(systemName: "clock.arrow.circlepath") {
                    if let onHistoryTap {
                        onHistoryTap()
                    } else {
                        viewModel.isShowingHistorySheet = true
                    }
                }
                
                // Profile Button (Empty objective for now)
                CircularIconButton(systemName: "circle") {
                    if let onProfileTap {
                        onProfileTap()
                    } else {
                        print("Profile button tapped (empty action)")
                    }
                }
            }
            
            // Second Row: Large "Occasions" Title
            Text("Occasions")
                .font(AppTypography.screenHeader)
                .foregroundStyle(AppColors.espressoTitle)
        }
    }
    
    /// Empty state view presented when no occasions are scheduled yet (no card).
    private var emptyStateView: some View {
        OccasionsEmptyStateView(
            onAddOccasion: {
                viewModel.isShowingNewOccasionSheet = true
            }
        )
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
    
    /// Populated list of occasions stored in SwiftData.
    private var occasionsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(activeOccasions) { occasion in
                OccasionCardView(occasion: occasion) {
                    if let onSelectOccasion {
                        onSelectOccasion(occasion)
                    } else {
                        viewModel.selectedOccasion = occasion
                    }
                }
                .contextMenu {
                    Button {
                        viewModel.editingOccasion = occasion
                    } label: {
                        Label("Edit Occasion", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        deleteOccasion(occasion)
                    } label: {
                        Label("Delete Occasion", systemImage: "trash")
                    }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: activeOccasions)
        .sheet(item: $viewModel.editingOccasion) { occasion in
            OccasionFormSheet(
                viewModel: OccasionInputViewModel(from: occasion),
                onSave: { updatedDetail in
                    viewModel.updateOccasion(occasion, with: updatedDetail, in: modelContext)
                }
            )
        }
    }
    
    /// Circular floating "+" action button positioned at bottom right.
    private var floatingAddButton: some View {
        HStack {
            Spacer()
            
            Button {
                viewModel.isShowingNewOccasionSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(
                        width: AppDimensions.floatingButtonSize,
                        height: AppDimensions.floatingButtonSize
                    )
                    .background(AppColors.primaryBlack)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.trailing, AppDimensions.screenHorizontalPadding)
        }
        .padding(.bottom, AppDimensions.tabBarHeight + 28)
        .sheet(isPresented: $viewModel.isShowingNewOccasionSheet) {
            OccasionFormSheet { occasionDetail in
                let activeProfile = userProfiles.first ?? UserProfile.mockSample
                let createdOccasion = viewModel.saveOccasion(
                    from: occasionDetail,
                    profile: activeProfile,
                    in: modelContext
                )
                viewModel.selectedOccasion = createdOccasion
            }
        }
    }
    
    // MARK: - Actions
    
    /// Deletes an occasion from SwiftData.
    private func deleteOccasion(_ occasion: OccasionItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            viewModel.deleteOccasion(occasion, in: modelContext)
        }
    }
}

// MARK: - Previews

#Preview("Occasions Home - Empty State") {
    OccasionsHomeView(
        selectedTab: .constant(.occasions)
    )
    .modelContainer(for: [OccasionItem.self, OutfitLook.self, GarmentItem.self], inMemory: true)
}

#Preview("Occasions Home - With Sample Data") {
    let container = try! ModelContainer(
        for: OccasionItem.self, OutfitLook.self, GarmentItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    for sample in OccasionItem.samples {
        container.mainContext.insert(sample)
    }
    
    return OccasionsHomeView(
        selectedTab: .constant(.occasions)
    )
    .modelContainer(container)
}
