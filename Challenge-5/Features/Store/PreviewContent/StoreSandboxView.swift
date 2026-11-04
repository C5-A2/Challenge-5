//
//  StoreSandboxView.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import SwiftData
import SwiftUI

/// Test screen for the store flow with the dummy look (C5-75).
/// Not part of the production navigation: it shows the look image and the Output's
/// "On this outfit" row. Tap a garment to open its Google Lens results.
struct StoreSandboxView: View {

    // MARK: - Properties

    let looks: [OutfitLook]
    @State private var selectedGarment: GarmentItem?
    /// Garment crops for the "On this outfit" cards, by garment ID.
    @State private var cropImagesByGarmentID: [UUID: CGImage] = [:]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppDimensions.sectionSpacing) {
                    occasionTitle
                    ForEach(looks) { look in
                        lookSection(for: look)
                    }
                }
                .padding(.vertical, AppDimensions.sectionSpacing)
            }
            .background(AppColors.canvasBackground)
        }
        .task { await loadCrops() }
        .sheet(item: $selectedGarment) { garment in
            WhereToBuySheet(garment: garment)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews

    private var occasionTitle: some View {
        Text(StoreSampleData.occasionTitle)
            .font(AppTypography.displayTitle)
            .foregroundStyle(AppColors.espressoTitle)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
    }

    private func lookSection(for look: OutfitLook) -> some View {
        VStack(alignment: .leading, spacing: AppDimensions.elementSpacing) {
            lookImage(for: look)
            // Same "On this outfit" row as the Output.
            OnThisOutfitSection(
                garments: look.garments.sortedForOutfitDisplay(),
                garmentCropImages: cropImagesByGarmentID,
                onSelectGarment: { garment in selectedGarment = garment }
            )
        }
    }

    // MARK: - Actions

    private func loadCrops() async {
        for look in looks {
            let crops = await GarmentCropProvider.shared.crops(for: look.garments)
            cropImagesByGarmentID.merge(crops.mapValues(\.image)) { _, newImage in newImage }
        }
    }

    // MARK: - Look Image

    @ViewBuilder
    private func lookImage(for look: OutfitLook) -> some View {
        if let image = try? GarmentCropProvider.shared.lookImage(for: look) {
            Image(image, scale: 1, label: Text("Look \(look.lookIndex + 1)"))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: StoreConstants.Layout.sandboxLookImageMaximumHeight)
        } else {
            Text("No look image")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        }
    }
}

// MARK: - Preview

#Preview {
    StoreSandboxView(looks: StoreSampleData.looks)
        .modelContainer(StoreSampleData.container)
}
