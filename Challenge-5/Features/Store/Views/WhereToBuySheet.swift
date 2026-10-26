//
//  WhereToBuySheet.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import SwiftData
import SwiftUI

/// Bottom sheet that helps the user find where to buy one garment of a look (C5-112).
///
/// Presented when `appState.isShowingWhereToBuySheet` is true, for
/// `appState.selectedGarmentForPurchase` (integration contract 8.2).
struct WhereToBuySheet: View {

    // MARK: - Properties

    @State private var viewModel: StoreViewModel
    @State private var presentedPage: StoreWebPage?
    @Environment(\.openURL) private var openURL

    // MARK: - Initializers

    init(garment: GarmentItem) {
        _viewModel = State(initialValue: StoreViewModel(garment: garment))
    }

    init(viewModel: StoreViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppDimensions.sectionSpacing) {
                    garmentHeader
                    garmentCropPreview
                    visualSearchSection
                    marketplaceSection
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                .padding(.vertical, AppDimensions.sectionSpacing)
            }
            .background(AppColors.canvasBackground)
            .navigationTitle("Where to Buy")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .task { await viewModel.prepareGarmentCrop() }
        .onChange(of: viewModel.visualSearchState) { _, newState in
            if case .ready(let lensURL) = newState {
                open(lensURL)
                viewModel.markLensPageOpened()
            }
        }
        .alert("Search With Your Look Image?", isPresented: $viewModel.isShowingUploadConsent) {
            Button("Not Now", role: .cancel) { viewModel.declineUploadConsent() }
            Button("Allow") { Task { await viewModel.grantUploadConsent() } }
        } message: {
            Text(viewModel.uploadConsentMessage)
        }
        #if os(iOS)
        .sheet(item: $presentedPage) { page in
            SafariView(url: page.url)
                .ignoresSafeArea()
        }
        .fullScreenCover(item: $viewModel.directLensPage) { page in
            LensWebPageView(page: page)
        }
        #endif
    }

    // MARK: - Subviews

    private var garmentHeader: some View {
        VStack(alignment: .leading, spacing: AppDimensions.elementSpacing) {
            Text(viewModel.garment.category.rawValue.uppercased())
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
            Text(viewModel.garment.name)
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.espressoTitle)
            Text("\(viewModel.garment.material) · \(viewModel.garment.colorName)")
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.mutedCaption)
        }
    }

    @ViewBuilder
    private var garmentCropPreview: some View {
        if let garmentCrop = viewModel.garmentCrop {
            Image(garmentCrop, scale: 1, label: Text("Cropped \(viewModel.garment.name)"))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: StoreConstants.Layout.cropPreviewMaximumHeight)
                .background(AppColors.cardBackground)
                .clipShape(.rect(cornerRadius: AppDimensions.cardCornerRadius))
        } else if viewModel.visualSearchState == .cropping {
            ProgressView("Finding the \(viewModel.garment.category.rawValue.lowercased()) in your look…")
                .frame(maxWidth: .infinity, minHeight: StoreConstants.Layout.cropPreviewMaximumHeight)
        }
    }

    private var visualSearchSection: some View {
        VStack(alignment: .leading, spacing: AppDimensions.elementSpacing) {
            Text("Search by image")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.bodyText)
            visualSearchContent
        }
    }

    @ViewBuilder
    private var visualSearchContent: some View {
        switch viewModel.visualSearchState {
        case .idle, .ready:
            searchButtons
        case .cropping:
            PrimaryPillButton(title: "Preparing image…", isEnabled: false) {}
        case .uploading:
            HStack(spacing: AppDimensions.elementSpacing) {
                ProgressView()
                Text("Uploading image…")
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.mutedCaption)
            }
        case .unavailable(let message):
            VStack(alignment: .leading, spacing: AppDimensions.elementSpacing) {
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
                // The other search method may still work, so keep the buttons when there is a crop.
                if viewModel.garmentCrop != nil {
                    searchButtons
                }
            }
        case .failed(let message):
            // Tapping a search button again retries.
            VStack(alignment: .leading, spacing: AppDimensions.elementSpacing) {
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.destructiveRed)
                searchButtons
            }
        }
    }

    /// Two ways to reach Google Lens, kept side by side for comparison (C5-55).
    private var searchButtons: some View {
        VStack(spacing: AppDimensions.elementSpacing) {
            #if os(iOS)
            PrimaryPillButton(title: "Google Lens (direct)", isEnabled: viewModel.garmentCrop != nil) {
                Task { await viewModel.requestVisualSearch(using: .directUpload) }
            }
            #endif
            PrimaryPillButton(title: "Google Lens (via imgbb)", isEnabled: viewModel.garmentCrop != nil) {
                Task { await viewModel.requestVisualSearch(using: .hostedImage) }
            }
        }
    }

    private var marketplaceSection: some View {
        VStack(alignment: .leading, spacing: AppDimensions.elementSpacing) {
            Text("Search by keyword")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.bodyText)
            Text("Keyword: \(viewModel.searchKeyword)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
            ForEach(viewModel.marketplaceLinks) { link in
                marketplaceButton(for: link)
            }
        }
    }

    private func marketplaceButton(for link: MarketplaceSearchLink) -> some View {
        Button {
            open(link.url)
        } label: {
            HStack {
                Text(link.marketplace.rawValue)
                    .font(AppTypography.buttonLabel)
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .foregroundStyle(AppColors.primaryBlue)
            .padding(AppDimensions.cardInternalPadding)
            .background(AppColors.cardBackground)
            .clipShape(.rect(cornerRadius: AppDimensions.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func open(_ url: URL) {
        #if os(iOS)
        presentedPage = StoreWebPage(url: url)
        #else
        openURL(url)
        #endif
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
            cropper: MockGarmentCropper(),
            uploader: MockImageUploader()
        )
    )
    .modelContainer(StoreSampleData.container)
}
