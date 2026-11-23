//
//  SkinScanGuideView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Visual preparation view before capturing facial photo for personal color analysis (C5-81).
struct SkinScanGuideView: View {

    // MARK: - Dependencies

    @Bindable var viewModel: SkinScanViewModel
    var showsBackButton: Bool? = nil
    var onBack: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    // MARK: - State & Environment

    @Query private var userProfiles: [UserProfile]
    @Environment(\.dismiss) private var dismiss

    private var hasExistingData: Bool {
        userProfiles.first?.colorSeason != nil
    }

    private var shouldShowBackButton: Bool {
        showsBackButton ?? !hasExistingData
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.cardBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Sheet Drag Indicator
                SheetDragHandle()
                    .padding(.bottom, 6)

                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        illustrationCard
                            .padding(.top, 16)

                        Text("For the most accurate results, take a front-facing photo with a bare face, no accessories, hair tied back, natural daylight, and a plain neutral background.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.bodyText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2.5)
                            .padding(.horizontal, 8)

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                }

                bottomActionBar
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Left: Back (<) Button — shown only when no existing data (first time)
            if shouldShowBackButton {
                CircularIconButton(systemName: "chevron.left") {
                    if let onBack = onBack {
                        onBack()
                    } else if let onDismiss = onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }
                .accessibilityLabel("Back")
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Skin Color Scan")
                .font(.system(size: 17, weight: .bold).width(.expanded))
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            // Right: Close (X) Button
            CircularIconButton(systemName: "xmark") {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.vertical, 8)
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            PrimaryPillButton(title: "Take Photo") {
                viewModel.currentStep = .camera
                viewModel.startCamera()
            }
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    // MARK: - Center Illustration Card

    private var illustrationCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.07), radius: 16, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )

            Image("skinsvg")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .padding(36)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    SkinScanGuideView(viewModel: SkinScanViewModel())
}
