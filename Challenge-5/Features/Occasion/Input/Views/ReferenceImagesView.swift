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
    var isEditable: Bool = true
    /// Saved looks (bookmarked), newest first, same order as the Library.
    @Query(filter: #Predicate<OutfitLook> { $0.isBookmarked },
           sort: [SortDescriptor(\OutfitLook.savedAt, order: .reverse)])
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
                preselectedLookIds: viewModel.selectedSavedLookIDs,
                onSelectReferences: { pickedLooks in viewModel.updateSavedReferenceLooks(pickedLooks) },
                onDismiss: { viewModel.isShowingReferenceLibrary = false }
            )
        }
    }

    // MARK: - Subviews

    /// "Reference (Optional)" with the photo counter or camera icon.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Reference")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
            Text("(Optional)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
            Spacer()
            if isEditable {
                Text("\(viewModel.referenceImages.count)/\(ReferencePickerConstants.maximumReferenceCount)")
                    .font(AppTypography.caption)
                    .foregroundStyle(viewModel.canAddMoreReferences ? AppColors.mutedCaption : AppColors.espressoTitle)
            } else {
                Image(systemName: "camera")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.mutedCaption)
            }
        }
        // Same inset as the Dresscode and "I want to look more" headers.
        .padding(.leading, ReferencePickerConstants.Row.headerInset)
        .padding(.top, ReferencePickerConstants.Row.headerInset)
    }

    private var referenceRow: some View {
        Group {
            if !isEditable && viewModel.referenceImages.isEmpty {
                HStack {
                    Text("No reference photos attached")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(height: 52)
                .background(AppColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.inputCornerRadius)
                        .strokeBorder(AppColors.inputBorder, lineWidth: 1)
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: AppDimensions.elementSpacing) {
                            if isEditable && viewModel.canAddMoreReferences {
                                addReferenceTile
                            }
                            ForEach(Array(viewModel.referenceImages.enumerated()), id: \.offset) { index, imageData in
                                referenceThumbnail(imageData, at: index)
                            }
                            if isEditable && viewModel.isLoadingReferencePhotos {
                                ProgressView()
                                    .frame(width: ReferencePickerConstants.Row.tileWidth,
                                           height: ReferencePickerConstants.Row.tileHeight)
                            }
                        }
                    }

                    // Developer Debug Banner showing active VLM extracted context for Qwen 2.5
                    if !viewModel.referenceImages.isEmpty && (!viewModel.referenceImageKeywords.isEmpty || viewModel.isAnalyzingReferencePhotos) {
                        debugContextBanner
                    }
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
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                thumbnailImage(imageData)
                    .frame(width: ReferencePickerConstants.Row.tileWidth, height: ReferencePickerConstants.Row.tileHeight)
                    .clipShape(.rect(cornerRadius: AppDimensions.chipCornerRadius))
                if isEditable {
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

            // Developer debug keywords at the bottom of the reference image
            keywordsBottomView(for: index)
        }
        .frame(width: ReferencePickerConstants.Row.tileWidth)
    }

    @ViewBuilder
    private func keywordsBottomView(for index: Int) -> some View {
        let keywords = viewModel.extractedKeywords(for: index)
        if !keywords.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppColors.primaryBlue)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .frame(maxWidth: ReferencePickerConstants.Row.tileWidth, alignment: .leading)
                }
            }
        } else if viewModel.isAnalyzingReferencePhotos {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Analyzing…")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(AppColors.mutedCaption)
            }
            .frame(width: ReferencePickerConstants.Row.tileWidth, alignment: .leading)
        }
    }

    @ViewBuilder
    private var debugContextBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
                Text("VLM CONTEXT FOR QWEN 2.5 (DEBUG)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
                Spacer()
                Text("Full Prompt Text")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.primaryBlue.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(Capsule())
            }

            if let fullContext = viewModel.fullExtractedVLMContext, !fullContext.isEmpty {
                Text(fullContext)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.espressoTitle)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            } else if viewModel.isAnalyzingReferencePhotos {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Extracting full visual context via VLM / Vision engine…")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(AppColors.mutedCaption)
                }
                .padding(.vertical, 4)
            } else {
                let allKeywords = (0..<viewModel.referenceImages.count)
                    .flatMap { viewModel.extractedKeywords(for: $0) }
                if !allKeywords.isEmpty {
                    Text(allKeywords.joined(separator: " • "))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.espressoTitle)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.primaryBlue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(AppColors.primaryBlue.opacity(0.2), lineWidth: 1)
        )
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
        .modelContainer(SavedLookSampleData.makeContainer(savedLookCount: 4))
}
