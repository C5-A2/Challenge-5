//
//  OccasionsHistoryView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI
import SwiftData

/// History screen displaying past occasions (events whose date has passed).
///
/// Features the signature occasion cards list, empty state handling, and
/// tap-to-inspect form sheet capabilities.
struct OccasionsHistoryView: View {
    
    // MARK: - Environment & SwiftData Query
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OccasionItem.date, order: .reverse) private var allOccasions: [OccasionItem]
    
    // MARK: - Local State
    
    @AppStorage("hasAutoSeededDummyHistory") private var hasAutoSeededDummyHistory: Bool = false
    @State private var selectedOccasionForEdit: OccasionItem? = nil
    
    // MARK: - Computed Properties
    
    /// Filtered list of occasions that took place in the past.
    private var pastOccasions: [OccasionItem] {
        allOccasions.filter { $0.isPast }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Drag Handle Indicator
                    SheetDragHandle()
                    
                    // Header Bar (Close Button + Title)
                    ModalHeaderBar(
                        title: "Occasion History",
                        leadingIconSystemName: "xmark",
                        trailingIconSystemName: nil,
                        onLeadingAction: { dismiss() }
                    )
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Main Content: List of Past Occasion Cards or Empty State
                    if pastOccasions.isEmpty {
                        emptyHistoryStateView
                    } else {
                        pastOccasionsList
                    }
                }
            }
            .onAppear {
                seedDummyHistoryIfNeeded()
            }
            .sheet(item: $selectedOccasionForEdit) { occasion in
                OccasionFormSheet(
                    viewModel: OccasionInputViewModel(from: occasion),
                    onSave: { updatedDetail in
                        updateOccasion(occasion, with: updatedDetail)
                    }
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Scrollable list of past occasion cards.
    private var pastOccasionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(pastOccasions) { occasion in
                    OccasionCardView(occasion: occasion) {
                        selectedOccasionForEdit = occasion
                    }
                    .contextMenu {
                        Button {
                            selectedOccasionForEdit = occasion
                        } label: {
                            Label("View Details", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            deleteOccasion(occasion)
                        } label: {
                            Label("Delete From History", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }
    
    /// Empty state view presented when no past occasions exist.
    private var emptyHistoryStateView: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 40)
            
            // Stylized History Icon Container
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(AppColors.espressoTitle.opacity(0.7))
            }
            .padding(.bottom, 4)
            
            // Header & Description
            VStack(spacing: 6) {
                Text("No Past Occasions")
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text("Events whose dates have passed will automatically appear in your history archives.")
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.mutedCaption)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
            Spacer(minLength: 160)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    /// Automatically seeds sample past occasions once to test the view.
    private func seedDummyHistoryIfNeeded() {
        if pastOccasions.isEmpty && !hasAutoSeededDummyHistory {
            hasAutoSeededDummyHistory = true
            loadSampleHistory()
        }
    }
    
    /// Populates SwiftData with sample past occasions for testing.
    private func loadSampleHistory() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            for sample in OccasionItem.pastSamples {
                modelContext.insert(sample)
            }
            do {
                try modelContext.save()
            } catch {
                print("OccasionsHistoryView: Failed to save dummy history: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateOccasion(_ occasion: OccasionItem, with detail: OccasionDetail) {
        occasion.title = detail.title
        occasion.date = detail.date
        occasion.dresscode = detail.dresscode
        occasion.visionKeywords = detail.visions.map(\.rawValue)
        // Always update, so removing every reference photo is saved too.
        occasion.referenceImagesData = detail.referenceImages
        occasion.referenceImageData = detail.referenceImages.first
        do {
            try modelContext.save()
        } catch {
            print("OccasionsHistoryView: Failed to update occasion: \(error.localizedDescription)")
        }
    }
    
    private func deleteOccasion(_ occasion: OccasionItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            modelContext.delete(occasion)
            do {
                try modelContext.save()
            } catch {
                print("OccasionsHistoryView: Failed to delete occasion: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Previews

#Preview("History With Past Occasions") {
    let container = try! ModelContainer(
        for: OccasionItem.self, OutfitLook.self, GarmentItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    for sample in OccasionItem.pastSamples {
        container.mainContext.insert(sample)
    }
    
    return OccasionsHistoryView()
        .modelContainer(container)
}

#Preview("Empty History") {
    OccasionsHistoryView()
        .modelContainer(for: [OccasionItem.self, OutfitLook.self, GarmentItem.self], inMemory: true)
}
