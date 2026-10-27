//
//  OutfitGarmentStrip.swift
//  Challenge-5
//
//  Created by Natalie Grace on 26/10/26.
//

import SwiftData
import SwiftUI

/// "On this outfit": a horizontal row of cropped garments from a look.
/// Tapping a garment calls `onSelectGarment`, which opens `WhereToBuySheet` for it.
///
/// Meant to sit under the avatar on the result stage (Michael's `ResultStageView`).
struct OutfitGarmentStrip: View {

    // MARK: - Properties

    @State private var viewModel: OutfitGarmentStripViewModel
    private let selectedGarmentID: UUID?
    private let onSelectGarment: (GarmentItem) -> Void

    // MARK: - Initializer

    init(look: OutfitLook, selectedGarmentID: UUID? = nil, onSelectGarment: @escaping (GarmentItem) -> Void) {
        _viewModel = State(initialValue: OutfitGarmentStripViewModel(look: look))
        self.selectedGarmentID = selectedGarmentID
        self.onSelectGarment = onSelectGarment
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppDimensions.elementSpacing) {
            Text("On this outfit")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.espressoTitle)
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppDimensions.elementSpacing) {
                    ForEach(viewModel.garments) { garment in
                        thumbnailButton(for: garment)
                    }
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            }
        }
        .task(id: viewModel.look.id) { await viewModel.loadCrops() }
    }

    // MARK: - Subviews

    private func thumbnailButton(for garment: GarmentItem) -> some View {
        let isSelected = garment.id == selectedGarmentID
        return Button {
            onSelectGarment(garment)
        } label: {
            thumbnail(for: garment, isSelected: isSelected)
                .frame(width: StoreConstants.Layout.garmentThumbnailSize,
                       height: StoreConstants.Layout.garmentThumbnailSize)
                .background(AppColors.mutedCaption.opacity(isSelected
                    ? StoreConstants.Layout.garmentThumbnailSelectedBackgroundOpacity
                    : StoreConstants.Layout.garmentThumbnailBackgroundOpacity))
                .clipped()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(garment.category.rawValue): \(garment.name)")
        .accessibilityHint("Searches this item with Google Lens")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func thumbnail(for garment: GarmentItem, isSelected: Bool) -> some View {
        if let crop = viewModel.cropsByGarmentID[garment.id] {
            // Selected: the crop sits on a white rounded card over a darker background.
            let layout = StoreConstants.Layout.self
            let imageSize = isSelected
                ? layout.garmentThumbnailSize - layout.garmentThumbnailSelectedInset * 2
                : layout.garmentThumbnailSize
            Image(crop.image, scale: 1, label: Text(garment.name))
                .resizable()
                .scaledToFill()
                .frame(width: imageSize, height: imageSize)
                .background(AppColors.cardBackground)
                .clipShape(.rect(cornerRadius: isSelected ? AppDimensions.cardCornerRadius : 0))
        } else if viewModel.unavailableGarmentIDs.contains(garment.id) {
            VStack(spacing: AppDimensions.elementSpacing) {
                Image(systemName: "tshirt")
                    .foregroundStyle(AppColors.mutedCaption)
                Text(garment.name)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
                    .multilineTextAlignment(.center)
            }
            .padding(AppDimensions.elementSpacing)
        } else {
            ProgressView()
        }
    }
}

// MARK: - Preview

#Preview {
    if let look = StoreSampleData.looks.first {
        OutfitGarmentStrip(look: look) { _ in }
            .modelContainer(StoreSampleData.container)
    }
}
