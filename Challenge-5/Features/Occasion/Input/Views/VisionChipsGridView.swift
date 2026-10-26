//
//  VisionChipsGridView.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import SwiftUI

/// Section displaying the "I want to look more" header and predefined `StyleVision` chips.
@MainActor
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
            // Header with Selection Counter & Optional Indicator (Min 0, Max 3)
            HStack(alignment: .firstTextBaseline) {
                Text("I want to look more")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text("(Optional)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.bodyText.opacity(0.6))
                
                Spacer()
                
                Text("\(viewModel.selectedVisions.count)/3")
                    .font(AppTypography.caption)
                    .foregroundStyle(viewModel.selectedVisions.count >= 3 ? AppColors.espressoTitle : AppColors.bodyText.opacity(0.6))
            }
            .padding(.leading, 4)
            .padding(.top, 4)
            
            // Chips Flow (Alphabetical, capped at 3 selections)
            FlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(StyleVision.allCases) { vision in
                    let isSelected = viewModel.isVisionSelected(vision)
                    let isMaxReached = viewModel.selectedVisions.count >= 3 && !isSelected
                    
                    MultiSelectChip(
                        label: vision.rawValue.lowercased(),
                        isSelected: isSelected,
                        showsPlusIcon: true
                    ) {
                        viewModel.toggleVision(vision)
                    }
                    .opacity(isMaxReached ? 0.45 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isMaxReached)
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
