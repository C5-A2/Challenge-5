//
//  OccasionFormSheet.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import SwiftData
import SwiftUI

/// A modal sheet view for viewing, creating, or editing occasion details.
///
/// Supports three modes:
/// - `.create`: Shows the header arrow button to save, editable form inputs.
/// - `.view`: Read-only layout showing occasion details, with an "Edit" button in the header.
/// - `.edit`: Editable inputs with a checkmark save button, plus a "Delete Occasion" button at the bottom.
@MainActor
public struct OccasionFormSheet: View {
    
    // MARK: - Mode
    
    public enum Mode {
        case create
        case view
        case edit
    }
    
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    @State public var viewModel: OccasionInputViewModel
    @State public var mode: Mode
    private let initialMode: Mode
    
    @State private var isShowingDeleteConfirmation: Bool = false
    @State private var isShowingSaveConfirmation: Bool = false
    @State private var isShowingDatePicker: Bool = false
    
    // MARK: - Callbacks
    
    /// Invoked when the user taps the submit/save button with valid input.
    public var onSave: ((OccasionDetail) -> Void)?
    
    /// Invoked when the user confirms deleting this occasion.
    public var onDelete: (() -> Void)?
    
    /// Invoked when the user dismisses the sheet.
    public var onDismiss: (() -> Void)?
    
    // MARK: - Initializers
    
    public init(
        viewModel: OccasionInputViewModel,
        initialMode: Mode = .create,
        onSave: ((OccasionDetail) -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        _mode = State(initialValue: initialMode)
        self.initialMode = initialMode
        self.onSave = onSave
        self.onDelete = onDelete
        self.onDismiss = onDismiss
    }
    
    public init(
        initialMode: Mode = .create,
        onSave: ((OccasionDetail) -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: OccasionInputViewModel())
        _mode = State(initialValue: initialMode)
        self.initialMode = initialMode
        self.onSave = onSave
        self.onDelete = onDelete
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
                    
                    // Header Bar (Close, Title, Dynamic Action Button)
                    headerBar
                        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    
                    // Form Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: AppDimensions.elementSpacing + 4) {
                            if mode == .view {
                                viewModeContent
                            } else {
                                editModeContent
                            }
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
                    if mode == .edit && initialMode == .view {
                        viewModel.resetToInitial()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            mode = .view
                        }
                    } else {
                        dismiss()
                        onDismiss?()
                    }
                }
            )
            .alert("Delete Occasion?", isPresented: $isShowingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this occasion? This action cannot be undone.")
            }
            .alert("Save Changes?", isPresented: $isShowingSaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Yes") {
                    performSave()
                }
            } message: {
                Text("Saving changes will regenerate your outfit recommendations. This action cannot be undone.")
            }
            .sheet(isPresented: $viewModel.isShowingVisionPicker) {
                StyleVisionPickerSheet(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Subviews
    
    private var headerBar: some View {
        HStack {
            CircularIconButton(
                systemName: "xmark",
                action: handleClose
            )
            
            Spacer()
            
            ModalTitleView("Occasion Outfit")
            
            Spacer()
            
            switch mode {
            case .create:
                CircularIconButton(
                    systemName: "arrow.up",
                    isFilled: viewModel.isValid,
                    isEnabled: viewModel.isValid,
                    action: handleSave
                )
            case .view:
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mode = .edit
                    }
                } label: {
                    Text("Edit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(AppColors.primaryBlack)
                        .clipShape(Capsule())
                }
            case .edit:
                Button(action: handleSave) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(
                            width: AppDimensions.circularIconSize,
                            height: AppDimensions.circularIconSize
                        )
                        .background(AppColors.primaryBlack)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(viewModel.isValid ? 0.08 : 0.02), radius: 3, y: 1)
                }
                .disabled(!viewModel.isValid)
                .opacity(viewModel.isValid ? 1.0 : 0.45)
            }
        }
    }
    
    private var viewModeContent: some View {
        VStack(spacing: AppDimensions.elementSpacing + 4) {
            // 1. Occasion Title Card
            HStack {
                Text(viewModel.title.isEmpty ? "Untitled Occasion" : viewModel.title)
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.espressoTitle)
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: AppDimensions.inputFieldHeight)
            .background(AppColors.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius)
                    .strokeBorder(AppColors.inputBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
            
            // 2. Date Card with Capsule Badge
            HStack {
                Text("Date")
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.primaryBlack)
                
                Spacer()
                
                dateCapsuleBadge
            }
            .padding(.horizontal, 18)
            .frame(height: AppDimensions.inputFieldHeight)
            .background(AppColors.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius)
                    .strokeBorder(AppColors.inputBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
            
            // 3. Dresscode Section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("Dresscode")
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Text("(Optional)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText.opacity(0.6))
                }
                .padding(.leading, 4)
                .padding(.top, 4)
                
                HStack {
                    Text(viewModel.dresscode.isEmpty ? "-" : viewModel.dresscode)
                        .font(AppTypography.bodyRegular)
                        .foregroundStyle(viewModel.dresscode.isEmpty ? AppColors.inputPlaceholder : AppColors.espressoTitle)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(height: AppDimensions.inputFieldHeight)
                .background(AppColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius)
                        .strokeBorder(AppColors.inputBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
            }
            
            // 4. Style Vision Row
            visionSelectorSection(isInteractive: false)
            
            // 5. Reference Photos (Read-Only)
            ReferenceImagesView(viewModel: viewModel, isEditable: false)
        }
    }
    
    private var dateCapsuleBadge: some View {
        Text(viewModel.date.formatted(date: .long, time: .omitted))
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppColors.primaryBlack)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
    }

    private var editModeContent: some View {
        VStack(spacing: AppDimensions.elementSpacing + 4) {
            // 1. Occasion Title Field (Required, Max 50 Characters)
            VStack(alignment: .trailing, spacing: 6) {
                PillTextField(
                    placeholder: "Occasion Title",
                    text: $viewModel.title
                )
                
                HStack {
                    if viewModel.title.count > OccasionInputViewModel.maxTitleLength {
                        Text("Maximum \(OccasionInputViewModel.maxTitleLength) characters allowed")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color(hex: "#FF3B30"))
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.title.count)/\(OccasionInputViewModel.maxTitleLength)")
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundStyle(
                            viewModel.title.count > OccasionInputViewModel.maxTitleLength
                                ? Color(hex: "#FF3B30")
                                : AppColors.mutedCaption
                        )
                }
                .padding(.horizontal, 14)
            }
            
            // 2. Date Picker Row (Defaults to tomorrow, past dates disabled)
            Button {
                isShowingDatePicker = true
            } label: {
                HStack {
                    Text("Date")
                        .font(AppTypography.bodyRegular)
                        .foregroundStyle(AppColors.primaryBlack)
                    
                    Spacer()
                    
                    dateCapsuleBadge
                }
            }
            .buttonStyle(.plain)
            .pillInputContainer()
            .popover(isPresented: $isShowingDatePicker, arrowEdge: .top) {
                CalendarPickerSheet(
                    selectedDate: $viewModel.date,
                    minimumDate: min(
                        Calendar.current.startOfDay(for: Date()),
                        Calendar.current.startOfDay(for: viewModel.date)
                    ),
                    showCardChrome: false
                ) {
                    isShowingDatePicker = false
                }
                .frame(width: 320)
                .presentationCompactAdaptation(.popover)
                .presentationBackground(Color.white)
            }
            
            // 3. "I Want to Look More" Selector Row (Opens picker modal, shows chosen under)
            visionSelectorSection(isInteractive: true)
            
            // 4. Dresscode Section (Optional)
            dresscodeSection
            
            // 5. Reference Photos Section (Optional, Max 3)
            ReferenceImagesView(viewModel: viewModel, isEditable: true)
            
            // 6. Delete Occasion Button (Only presented below the last question when editing)
            if mode == .edit, onDelete != nil {
                Button {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text("Delete Occasion")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.destructiveRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
    }
    
    /// "I Want to Look More" picker button showing the chosen style visions underneath.
    private func visionSelectorSection(isInteractive: Bool) -> some View {
        Button {
            if isInteractive {
                viewModel.isShowingVisionPicker = true
            }
        } label: {
            VStack(spacing: 0) {
                // Top Row: Title and Chevron
                HStack {
                    Text("I Want to Look More")
                        .font(AppTypography.bodyRegular)
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.inputPlaceholder)
                }
                .padding(.horizontal, 18)
                .frame(height: AppDimensions.inputFieldHeight)
                
                // Divider
                Divider()
                    .overlay(AppColors.inputBorder)
                    .padding(.horizontal, 18)
                
                // Bottom Row: Chosen Style Visions or Placeholder
                HStack {
                    Text(viewModel.selectedVisionsSummaryText)
                        .font(AppTypography.caption)
                        .foregroundStyle(
                            viewModel.selectedVisions.isEmpty
                                ? AppColors.inputPlaceholder
                                : AppColors.mutedCaption
                        )
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(height: 38)
            }
            .background(AppColors.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius)
                    .strokeBorder(AppColors.inputBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
    }
    
    /// Section displaying the "Dresscode" header and its optional pill input field.
    private var dresscodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Dresscode")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text("(Optional)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.bodyText.opacity(0.6))
            }
            .padding(.leading, 4)
            .padding(.top, 4)
            
            PillTextField(
                placeholder: "Dresscode",
                text: $viewModel.dresscode
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleClose() {
        if mode == .edit && initialMode == .view {
            if viewModel.hasUnsavedChanges {
                viewModel.isShowingDiscardAlert = true
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    mode = .view
                }
            }
        } else if viewModel.hasUnsavedChanges {
            viewModel.isShowingDiscardAlert = true
        } else {
            dismiss()
            onDismiss?()
        }
    }
    
    private func handleSave() {
        guard viewModel.isValid else { return }
        if mode == .edit {
            isShowingSaveConfirmation = true
        } else {
            performSave()
        }
    }
    
    private func performSave() {
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
        .modelContainer(for: [OccasionItem.self, OutfitLook.self, GarmentItem.self], inMemory: true)
}

/// "+ Add Ref" → "From Library" shows 4 saved looks. Reopen it to see the picked ones preselected.
#Preview("Saved Looks as References") {
    OccasionFormSheet()
        .modelContainer(SavedLookSampleData.makeContainer(savedLookCount: 4))
}

#Preview("Prefilled State") {
    OccasionFormSheet(
        viewModel: OccasionInputViewModel(
            title: "Annual Gala Dinner",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            dresscode: "Black Tie Optional"
        )
    )
    .modelContainer(for: [OccasionItem.self, OutfitLook.self, GarmentItem.self], inMemory: true)
}
