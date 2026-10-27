//
//  SkinScanGuideView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import SwiftUI

/// Visual guidance view that presents essential Do(s) and Don't(s)
/// before capturing facial photo for personal color analysis (C5-81).
struct SkinScanGuideView: View {

    // MARK: - Dependencies

    @Bindable var viewModel: SkinScanViewModel
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
                        instructionHeader

                        doDontSection

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 8)
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
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Instruction Header

    private var instructionHeader: some View {
        VStack(spacing: 8) {
            Text("Skin Color Scan")
                .font(AppTypography.screenHeader)
                .foregroundStyle(AppColors.espressoTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Follow these visual guidelines to ensure optimal lighting and facial positioning for accurate color season analysis.")
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Do(s) & Don't(s) Grid Section

    private var doDontSection: some View {
        VStack(spacing: 16) {
            // Column Headers
            HStack {
                Text("Do(s)")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)

                Text("Don't(s)")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 4)

            // Pair 1: Bare Face vs Makeup
            HStack(alignment: .top, spacing: 16) {
                GuideDoDontCard(
                    image: Image(systemName: "face.smiling"),
                    label: "Bare Face Only\nNo filters or products",
                    isDo: true
                )

                GuideDoDontCard(
                    image: Image(systemName: "paintbrush.fill"),
                    label: "Wearing Makeup\nAvoid foundation & blush",
                    isDo: false
                )
            }

            Divider()
                .padding(.vertical, 4)

            // Pair 2: Natural Daylight vs Artificial / Yellow Lighting
            HStack(alignment: .top, spacing: 16) {
                GuideDoDontCard(
                    image: Image(systemName: "sun.max.fill"),
                    label: "Natural Daylight\nFace toward a window",
                    isDo: true
                )

                GuideDoDontCard(
                    image: Image(systemName: "lightbulb.fill"),
                    label: "Artificial Lighting\nAvoid harsh yellow light",
                    isDo: false
                )
            }

            Divider()
                .padding(.vertical, 4)

            // Pair 3: Direct Head Angle vs Tilted Angle
            HStack(alignment: .top, spacing: 16) {
                GuideDoDontCard(
                    image: Image(systemName: "person.fill.viewfinder"),
                    label: "Face Camera Directly\nCentered & upright posture",
                    isDo: true
                )

                GuideDoDontCard(
                    image: Image(systemName: "person.crop.circle.badge.exclamationmark"),
                    label: "Tilt or Angle Head\nAvoid shadows & tilt",
                    isDo: false
                )
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            PrimaryPillButton(title: "Let's Get Started") {
                viewModel.currentStep = .camera
                viewModel.startCamera()
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AppColors.cardBackground)
    }
}

// MARK: - Preview

#Preview {
    SkinScanGuideView(viewModel: SkinScanViewModel())
}
