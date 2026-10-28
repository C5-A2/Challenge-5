//
//  SideBodyReviewView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Photo review and posture verification screen for side-body capture (C5-89).
/// Features captured side profile presentation, 3-point posture verification checklist
/// (Sideways Angle, Upright Spine, Fitted Clothing), Retake, and Use Photo actions.
struct SideBodyReviewView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: BodyScanViewModel

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
        }
        .discardConfirmation(
            isPresented: $viewModel.isShowingDiscardDialog,
            title: "Are you sure Discard?",
            message: "Discarding will remove the side body photo and return to the guidance instructions."
        ) {
            viewModel.discardSidePhoto()
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            CircularIconButton(systemName: "chevron.left") {
                viewModel.isShowingDiscardDialog = true
            }

            Spacer()

            Text("Body Type Scan (Side)")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            // Balance circular icon button on the left
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
            if let uiImage = viewModel.sideImage {
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
            .frame(height: 340)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk.arrival")
                        .font(.system(size: 64))
                        .foregroundStyle(AppColors.mutedCaption)
                    Text("No Side Photo Captured")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
                }
            )
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }

    // MARK: - Posture Verification Checklist Section

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
                // Item 1: Sideways Angle
                checkBadge(
                    title: "Sideways",
                    iconName: "figure.walk.arrival",
                    isConfirmed: viewModel.isSideAngleConfirmed
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.isSideAngleConfirmed.toggle()
                    }
                }

                // Item 2: Upright Spine
                checkBadge(
                    title: "Upright Spine",
                    iconName: "figure.stand",
                    isConfirmed: viewModel.isSidePostureConfirmed
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.isSidePostureConfirmed.toggle()
                    }
                }

                // Item 3: Fitted Clothing
                checkBadge(
                    title: "Fitted Clothes",
                    iconName: "tshirt",
                    isConfirmed: viewModel.isSideFittedClothingConfirmed
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.isSideFittedClothingConfirmed.toggle()
                    }
                }
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
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
                    .lineLimit(2)
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
                    viewModel.retakeSidePhoto()
                } label: {
                    Text("Retake")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(AppColors.bodyText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }

                Spacer()

                Button {
                    viewModel.confirmSidePhotoAndProceed()
                } label: {
                    Text("Use Photo")
                        .font(AppTypography.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.canConfirmSidePhoto ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.4))
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.canConfirmSidePhoto)
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AppColors.cardBackground)
    }
}

// MARK: - Preview

#Preview {
    let vm = BodyScanViewModel()
    vm.isSideAngleConfirmed = true
    vm.isSidePostureConfirmed = true
    vm.isSideFittedClothingConfirmed = true
    return SideBodyReviewView(viewModel: vm)
}
