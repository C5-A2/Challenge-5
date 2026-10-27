//
//  SideBodyGuideView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI

/// Visual guidance view presenting essential Do(s) and Don't(s)
/// before capturing side-body photo for posture and body profile analysis (C5-87).
struct SideBodyGuideView: View {

    // MARK: - Dependencies

    @Bindable var viewModel: BodyScanViewModel
    var onDismiss: (() -> Void)? = nil

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppDimensions.sectionSpacing) {
                        doDontSection

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }

                bottomActionBar
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            CircularIconButton(systemName: "xmark") {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }

            Spacer()

            Text("Body Type Scan (Side)")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            // Balance circular icon button on the left
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Do(s) & Don't(s) Section

    private var doDontSection: some View {
        VStack(spacing: 16) {
            // Column Headers
            HStack {
                Text("Do(s)")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(Color(hex: "#34C759"))
                    .frame(maxWidth: .infinity)

                Text("Don't(s)")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(Color(hex: "#FF3B30"))
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 4)

            // Pair 1: Stand sideways directly vs tilted angle
            HStack(alignment: .top, spacing: 16) {
                GuideDoDontCard(
                    image: guideImage(named: "side_body_angle_do", fallbackSystemName: "figure.walk.arrival"),
                    label: "Face the Camera Sideways",
                    isDo: true
                )

                GuideDoDontCard(
                    image: guideImage(named: "side_body_angle_dont", fallbackSystemName: "person.crop.circle.badge.exclamationmark"),
                    label: "Tilt or Angle Your Body",
                    isDo: false
                )
            }

            Divider()
                .padding(.vertical, 4)

            // Pair 2: Upright side posture vs slouched/hunched posture
            HStack(alignment: .top, spacing: 16) {
                GuideDoDontCard(
                    image: guideImage(named: "side_body_posture_do", fallbackSystemName: "figure.stand"),
                    label: "Upright Pose",
                    isDo: true
                )

                GuideDoDontCard(
                    image: guideImage(named: "side_body_posture_dont", fallbackSystemName: "figure.fall"),
                    label: "Relaxed Pose",
                    isDo: false
                )
            }

            Divider()
                .padding(.vertical, 4)

            // Pair 3: Tight clothing against contrast wall vs baggy clothing with clutter
            HStack(alignment: .top, spacing: 16) {
                GuideDoDontCard(
                    image: guideImage(named: "side_body_clothing_do", fallbackSystemName: "tshirt"),
                    label: "Tight Clothing and Infront of Contrast Colored Wall",
                    isDo: true
                )

                GuideDoDontCard(
                    image: guideImage(named: "side_body_clothing_dont", fallbackSystemName: "shippingbox.fill"),
                    label: "Baggy Clothing and Infront of Objects",
                    isDo: false
                )
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            PrimaryPillButton(title: "Take Picture") {
                viewModel.currentStep = .sideCamera
                viewModel.startCamera()
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AppColors.cardBackground)
    }

    // MARK: - Asset Helper

    private func guideImage(named assetName: String, fallbackSystemName: String) -> Image {
        #if canImport(UIKit)
        if UIImage(named: assetName) != nil {
            return Image(assetName)
        }
        #endif
        return Image(systemName: fallbackSystemName)
    }
}

// MARK: - Preview

#Preview {
    SideBodyGuideView(viewModel: BodyScanViewModel())
}
