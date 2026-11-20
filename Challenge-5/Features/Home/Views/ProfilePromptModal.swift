//
//  ProfilePromptModal.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 02/11/26.
//

import SwiftUI
import SwiftData

/// "Permission" onboarding modal prompt (C5-98).
///
/// Presents the 3 profiling steps (Skin Color Scan, Body Type Scan Front, Body Type Scan Side)
/// and privacy notice before launching the profiling flow.
struct ProfilePromptModal: View {

    // MARK: - Dependencies & Callbacks

    var onStartProfiling: () -> Void
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.cardBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Sheet Drag Indicator
                SheetDragHandle()
                    .padding(.bottom, 6)

                // Top Header Bar (Close X | Permission | Checkmark)
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Intro Description
                        Text("Before we get started, let’s gather some details about you to personalize your color analysis, body type, and outfit recommendations.")
                            .font(AppTypography.bodyRegular)
                            .foregroundStyle(AppColors.bodyText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 12)
                            .padding(.top, 14)

                        // Steps Section
                        stepsSection

                        // Privacy Notice Card
                        privacyCard
                            .padding(.top, 4)

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                }
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Left: Close (X) Button
            CircularIconButton(systemName: "xmark") {
                if let onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
            .accessibilityLabel("Close")

            Spacer()

            Text("Permission")
                .font(.system(size: 17, weight: .bold).width(.expanded))
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            // Right: Confirm (Checkmark) Button
            CircularIconButton(systemName: "checkmark", isFilled: true) {
                onStartProfiling()
            }
            .accessibilityLabel("Confirm")
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.vertical, 8)
    }

    // MARK: - Steps Section

    private var stepsSection: some View {
        VStack(spacing: 16) {
            Text("Steps")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.espressoTitle)

            HStack(alignment: .top, spacing: 8) {
                // Step 1: Skin Color Scan
                VStack(spacing: 12) {
                    Image("skinsvg")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 112)
                        .frame(maxWidth: .infinity)
                        .frame(height: 148, alignment: .center)

                    Text("Skin Color Scan")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                // Step 2: Body Type Scan (Front)
                VStack(spacing: 12) {
                    Image("bodyfront")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 144)
                        .frame(maxWidth: .infinity)
                        .frame(height: 148, alignment: .center)

                    Text("Body Type Scan\n(Front)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                // Step 3: Body Type Scan (Side)
                VStack(spacing: 12) {
                    Image("bodyside")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 144)
                        .frame(maxWidth: .infinity)
                        .frame(height: 148, alignment: .center)

                    Text("Body Type Scan\n(Side)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Privacy Card

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.bodyText)

                Text("Your privacy matters")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.espressoTitle)
            }

            Text("Your photos and personal information will be used to support your analysis and personalize your experience. Please review our Privacy Policy to learn how your data is stored and managed.")
                .font(AppTypography.caption1Medium)
                .foregroundStyle(AppColors.secondaryText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ProfilePromptModal(onStartProfiling: {})
}
