//
//  ReferenceCameraView.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

import PhotosUI
import SwiftUI

/// Full-screen camera for adding an occasion reference photo.
///
/// - Top right: confirm the captured photo (✓), which adds it to `referenceImages`.
/// - Bottom left: pick a photo from the user's gallery instead.
/// - Bottom center: take the photo.
/// - Bottom right: retake.
@MainActor
struct ReferenceCameraView: View {

    // MARK: - Properties

    @Bindable var viewModel: OccasionInputViewModel
    @State private var galleryItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppDimensions.sectionSpacing) {
            topBar
            cameraFrame
            Spacer(minLength: 0)
            bottomControls
        }
        .padding(.vertical, AppDimensions.elementSpacing)
        .background(Color.black.ignoresSafeArea())
        .task { await viewModel.startReferenceCamera() }
        .onDisappear { viewModel.stopReferenceCamera() }
        .onChange(of: galleryItem) { _, pickedItem in
            guard let pickedItem else { return }
            Task {
                let isAdded = await viewModel.addGalleryReference(pickedItem)
                galleryItem = nil
                if isAdded {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            CircularIconButton(systemName: "xmark") { dismiss() }
                .accessibilityLabel("Close")
            Spacer()
            CircularIconButton(systemName: "checkmark", isFilled: true, isEnabled: viewModel.hasCapturedReference) {
                if viewModel.confirmCapturedReference() {
                    dismiss()
                }
            }
            .accessibilityLabel("Use photo")
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
    }

    private var cameraFrame: some View {
        Color.black
            .aspectRatio(ReferencePickerConstants.Camera.frameAspectRatio, contentMode: .fit)
            .overlay {
                if let capturedImage = viewModel.capturedReferenceImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFill()
                } else if let cameraService = viewModel.referenceCameraService {
                    CameraPreviewView(session: cameraService.session)
                    CameraGridShape(divisions: ReferencePickerConstants.Camera.gridDivisions)
                        .stroke(AppColors.cardBackground.opacity(ReferencePickerConstants.Camera.gridLineOpacity),
                                lineWidth: ReferencePickerConstants.Camera.gridLineWidth)
                }
            }
            .overlay(alignment: .bottom) {
                if let errorMessage = viewModel.referenceCameraErrorMessage {
                    Text(errorMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.cardBackground)
                        .multilineTextAlignment(.center)
                        .padding(AppDimensions.elementSpacing)
                }
            }
            .clipped()
    }

    private var bottomControls: some View {
        HStack {
            galleryButton
                .frame(maxWidth: .infinity, alignment: .leading)
            shutterButton
            CircularIconButton(systemName: "arrow.counterclockwise", isEnabled: viewModel.hasCapturedReference) {
                viewModel.retakeReferencePhoto()
            }
            .accessibilityLabel("Retake")
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
    }

    private var galleryButton: some View {
        PhotosPicker(selection: $galleryItem, matching: .images) {
            Image(systemName: "photo.on.rectangle")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.bodyText)
                .frame(width: ReferencePickerConstants.Camera.galleryButtonSize,
                       height: ReferencePickerConstants.Camera.galleryButtonSize)
                .background(AppColors.circularButtonBackground)
                .clipShape(Circle())
        }
        .accessibilityLabel("Choose from gallery")
    }

    private var shutterButton: some View {
        let isEnabled = viewModel.canCaptureReference && !viewModel.hasCapturedReference
        return Button {
            Task { await viewModel.captureReferencePhoto() }
        } label: {
            Circle()
                .fill(AppColors.cardBackground)
                .frame(width: ReferencePickerConstants.Camera.shutterSize,
                       height: ReferencePickerConstants.Camera.shutterSize)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : ReferencePickerConstants.Camera.disabledControlOpacity)
        .accessibilityLabel("Take photo")
    }
}

/// Lines that split a rect into equal columns and rows (rule of thirds by default).
private struct CameraGridShape: Shape {
    let divisions: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard divisions > 1 else { return path }
        for step in 1..<divisions {
            let fraction = CGFloat(step) / CGFloat(divisions)
            let x = rect.minX + rect.width * fraction
            let y = rect.minY + rect.height * fraction
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

// MARK: - Preview

#Preview {
    ReferenceCameraView(viewModel: OccasionInputViewModel())
}
