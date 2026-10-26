//
//  StoreSandboxView.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import SwiftData
import SwiftUI

/// Test screen for the store flow with dummy looks (C5-75).
/// Not part of the production navigation: tap a garment to open `WhereToBuySheet`.
struct StoreSandboxView: View {

    // MARK: - Properties

    let looks: [OutfitLook]
    @State private var selectedGarment: GarmentItem?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                ForEach(looks) { look in
                    Section("Look \(look.lookIndex + 1)") {
                        lookImage(for: look)
                        ForEach(orderedGarments(of: look)) { garment in
                            Button {
                                selectedGarment = garment
                            } label: {
                                garmentRow(for: garment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Store Sandbox")
        }
        .sheet(item: $selectedGarment) { garment in
            WhereToBuySheet(garment: garment)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func lookImage(for look: OutfitLook) -> some View {
        if let data = look.lookImageData, let image = LookImageDecoder.makeImage(from: data) {
            Image(image, scale: 1, label: Text("Look \(look.lookIndex + 1)"))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: StoreConstants.Layout.sandboxLookImageMaximumHeight)
        } else {
            Text("No look image")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
        }
    }

    private func garmentRow(for garment: GarmentItem) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(garment.category.rawValue.uppercased())
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
                Text(garment.name)
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.bodyText)
                Text("\(garment.material) · \(garment.colorName)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
            }
            Spacer()
            Image(systemName: "cart")
                .foregroundStyle(AppColors.primaryBlue)
        }
        .contentShape(.rect)
    }

    // MARK: - Helpers

    /// Outer, then top, then bottom.
    private func orderedGarments(of look: OutfitLook) -> [GarmentItem] {
        let order = GarmentCategory.allCases
        return look.garments.sorted {
            (order.firstIndex(of: $0.category) ?? 0) < (order.firstIndex(of: $1.category) ?? 0)
        }
    }
}

// MARK: - Preview

#Preview {
    StoreSandboxView(looks: StoreSampleData.looks)
        .modelContainer(StoreSampleData.container)
}
