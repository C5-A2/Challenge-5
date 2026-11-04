//
//  StyleVisionPickerSheet.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 03/11/26.
//

import SwiftUI

/// Modal sheet allowing the user to select desired emotional style impressions (StyleVision).
///
/// Features:
/// - Leading back button (`<`) to dismiss.
/// - Centered title "I Want to Look More" with subtitle "Pick Min. 1, Max 3".
/// - Vertical list of all `StyleVision` items with trailing checkmarks for selected items.
/// - Enforces selection rules (min 1, max 3).
@MainActor
public struct StyleVisionPickerSheet: View {
    
    // MARK: - Environment & ViewModel
    @Environment(\.dismiss) private var dismiss
    @Bindable public var viewModel: OccasionInputViewModel
    
    // MARK: - Initializer
    public init(viewModel: OccasionInputViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            // Background Canvas
            AppColors.canvasBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Drag Handle Indicator
                SheetDragHandle()
                
                // Top Header Bar
                headerBar
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Vision List Container
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        let allVisions = StyleVision.allCases
                        ForEach(Array(allVisions.enumerated()), id: \.element.id) { index, vision in
                            visionRow(vision)
                            
                            if index < allVisions.count - 1 {
                                Divider()
                                    .overlay(AppColors.inputBorder)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                            .strokeBorder(AppColors.inputBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.bottom, 32)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Subviews
    
    /// Header bar with leading back button, centered title + subtitle, and trailing placeholder.
    private var headerBar: some View {
        HStack {
            // Leading Back Button
            CircularIconButton(
                systemName: "chevron.left",
                action: { dismiss() }
            )
            
            Spacer()
            
            // Centered Title and Subtitle
            VStack(spacing: 4) {
                Text("I Want to Look More")
                    .font(AppTypography.sfProSemiboldExtended(size: 18))
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text("Pick Min. 1, Max 3")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
            }
            
            Spacer()
            
            // Trailing Placeholder to keep title balanced
            Color.clear
                .frame(
                    width: AppDimensions.circularIconSize,
                    height: AppDimensions.circularIconSize
                )
        }
    }
    
    /// Row for a single `StyleVision` option.
    private func visionRow(_ vision: StyleVision) -> some View {
        let isSelected = viewModel.isVisionSelected(vision)
        
        return Button {
            viewModel.toggleVision(vision)
        } label: {
            HStack {
                Text(vision.rawValue)
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 52)
            .padding(.horizontal, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var viewModel = OccasionInputViewModel(
        selectedVisions: [.approachable, .competent, .elegant]
    )
    
    StyleVisionPickerSheet(viewModel: viewModel)
}

