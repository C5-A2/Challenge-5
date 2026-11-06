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
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Sheet Drag Indicator
                Capsule()
                    .fill(Color(hex: "#D6D1CA"))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                // Top Header Bar (Close X | Permission | Checkmark)
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Intro Description
                        Text("Before we get started, let’s gather some details about you to personalize your color analysis, body type, and outfit recommendations.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "#1C1C1E"))
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
            Button {
                if let onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#EFEFF0"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Permission")
                .font(.system(size: 17, weight: .bold).width(.expanded))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Spacer()

            // Right: Confirm (Checkmark) Button
            Button {
                onStartProfiling()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.vertical, 8)
    }

    // MARK: - Steps Section

    private var stepsSection: some View {
        VStack(spacing: 16) {
            Text("Steps")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "#1C1C1E"))

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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))
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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))
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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))
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
                    .foregroundStyle(Color(hex: "#1C1C1E"))

                Text("Your privacy matters")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            Text("Your photos and personal information will be used to support your analysis and personalize your experience. Please review our Privacy Policy to learn how your data is stored and managed.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(hex: "#2C2C2E"))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ProfilePromptModal(onStartProfiling: {})
}
