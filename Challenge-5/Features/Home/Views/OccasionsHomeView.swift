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
    
    // MARK: - Local ViewModel & State
    
    @State private var viewModel = HomeViewModel()
    @State private var isShowingProfileSheet: Bool = false
    @State private var occasionToDelete: OccasionItem? = nil
    @State private var isPastOccasionsExpanded: Bool = false
    
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
        occasions
            .filter { !$0.isPast }
            .sorted(by: { $0.date < $1.date })
    }
    
    /// Filtered list of past occasions (events whose date has passed), sorted most recent first.
    private var pastOccasions: [OccasionItem] {
        occasions
            .filter { $0.isPast }
            .sorted(by: { $0.date > $1.date })
    }

    private var currentProfile: UserProfile? {
        userProfiles.first
    }

    private var isProfileSetupCompleted: Bool {
        currentProfile?.hasCompletedProfileSetup == true
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
                    // Header Bar (Profile icon + Large Title)
                    headerBar
                        .padding(.top, 8)

                    // Profile Setup Prompt Banner (C5-98)
                    if !isProfileSetupCompleted {
                        profileSetupPromptCard
                    }
                    
                    // Main Feed Content: Upcoming Occasions & Past Occasions
                    if activeOccasions.isEmpty && pastOccasions.isEmpty {
                        emptyStateView
                    } else {
                        if activeOccasions.isEmpty {
                            emptyStateView
                        } else {
                            occasionsList
                        }
                        
                        // Past Occasions Expandable Section (only shown when history exists)
                        if !pastOccasions.isEmpty {
                            pastOccasionsSection
                        }
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
        .sheet(isPresented: $isShowingProfileSheet) {
            ProfileHubView()
        }
        .sheet(isPresented: $viewModel.isShowingProfilePromptModal) {
            ProfilePromptModal(
                onStartProfiling: {
                    viewModel.isShowingProfilePromptModal = false
                    viewModel.isShowingProfilingFlow = true
                }
            )
        }
        .fullScreenCover(isPresented: $viewModel.isShowingProfilingFlow) {
            ProfilingFlowHostView(
                onComplete: {
                    viewModel.isShowingProfilingFlow = false
                }
            )
        }
        .sheet(item: $viewModel.editingOccasion) { occasion in
            OccasionFormSheet(
                viewModel: OccasionInputViewModel(from: occasion),
                onSave: { updatedDetail in
                    viewModel.updateOccasion(occasion, with: updatedDetail, in: modelContext)
                }
            )
        }
        .fullScreenCover(item: $viewModel.selectedOccasion) { occasion in
            let activeProfile = userProfiles.first ?? UserProfile.mockSample
            OccasionOutputView(
                occasion: occasion,
                profile: activeProfile,
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

    /// Prompt card displayed at the top of Home feed encouraging profile setup (C5-98).
    private var profileSetupPromptCard: some View {
        Button {
            viewModel.isShowingProfilePromptModal = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.pastelGold.opacity(0.35))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.espressoTitle)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Set Up Your Profile")
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                    Text("Ketahui bentuk tubuh & warna personalmu untuk kurasi outfit yang presisi.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.mutedCaption)
            }
            .padding(AppDimensions.cardInternalPadding)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                    .stroke(AppColors.subtleBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
    
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
                
                // Profile Button (Opens ProfileHubView)
                CircularIconButton(systemName: "person.crop.circle") {
                    if let onProfileTap {
                        onProfileTap()
                    } else {
                        isShowingProfileSheet = true
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
    
    /// Populated list of upcoming occasions stored in SwiftData.
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
                .swipeToDelete {
                    occasionToDelete = occasion
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: activeOccasions)
    }
    
    /// Expandable section for past occasions displayed at the bottom of upcoming occasions.
    private var pastOccasionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Expand / Collapse Header Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isPastOccasionsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Past Occasion")
                        .font(AppTypography.sectionHeader)
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                        .rotationEffect(.degrees(isPastOccasionsExpanded ? 0 : -90))
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, activeOccasions.isEmpty ? 0 : 4)
            
            // Expanded Past Occasion Cards
            if isPastOccasionsExpanded {
                LazyVStack(spacing: 16) {
                    ForEach(pastOccasions) { occasion in
                        OccasionCardView(occasion: occasion) {
                            if let onSelectOccasion {
                                onSelectOccasion(occasion)
                            } else {
                                viewModel.selectedOccasion = occasion
                            }
                        }
                        .swipeToDelete {
                            occasionToDelete = occasion
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isPastOccasionsExpanded)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: pastOccasions)
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
        .alert("AI Generation Error", isPresented: $viewModel.isShowingErrorAlert, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert(
            "Delete Occasion?",
            isPresented: Binding(
                get: { occasionToDelete != nil },
                set: { if !$0 { occasionToDelete = nil } }
            ),
            presenting: occasionToDelete
        ) { occasion in
            Button("Cancel", role: .cancel) {
                occasionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteOccasion(occasion)
                occasionToDelete = nil
            }
        } message: { occasion in
            if occasion.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Are you sure you want to delete this occasion? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete \"\(occasion.title)\"? This action cannot be undone.")
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
    .modelContainer(for: [OccasionItem.self, OutfitLook.self, GarmentItem.self, UserProfile.self], inMemory: true)
}

#Preview("Occasions Home - With Sample Data") {
    let container = try! ModelContainer(
        for: OccasionItem.self, OutfitLook.self, GarmentItem.self, UserProfile.self,
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
