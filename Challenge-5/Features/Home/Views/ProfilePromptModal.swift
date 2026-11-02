//
//  ProfilePromptModal.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 02/11/26.
//

import SwiftUI
import SwiftData

/// "Set Up Your Profile" modal prompt (C5-98).
///
/// Educates the user on personal color analysis, 3D body morphotype scanning,
/// and accurate body measurements, prompting them to launch the profiling flow.
struct ProfilePromptModal: View {

    // MARK: - Dependencies & Callbacks

    var onStartProfiling: () -> Void
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header with Close Button
                HStack {
                    Spacer()

                    CircularIconButton(systemName: "xmark") {
                        if let onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Emblem Icon Badge
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryBlue.opacity(0.12))
                                .frame(width: 80, height: 80)

                            Image(systemName: "sparkles")
                                .font(.system(size: 36))
                                .foregroundStyle(AppColors.primaryBlue)
                        }
                        .padding(.top, 12)

                        // Title & Subtitle
                        VStack(spacing: 8) {
                            Text("Set Up Your Profile")
                                .font(AppTypography.screenHeader)
                                .foregroundStyle(AppColors.espressoTitle)
                                .multilineTextAlignment(.center)

                            Text("Lengkapi analisis personal color dan bentuk tubuhmu untuk mendapatkan kurasi rekomendasi gaya busana yang paling presisi.")
                                .font(AppTypography.bodyRegular)
                                .foregroundStyle(AppColors.mutedCaption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }

                        // Feature Highlights
                        VStack(spacing: 14) {
                            featureRow(
                                icon: "paintpalette.fill",
                                color: Color(hex: "#FF7043"),
                                title: "Personal Color Analysis",
                                subtitle: "Menemukan palet warna busana yang harmonis dengan skin undertone wajahmu."
                            )

                            featureRow(
                                icon: "figure.stand",
                                color: AppColors.primaryBlue,
                                title: "3D Body Shape Scan",
                                subtitle: "Mendeteksi klasifikasi bentuk tubuh dan proporsi torso vertikal hanya dari 2 foto."
                            )

                            featureRow(
                                icon: "ruler.fill",
                                color: Color(hex: "#009688"),
                                title: "Dimensi Lingkar Presisi",
                                subtitle: "Rekonstruksi lingkar dada, pinggang, dan pinggul menggunakan aproksimasi elips 3D."
                            )
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                }

                // Bottom Action Bar
                VStack(spacing: 12) {
                    Divider()

                    PrimaryPillButton(title: "Let's Get Started") {
                        onStartProfiling()
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)

                    Button {
                        if let onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("Nanti Saja")
                            .font(AppTypography.caption.weight(.medium))
                            .foregroundStyle(AppColors.mutedCaption)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }
                .background(AppColors.cardBackground)
            }
        }
    }

    // MARK: - Feature Highlight Row

    private func featureRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.bodyText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ProfilePromptModal(onStartProfiling: {})
}
