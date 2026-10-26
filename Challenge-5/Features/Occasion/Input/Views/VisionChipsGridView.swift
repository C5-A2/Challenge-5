//
//  VisionChipsGridView.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import SwiftUI

/// Section displaying the "I want to look more" header and predefined `StyleVision` chips.
public struct VisionChipsGridView: View {
    
    // MARK: - Properties
    @Bindable public var viewModel: OccasionInputViewModel
    
    // MARK: - Initializer
    public init(viewModel: OccasionInputViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            Text("I want to look more")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
                .padding(.leading, 4)
                .padding(.top, 4)
            
            // Chips Flow
            FlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(StyleVision.allCases) { vision in
                    MultiSelectChip(
                        label: vision.rawValue.lowercased(),
                        isSelected: viewModel.isVisionSelected(vision),
                        showsPlusIcon: true
                    ) {
                        viewModel.toggleVision(vision)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var viewModel = OccasionInputViewModel(
        selectedVisions: [.confident]
    )
    
    return ScrollView {
        VisionChipsGridView(viewModel: viewModel)
            .padding()
    }
    .background(AppColors.sheetBackground)
}
