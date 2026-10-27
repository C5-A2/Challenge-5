//
//  FaceReviewView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import SwiftUI

/// Photo review and verification screen for facial skin capture (C5-84).
/// Features captured photo presentation, a 3-point validation checklist
/// (Bare Face, Natural Lighting, Direct Angle), Retake, Use Photo, and Discard actions.
struct FaceReviewView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: SkinScanViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        photoCard

                        checklistSection

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                bottomActionBar
            }

            if viewModel.isAnalyzing {
                analyzingOverlay
            }
        }
        .discardConfirmation(
            isPresented: $viewModel.isShowingDiscardDialog,
            title: "Are you sure Discard?",
            message: "Discarding will remove the captured photo and return to the instructions."
        ) {
            viewModel.discardPhoto()
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            CircularIconButton(systemName: "chevron.left") {
                viewModel.isShowingDiscardDialog = true
            }

            Spacer()

            Text("Skin Color Scan")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            // Visual balance spacer matching back button size
            Color.clear
                .frame(width: AppDimensions.circularIconSize, height: AppDimensions.circularIconSize)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Photo Card

    private var photoCard: some View {
        ZStack {
            #if canImport(UIKit)
            if let uiImage = viewModel.capturedFaceImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 380)
                    .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            } else {
                photoPlaceholder
            }
            #else
            photoPlaceholder
            #endif
        }
        .frame(maxWidth: .infinity)
    }

    private var photoPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
            .fill(AppColors.cardBackground)
            .frame(height: 320)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.rectangle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppColors.mutedCaption)
                    Text("No Photo Available")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
                }
            )
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }

    // MARK: - Validation Checklist Section

    private var checklistSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Check:")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)

                Spacer()

                Text("Tap each to confirm")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
            }

            HStack(spacing: 12) {
                // Item 1: Bare Face
                checkBadge(
                    title: "Bare Face",
                    iconName: "face.smiling",
                    isConfirmed: viewModel.isBareFaceConfirmed
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.isBareFaceConfirmed.toggle()
                    }
                }

                // Item 2: Optimal Lighting
                checkBadge(
                    title: "Natural Light",
                    iconName: "sun.max.fill",
                    isConfirmed: viewModel.isLightingConfirmed
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.isLightingConfirmed.toggle()
                    }
                }

                // Item 3: Direct Angle
                checkBadge(
                    title: "Direct Angle",
                    iconName: "person.fill.viewfinder",
                    isConfirmed: viewModel.isDirectAngleConfirmed
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.isDirectAngleConfirmed.toggle()
                    }
                }
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func checkBadge(
        title: String,
        iconName: String,
        isConfirmed: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: iconName)
                        .font(.system(size: 26))
                        .foregroundStyle(isConfirmed ? AppColors.espressoTitle : AppColors.mutedCaption)
                        .frame(width: 44, height: 44)

                    Image(systemName: isConfirmed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isConfirmed ? .green : .red)
                        .offset(x: 4, y: -4)
                }

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.bodyText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isConfirmed ? Color.green.opacity(0.08) : Color.black.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.chipCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.chipCornerRadius)
                    .stroke(isConfirmed ? Color.green.opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                Button {
                    viewModel.retakePhoto()
                } label: {
                    Text("Retake")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(AppColors.bodyText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.analyzeSkinTone()
                    }
                } label: {
                    Text("Use Photo")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.canProceedToResult ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.4))
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.canProceedToResult || viewModel.isAnalyzing)
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AppColors.cardBackground)
    }

    // MARK: - Analyzing Loading Overlay

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text(viewModel.analysisProgressText.isEmpty ? "Analyzing skin tone..." : viewModel.analysisProgressText)
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(Color(hex: "#2C1E18").opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 16)
        }
    }
}

// MARK: - Preview

#Preview {
    let vm = SkinScanViewModel()
    vm.isBareFaceConfirmed = true
    vm.isLightingConfirmed = true
    vm.isDirectAngleConfirmed = true
    return FaceReviewView(viewModel: vm)
}
