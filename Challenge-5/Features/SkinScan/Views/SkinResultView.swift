//
//  SkinResultView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Personal Color Season result screen (C5-85).
///
/// Presents:
/// 1. Color Season Wheel poster with the user's face in the center surrounded by chromatic palette wedges.
/// 2. Foundation / neutral skin tone swatches.
/// 3. Personalized skin undertone explanation.
/// 4. Curated Pantone TCX swatches list with hex values.
/// 5. Color styling rules and colors to avoid.
/// 6. Action buttons for "Retake" and "Next" (proceeding to Body Scan).
struct SkinResultView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: SkinScanViewModel
    var onNext: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    private var activeSeason: ColorSeason {
        viewModel.selectedColorSeason ?? viewModel.predictedColorSeason ?? .trueSpring
    }

    private var undertoneTitle: String {
        switch activeSeason {
        case .brightSpring, .trueSpring, .lightSpring:
            return "Warm Spring Undertone"
        case .lightSummer, .trueSummer, .softSummer:
            return "Cool Summer Undertone"
        case .softAutumn, .trueAutumn, .darkAutumn:
            return "Warm Autumn Undertone"
        case .darkWinter, .trueWinter, .brightWinter:
            return "Cool Winter Undertone"
        }
    }

    private var undertoneExplanation: String {
        switch activeSeason {
        case .brightSpring, .trueSpring, .lightSpring:
            return "You have a permanent, underlying layer of golden, yellow, or peach hues beneath the surface of your skin."
        case .lightSummer, .trueSummer, .softSummer:
            return "You have a permanent, underlying layer of cool blue, rose, or gentle pink hues beneath the surface of your skin."
        case .softAutumn, .trueAutumn, .darkAutumn:
            return "You have a permanent, underlying layer of rich warm bronze, olive, or golden undertones beneath the surface of your skin."
        case .darkWinter, .trueWinter, .brightWinter:
            return "You have a permanent, underlying layer of cool blue, porcelain, or vivid cool undertones beneath the surface of your skin."
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppDimensions.sectionSpacing) {
                        resultPosterCard

                        undertoneExplanationCard

                        curatedSwatchesCard

                        stylingGuidanceCard

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
            CircularIconButton(systemName: "chevron.left") {
                viewModel.currentStep = .review
            }

            Spacer()

            Text("Analyze Result")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            Button {
                viewModel.retakePhoto()
            } label: {
                Text("Retake")
                    .font(AppTypography.caption.weight(.medium))
                    .foregroundStyle(AppColors.espressoTitle)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppColors.circularButtonBackground)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Result Poster Card

    private var resultPosterCard: some View {
        VStack(spacing: 20) {
            // Best Colors Badge
            Text("BEST COLORS FOR YOUR SEASON")
                .font(AppTypography.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(AppColors.espressoTitle.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "#F5ECE5"))
                .clipShape(Capsule())

            // Color Season Wheel with Face in Center
            ColorSeasonWheelView(
                selectedSeasonName: activeSeason.rawValue,
                wheelDiameter: 230,
                hexColors: activeSeason.wheelHexColors,
                faceImage: viewModel.capturedFaceImage
            )

            // Subtitle Label
            Text(undertoneTitle)
                .font(AppTypography.sfProSemiboldExtended(size: 16))
                .foregroundStyle(AppColors.espressoTitle)
                .padding(.top, 4)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, AppDimensions.cardInternalPadding)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
    }

    // MARK: - Undertone Explanation Card

    private var undertoneExplanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#C68B59"))

                Text("Skin Undertone Analysis")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
            }

            Text(undertoneExplanation)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .lineSpacing(3)

            Divider()
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Seasonal Essence")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.espressoTitle)

                Text(activeSeason.act)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
                    .lineSpacing(2)
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    // MARK: - Curated Swatches Card

    private var curatedSwatchesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Curated Palette Swatches")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)

                Spacer()

                Text("Pantone TCX")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
            }

            VStack(spacing: 10) {
                ForEach(activeSeason.sampleSwatches) { swatch in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: swatch.hex))
                            .frame(width: 38, height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(swatch.name)
                                .font(AppTypography.bodyRegular.weight(.medium))
                                .foregroundStyle(AppColors.espressoTitle)

                            Text(swatch.pantoneCode)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.mutedCaption)
                        }

                        Spacer()

                        Text(swatch.hex.uppercased())
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppColors.mutedCaption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    // MARK: - Styling Guidance Card

    private var stylingGuidanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Wardrobe Color Harmonization")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)

            // Combination Rules
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                        .font(.system(size: 14))

                    Text("How to Combine")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Text(activeSeason.colorCombinationRules)
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.bodyText)
                    .lineSpacing(2)
            }

            Divider()
                .padding(.vertical, 2)

            // Colors to Avoid
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.orange)
                        .font(.system(size: 14))

                    Text("Colors to Avoid")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Text(activeSeason.colorsToAvoid)
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.bodyText)
                    .lineSpacing(2)
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            PrimaryPillButton(title: "Next") {
                if let onNext = onNext {
                    onNext()
                } else {
                    dismiss()
                }
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AppColors.cardBackground)
    }
}

// MARK: - Preview

#Preview {
    SkinResultView(viewModel: {
        let vm = SkinScanViewModel()
        vm.predictedColorSeason = .trueSpring
        vm.selectedColorSeason = .trueSpring
        return vm
    }())
}
