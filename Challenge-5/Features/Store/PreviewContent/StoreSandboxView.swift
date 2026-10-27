//
//  StoreSandboxView.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import SwiftData
import SwiftUI

/// Test screen for the store flow with the dummy look (C5-75).
/// Not part of the production navigation: it mimics the result stage with the look image and the
/// "On this outfit" row. Tap a garment to open its Google Lens results.
struct StoreSandboxView: View {

    // MARK: - Properties

    let looks: [OutfitLook]
    @State private var selectedGarment: GarmentItem?

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
            OutfitGarmentStrip(look: look, selectedGarmentID: selectedGarment?.id) { garment in
                selectedGarment = garment
            }
        }
    }

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
