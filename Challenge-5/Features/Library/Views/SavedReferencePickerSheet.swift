//
//  SavedReferencePickerSheet.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI

public struct SavedReferencePickerSheet: View {
    
    // MARK: - Segment Enum
    
    public enum PickerSegment: String, CaseIterable, Identifiable {
        case photos = "Photos"
        case collection = "Collection"
        
        public var id: String { rawValue }
    }
    
    // MARK: - Properties
    
    public let savedLooks: [SavedLookItem]
    public var allowsMultipleSelection: Bool = false
    public var onSelectReferences: ([SavedLookItem]) -> Void
    public var onDismiss: () -> Void
    
    // MARK: - State
    
    @State private var selectedSegment: PickerSegment = .collection
    @State private var selectedLookIds: Set<UUID> = []
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    // MARK: - Initializer
    
    public init(
        savedLooks: [SavedLookItem] = SavedLookItem.samples,
        allowsMultipleSelection: Bool = false,
        preselectedLookIds: Set<UUID> = [],
        onSelectReferences: @escaping ([SavedLookItem]) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.savedLooks = savedLooks
        self.allowsMultipleSelection = allowsMultipleSelection
        self._selectedLookIds = State(initialValue: preselectedLookIds)
        self.onSelectReferences = onSelectReferences
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {

            topHeaderBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            Group {
                if selectedSegment == .collection {
                    if savedLooks.isEmpty {
                        emptyCollectionPlaceholder
                    } else {
                        collectionGridView
                    }
                } else {
                    photosTabPlaceholder
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    // MARK: - Top Header Bar
    
    private var topHeaderBar: some View {
        HStack(alignment: .center) {
            
            CircularIconButton(systemName: "xmark") {
                onDismiss()
            }
            
            Spacer()
            
            segmentedControlPill
            
            Spacer()
            
            if !selectedLookIds.isEmpty {
                Button("Done") {
                    confirmSelection()
                }
                .font(AppTypography.buttonLabel)
                .foregroundStyle(AppColors.espressoTitle)
                .frame(minWidth: AppDimensions.circularIconSize)
            } else {
                Color.clear
                    .frame(width: AppDimensions.circularIconSize, height: AppDimensions.circularIconSize)
            }
        }
    }
    
    // MARK: - Segmented Control Pill
    
    private var segmentedControlPill: some View {
        HStack(spacing: 4) {
            ForEach(PickerSegment.allCases) { segment in
                let isSelected = selectedSegment == segment
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedSegment = segment
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? AppColors.espressoTitle : AppColors.mutedCaption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(AppColors.cardBackground)
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(hex: "#EAE7E1"))
        )
    }
    
    // MARK: - Collection Grid View
    
    private var collectionGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(savedLooks) { look in
                    let isSelected = selectedLookIds.contains(look.id)
                    
                    Button {
                        toggleSelection(for: look.id)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                          
                            AsyncLookThumbnailView(
                                imageData: look.lookImageData,
                                assetImageName: look.assetImageName,
                                contentMode: .fill,
                                showPlaceholderIcon: false
                            )
                            .aspectRatio(1, contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .clipped()

                            if isSelected {
                                Rectangle()
                                    .strokeBorder(Color(hex: "#007AFF"), lineWidth: 3.5)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#007AFF"))
                                        .frame(width: 22, height: 22)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .padding(6)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Empty & Photos Placeholders
    
    private var emptyCollectionPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bookmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(AppColors.mutedCaption)
            
            Text("No saved looks found")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
            
            Text("Bookmark outfit recommendations from your styling stage to use them as reference.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    private var photosTabPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppColors.mutedCaption)
            
            Text("Device Photos")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
            
            Text("Choose 'Collection' to select from your saved AI outfit inspirations.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func toggleSelection(for id: UUID) {
        // Tactile Haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            if allowsMultipleSelection {
                if selectedLookIds.contains(id) {
                    selectedLookIds.remove(id)
                } else {
                    selectedLookIds.insert(id)
                }
            } else {
                if selectedLookIds.contains(id) {
                    selectedLookIds.removeAll()
                } else {
                    selectedLookIds = [id]
                }
            }
        }
    }
    
    private func confirmSelection() {
        let chosen = savedLooks.filter { selectedLookIds.contains($0.id) }
        onSelectReferences(chosen)
        onDismiss()
    }
}

// MARK: - Preview

#Preview {
    SavedReferencePickerSheet(
        savedLooks: SavedLookItem.samples,
        allowsMultipleSelection: true,
        preselectedLookIds: [SavedLookItem.samples[0].id],
        onSelectReferences: { selected in
            print("Selected: \(selected.count) looks")
        },
        onDismiss: {
            print("Dismissed")
        }
    )
}
