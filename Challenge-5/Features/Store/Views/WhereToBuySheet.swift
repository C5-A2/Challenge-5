//
//  WhereToBuySheet.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import SwiftData
import SwiftUI

/// Bottom sheet that shows Google Lens results for one cropped garment of a look (C5-112).
///
/// The garment is picked from the "On this outfit" row (`OutfitGarmentStrip`). Presented when
/// `appState.isShowingWhereToBuySheet` is true, for `appState.selectedGarmentForPurchase`
/// (integration contract 8.2).
struct WhereToBuySheet: View {

    // MARK: - Properties

    @State private var viewModel: StoreViewModel
    @State private var isLensPageLoading = true
    @State private var isShowingMoreActions = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializers

    init(garment: GarmentItem) {
        _viewModel = State(initialValue: StoreViewModel(garment: garment))
    }

    init(viewModel: StoreViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppDimensions.elementSpacing) {
            header
            googleLensContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.cardBackground)
        .task { await viewModel.loadInitialContent() }
        .alert("Search With Your Look Image?", isPresented: $viewModel.isShowingUploadConsent) {
            Button("Not Now", role: .cancel) { viewModel.declineUploadConsent() }
            Button("Allow") { Task { await viewModel.grantUploadConsent() } }
        } message: {
            Text("To find similar items, the cropped garment image is sent to Google Lens.")
        }
        .alert(viewModel.photoSaveMessage ?? "", isPresented: $viewModel.isShowingPhotoSaveResult) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Header

    /// Close button, "Shop" title, and "more" menu, with the garment name below.
    private var header: some View {
        VStack(spacing: AppDimensions.elementSpacing) {
            ZStack {
                Text("Shop")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                HStack {
                    CircularIconButton(systemName: "xmark") { dismiss() }
                        .accessibilityLabel("Close")
                    Spacer()
                    moreButton
                }
            }
            Text(viewModel.sheetTitle)
                .font(AppTypography.chipLabel)
                .foregroundStyle(AppColors.bodyText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, AppDimensions.sectionSpacing)
    }

    /// The shared `CircularIconButton` opens the extra actions as a dialog anchored to the button.
    private var moreButton: some View {
        CircularIconButton(systemName: "ellipsis") { isShowingMoreActions = true }
            .accessibilityLabel("More")
            .confirmationDialog("More", isPresented: $isShowingMoreActions, titleVisibility: .hidden) {
                #if os(iOS)
                Button("Save to Photos") {
                    Task { await viewModel.saveGarmentCropToPhotos() }
                }
                .disabled(viewModel.garmentCrop == nil)
                #endif
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var googleLensContent: some View {
        #if os(iOS)
        if let lensPage = viewModel.lensPage {
            LensWebView(request: lensPage.request, isLoading: $isLensPageLoading)
                .id(lensPage.id)
                .overlay {
                    if isLensPageLoading {
                        ProgressView()
                    }
                }
        } else {
            lensStatusView
        }
        #else
        lensStatusView
        #endif
    }

    /// Shown before Lens results load: cropping, the search button, or why search isn't available.
    private var lensStatusView: some View {
        ScrollView {
            VStack(spacing: AppDimensions.sectionSpacing) {
                if let garmentCrop = viewModel.garmentCrop {
                    Image(garmentCrop.image, scale: 1, label: Text("Cropped \(viewModel.garment.name)"))
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: StoreConstants.Layout.lensStatusCropMaximumHeight)
                        .clipShape(.rect(cornerRadius: AppDimensions.cardCornerRadius))
                }
                lensStatusContent
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.vertical, AppDimensions.sectionSpacing)
        }
    }

    @ViewBuilder
    private var lensStatusContent: some View {
        switch viewModel.visualSearchState {
        case .idle:
            lensSearchButton
        case .cropping:
            ProgressView("Finding the \(viewModel.garment.category.rawValue.lowercased()) in your look…")
        case .unavailable(let message):
            lensMessage(message, color: AppColors.mutedCaption)
            if viewModel.garmentCrop != nil {
                lensSearchButton
            }
        case .failed(let message):
            lensMessage(message, color: AppColors.destructiveRed)
            lensSearchButton
        }
    }

    private var lensSearchButton: some View {
        PrimaryPillButton(title: "Search with Google Lens", isEnabled: viewModel.garmentCrop != nil) {
            Task { await viewModel.requestLensSearch() }
        }
    }

    private func lensMessage(_ message: String, color: Color) -> some View {
        Text(message)
            .font(AppTypography.caption)
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Preview

#Preview("Live services") {
    WhereToBuySheet(garment: StoreSampleData.sampleGarment)
        .modelContainer(StoreSampleData.container)
}

#Preview("Mock services") {
    WhereToBuySheet(
        viewModel: StoreViewModel(
            garment: StoreSampleData.sampleGarment,
            cropProvider: GarmentCropProvider(cropper: MockGarmentCropper(), cropCache: GarmentCropCache())
        )
    )
    .modelContainer(StoreSampleData.container)
}
