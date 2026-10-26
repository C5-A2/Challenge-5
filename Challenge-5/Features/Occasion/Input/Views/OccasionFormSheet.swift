//
//  OccasionFormSheet.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import SwiftUI

/// A modal sheet view for entering occasion details.
///
/// Built entirely using the shared design system components:
/// - `SheetDragHandle`
/// - `ModalHeaderBar` (powered by `CircularIconButton`)
/// - `PillTextField` (for title and dresscode input)
/// - `pillInputContainer` modifier (for the native DatePicker row)
/// - `discardConfirmation` dialog
@MainActor
public struct OccasionFormSheet: View {
    
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    @State public var viewModel: OccasionInputViewModel
    
    // MARK: - Callbacks
    
    /// Invoked when the user taps the submit button with valid input.
    public var onSave: ((OccasionDetail) -> Void)?
    
    /// Invoked when the user dismisses the sheet.
    public var onDismiss: (() -> Void)?
    
    // MARK: - Initializers
    
    public init(
        viewModel: OccasionInputViewModel,
        onSave: ((OccasionDetail) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
        self.onDismiss = onDismiss
    }
    
    public init(
        onSave: ((OccasionDetail) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: OccasionInputViewModel())
        self.onSave = onSave
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.sheetBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Drag Handle Indicator
                    SheetDragHandle()
                    
                    // Header Bar (Close, Title, Submit)
                    ModalHeaderBar(
                        title: "Occasion Outfit",
                        leadingIconSystemName: "xmark",
                        trailingIconSystemName: "arrow.up",
                        isTrailingFilled: viewModel.isValid,
                        isTrailingEnabled: viewModel.isValid,
                        onLeadingAction: handleClose,
                        onTrailingAction: handleSave
                    )
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    
                    // Form Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: AppDimensions.elementSpacing + 4) {
                            // 1. Occasion Title Field
                            PillTextField(
                                placeholder: "Occasion",
                                text: $viewModel.title
                            )
                            
                            // 2. Date Picker Row
                            DatePicker(
                                "Date",
                                selection: $viewModel.date,
                                displayedComponents: [.date]
                            )
                            .font(AppTypography.bodyRegular)
                            .foregroundStyle(AppColors.espressoTitle)
                            .tint(AppColors.espressoTitle)
                            .pillInputContainer()
                            
                            // 3. Dresscode Section
                            dresscodeSection
                            
                            // 4. "I want to look more" Style Vision Chips Section
                            VisionChipsGridView(viewModel: viewModel)
                        }
                        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .discardConfirmation(
                isPresented: $viewModel.isShowingDiscardAlert,
                title: "Discard Occasion?",
                message: "You have unsaved changes. Are you sure you want to discard them?",
                onDiscard: {
                    dismiss()
                    onDismiss?()
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    /// Section displaying the "Dresscode" header and its pill input field.
    private var dresscodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dresscode")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
                .padding(.leading, 4)
                .padding(.top, 4)
            
            PillTextField(
                placeholder: "Occasion",
                text: $viewModel.dresscode
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleClose() {
        if viewModel.hasUnsavedChanges {
            viewModel.isShowingDiscardAlert = true
        } else {
            dismiss()
            onDismiss?()
        }
    }
    
    private func handleSave() {
        guard viewModel.isValid else { return }
        let detail = viewModel.createOccasionDetail()
        onSave?(detail)
        dismiss()
    }
}

// MARK: - Typealias for Convenience

public typealias OccasionInputView = OccasionFormSheet

// MARK: - Previews

#Preview("Empty State") {
    OccasionFormSheet()
}

#Preview("Prefilled State") {
    OccasionFormSheet(
        viewModel: OccasionInputViewModel(
            title: "Annual Gala Dinner",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            dresscode: "Black Tie Optional"
        )
    )
}
