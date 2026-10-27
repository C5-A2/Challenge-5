//
//  ReferenceImagesView.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

import PhotosUI
import SwiftData
import SwiftUI

/// Section displaying the "Reference" header and the reference photo row:
/// an "+ Add Ref" tile followed by up to 3 picked photos, each with an X button to remove it.
///
/// "+ Add Ref" opens `ImageSourceMenu`:
/// - **Camera**: `ReferenceCameraView`
/// - **Open from Photos**: the user's photo library (`PhotosPicker`)
/// - **From Library**: bookmarked looks saved in the app (`SavedReferencePickerSheet`)
@MainActor
struct ReferenceImagesView: View {

    // MARK: - Properties

    @Bindable var viewModel: OccasionInputViewModel
    @Query(filter: #Predicate<OutfitLook> { $0.isBookmarked }, sort: \OutfitLook.lookIndex)
    private var bookmarkedLooks: [OutfitLook]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppDimensions.elementSpacing) {
            header
            referenceRow
        }
        .fullScreenCover(isPresented: $viewModel.isShowingReferenceCamera) {
            ReferenceCameraView(viewModel: viewModel)
        }
        .photosPicker(
            isPresented: $viewModel.isShowingReferencePhotoPicker,
            selection: $viewModel.referencePhotoPickerItems,
            maxSelectionCount: viewModel.remainingReferenceCount,
            matching: .images
        )
        .onChange(of: viewModel.referencePhotoPickerItems) {
            Task { await viewModel.loadPickedReferencePhotos() }
        }
        .sheet(isPresented: $viewModel.isShowingReferenceLibrary) {
            SavedReferencePickerSheet(
                savedLooks: viewModel.savedReferenceLooks(from: bookmarkedLooks),
                allowsMultipleSelection: true,
                onSelectReferences: { pickedLooks in viewModel.addReferenceImages(from: pickedLooks) },
                onDismiss: { viewModel.isShowingReferenceLibrary = false }
            )
        }
    }

    // MARK: - Subviews

    /// "Reference (Optional)" with the photo counter, matching the other form section headers.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Reference")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
            Text("(Optional)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
            Spacer()
            Text("\(viewModel.referenceImages.count)/\(ReferencePickerConstants.maximumReferenceCount)")
                .font(AppTypography.caption)
                .foregroundStyle(viewModel.canAddMoreReferences ? AppColors.mutedCaption : AppColors.espressoTitle)
        }
        // Same inset as the Dresscode and "I want to look more" headers.
        .padding(.leading, ReferencePickerConstants.Row.headerInset)
        .padding(.top, ReferencePickerConstants.Row.headerInset)
    }

    private var referenceRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppDimensions.elementSpacing) {
                if viewModel.canAddMoreReferences {
                    addReferenceTile
                }
                ForEach(Array(viewModel.referenceImages.enumerated()), id: \.offset) { index, imageData in
                    referenceThumbnail(imageData, at: index)
                }
                if viewModel.isLoadingReferencePhotos {
                    ProgressView()
                        .frame(width: ReferencePickerConstants.Row.tileWidth,
                               height: ReferencePickerConstants.Row.tileHeight)
                }
            }
        }
    }

    private var addReferenceTile: some View {
        ImageSourceMenu(onSelect: { option in viewModel.selectReferenceSource(option) }) {
            VStack(spacing: AppDimensions.elementSpacing) {
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(AppTypography.screenHeader)
                Text("+ Add Ref")
                    .font(AppTypography.chipLabel)
            }
            .foregroundStyle(AppColors.primaryBlue)
            .frame(width: ReferencePickerConstants.Row.tileWidth, height: ReferencePickerConstants.Row.tileHeight)
            .background(AppColors.primaryBlue.opacity(ReferencePickerConstants.Row.addTileBackgroundOpacity))
            .clipShape(.rect(cornerRadius: AppDimensions.chipCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppDimensions.chipCornerRadius)
                    .strokeBorder(
                        AppColors.primaryBlue.opacity(ReferencePickerConstants.Row.addTileBorderOpacity),
                        style: StrokeStyle(lineWidth: ReferencePickerConstants.Row.addTileBorderWidth,
                                           dash: [ReferencePickerConstants.Row.addTileDashLength])
                    )
            }
        }
        .accessibilityLabel("Add reference photo")
    }

    private func referenceThumbnail(_ imageData: Data, at index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            thumbnailImage(imageData)
                .frame(width: ReferencePickerConstants.Row.tileWidth, height: ReferencePickerConstants.Row.tileHeight)
                .clipShape(.rect(cornerRadius: AppDimensions.chipCornerRadius))
            Button {
                viewModel.removeReferenceImage(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(AppColors.bodyText)
                    .frame(width: ReferencePickerConstants.Row.removeButtonSize,
                           height: ReferencePickerConstants.Row.removeButtonSize)
                    .background(AppColors.cardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(ReferencePickerConstants.Row.removeButtonInset)
            .accessibilityLabel("Remove reference photo \(index + 1)")
        }
    }

    @ViewBuilder
    private func thumbnailImage(_ imageData: Data) -> some View {
        if let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            AppColors.circularButtonBackground
        }
    }
}

// MARK: - Preview

#Preview {
    ReferenceImagesView(viewModel: OccasionInputViewModel())
        .padding(AppDimensions.screenHorizontalPadding)
        .modelContainer(for: [OutfitLook.self, GarmentItem.self], inMemory: true)
}
