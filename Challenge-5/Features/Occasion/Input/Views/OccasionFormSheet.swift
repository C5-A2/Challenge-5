//
//  OccasionFormSheet.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import SwiftUI

/// A modal sheet view for entering occasion details.
///
/// Captures only the core parameters for an occasion:
/// - Occasion title
/// - Date
/// - Dress code
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
                AppColors.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Drag Handle Indicator
                    dragHandle
                    
                    // Header Bar (Close, Title, Submit)
                    headerBar
                        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    
                    // Form Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: AppDimensions.elementSpacing + 4) {
                            // 1. Occasion Title Field
                            occasionTitleField
                            
                            // 2. Date Picker Row
                            dateRow
                            
                            // 3. Dresscode Section
                            dresscodeSection
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
    
    /// Top pill drag indicator for modal sheet styling.
    private var dragHandle: some View {
        Capsule()
            .fill(Color(hex: "#D6D1CA").opacity(0.8))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
    }
    
    /// Custom top navigation bar containing close button, screen title, and submit button.
    private var headerBar: some View {
        HStack {
            // Dismiss button (xmark)
            CircularIconButton(systemName: "xmark") {
                handleClose()
            }
            
            Spacer()
            
            // Screen title
            Text("Occasion Outfit")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColors.espressoTitle)
            
            Spacer()
            
            // Submit button (arrow.up)
            CircularIconButton(
                systemName: "arrow.up",
                isFilled: viewModel.isValid
            ) {
                handleSave()
            }
            .opacity(viewModel.isValid ? 1.0 : 0.45)
            .disabled(!viewModel.isValid)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isValid)
        }
    }
    
    /// Single-row pill input field for the occasion title.
    private var occasionTitleField: some View {
        HStack {
            TextField("Occasion", text: $viewModel.title)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.espressoTitle)
            
            if !viewModel.title.isEmpty {
                Button(action: { viewModel.title = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.mutedCaption.opacity(0.7))
                        .font(.system(size: 15))
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius + 4, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    /// Pill container presenting the Date label and standard iOS compact DatePicker.
    private var dateRow: some View {
        DatePicker(
            "Date",
            selection: $viewModel.date,
            displayedComponents: [.date]
        )
        .font(AppTypography.bodyRegular)
        .foregroundStyle(AppColors.espressoTitle)
        .tint(AppColors.espressoTitle)
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius + 4, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    /// Section displaying the "Dresscode" header and its pill input field.
    private var dresscodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dresscode")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
                .padding(.leading, 4)
                .padding(.top, 4)
            
            HStack {
                TextField("Occasion", text: $viewModel.dresscode)
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.espressoTitle)
                
                if !viewModel.dresscode.isEmpty {
                    Button(action: { viewModel.dresscode = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.mutedCaption.opacity(0.7))
                            .font(.system(size: 15))
                    }
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius + 4, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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

// MARK: - Preview

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
