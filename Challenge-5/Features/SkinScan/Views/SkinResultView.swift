//
//  SkinResultView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import SwiftData
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
    @Environment(\.modelContext) private var modelContext

    // MARK: - Computed Properties

    private var activeSeason: ColorSeason {
        viewModel.selectedColorSeason ?? viewModel.predictedColorSeason ?? .trueSpring
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
        VStack(spacing: 16) {
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

            // Season Title (exact match with ColorSeason ruleset)
            Text(activeSeason.rawValue)
                .font(.system(size: 21, weight: .bold).width(.expanded))
                .foregroundStyle(AppColors.espressoTitle)
                .padding(.top, 4)

            // Season Definition (exact match with ColorSeason.definition ruleset)
            colorSeasonHighlightedDescription(for: activeSeason)
                .font(.system(size: 13.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
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

                Text("Seasonal Essence & Tonal Aspects")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
            }

            Text(activeSeason.act)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .lineSpacing(3)

            Divider()
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Tonal Coordinates")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.espressoTitle)

                Text("• Hue: \(activeSeason.hue)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)

                Text("• Value: \(activeSeason.value)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)

                Text("• Chroma: \(activeSeason.chroma)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
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

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                    ForEach(activeSeason.colorsToAvoidPalette) { swatch in
                        Circle()
                            .fill(Color(hex: swatch.hex))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(AppColors.subtleBorder, lineWidth: 1))
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 1)
                            )
                            .accessibilityLabel(swatch.name)
                    }
                }
                .padding(.top, 4)
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
                _ = viewModel.saveToProfile(in: modelContext)
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

    private func colorSeasonHighlightedDescription(for season: ColorSeason) -> Text {
        switch season {
        case .brightSpring:
            return Text.highlighted([
                ("You have a ", false),
                ("bright, clear complexion", true),
                (" with ", false),
                ("neutral-warm (golden or peach) undertones", true),
                (" and ", false),
                ("high natural contrast", true),
                (" across your face. Because your natural coloring is ", false),
                ("vivid with zero greyness", true),
                (", so ", false),
                ("intensely saturated and clear hues", true),
                (" such as vivid coral, sunny yellow, bright turquoise, apple green, and lively pink mirror your natural luminosity without muting you.", false)
            ])
        case .trueSpring:
            return Text.highlighted([
                ("You have ", false),
                ("purely warm (golden or honey) undertones", true),
                (" with ", false),
                ("medium contrast", true),
                (" and a ", false),
                ("fresh, sunlit clarity", true),
                (". Since your features have ", false),
                ("zero coolness", true),
                (", ", false),
                ("rich, yellow-based, so vibrant shades", true),
                (" such as warm coral, tomato red, golden yellow, clear turquoise, apple green, and warm camel harmonize with your natural warmth and keep you glowing.", false)
            ])
        case .lightSpring:
            return Text.highlighted([
                ("You have ", false),
                ("light, delicate features", true),
                (" with ", false),
                ("low contrast", true),
                (" and ", false),
                ("neutral-warm (golden or peach) undertones", true),
                (". Because your overall coloring is ", false),
                ("airy without heavy depth", true),
                (", a ", false),
                ("light warm pastels and soft neutrals", true),
                (" such as peach, soft coral, mint green, cherry blossom pink, warm ivory, and light camel flatter your gentleness without overpowering you.", false)
            ])
        case .lightSummer:
            return Text.highlighted([
                ("You have ", false),
                ("very light, delicate features", true),
                (" with ", false),
                ("low contrast", true),
                (" and ", false),
                ("neutral-cool (blue or pink) undertones", true),
                (". Because your coloring is ", false),
                ("pale and airy", true),
                (", a ", false),
                ("fresh, blue-based pastels and soft cool neutrals", true),
                (" such as powder blue, soft lavender, cool blush pink, pale mint, periwinkle, and dove grey keep your look balanced and luminous.", false)
            ])
        case .trueSummer:
            return Text.highlighted([
                ("You have ", false),
                ("purely cool (blue or rose) undertones", true),
                (" with ", false),
                ("medium contrast", true),
                (" and a ", false),
                ("soft, gently blended appearance", true),
                (". Since your features contain ", false),
                ("no warmth", true),
                (", a ", false),
                ("calm, cool, medium-depth shades", true),
                (" such as raspberry, cool teal, soft rose, dusty orchid, misty slate blue, and cool navy echo your natural coolness without looking harsh.", false)
            ])
        case .softSummer:
            return Text.highlighted([
                ("You have ", false),
                ("muted, softly blended features", true),
                (" with ", false),
                ("low-to-medium contrast", true),
                (" and ", false),
                ("neutral-cool undertones", true),
                (". Because your coloring has a ", false),
                ("gentle, smoky quality", true),
                (", ", false),
                ("desaturated, so grey-tinted cool tones", true),
                (" such as dusty rose, mauve, sage green, muted teal, slate blue, and cocoa taupe enhance your understated harmony without overwhelming you.", false)
            ])
        case .softAutumn:
            return Text.highlighted([
                ("You have ", false),
                ("muted, understated features", true),
                (" with ", false),
                ("low-to-medium contrast", true),
                (" and ", false),
                ("neutral-warm undertones", true),
                (" that blend smoothly together. Because your coloring is ", false),
                ("soft rather than stark", true),
                (", so ", false),
                ("earthy, desaturated, low-contrast shades", true),
                (" such as sage green, warm taupe, dusty rose, muted terracotta, camel, and soft olive complement your gentle warmth naturally.", false)
            ])
        case .trueAutumn:
            return Text.highlighted([
                ("You have ", false),
                ("purely warm (golden or bronze) undertones", true),
                (" with ", false),
                ("medium contrast", true),
                (" and a ", false),
                ("rich, earthy softness", true),
                (". Since your features radiate ", false),
                ("warm, sunlit depth", true),
                (" and ", false),
                ("rich autumn-forest hues", true),
                (" such as terracotta, rust, mustard yellow, warm olive green, caramel, and burnt sienna bring out your natural richness and warmth.", false)
            ])
        case .darkAutumn:
            return Text.highlighted([
                ("You have a ", false),
                ("deep, rich complexion", true),
                (" with ", false),
                ("high contrast", true),
                (" and ", false),
                ("neutral-warm (golden or olive) undertones", true),
                (". Because ", false),
                ("depth is your most prominent trait", true),
                (", then ", false),
                ("rich, saturated, and heavier warm shades", true),
                (" such as deep olive, espresso brown, burnt orange, warm burgundy, deep teal, and rich gold balance your intensity without washing you out.", false)
            ])
        case .darkWinter:
            return Text.highlighted([
                ("You have ", false),
                ("prominent dark features", true),
                (" with ", false),
                ("high contrast", true),
                (" and ", false),
                ("neutral-cool undertones", true),
                (". Because your coloring combines ", false),
                ("deep intensity with a hint of frost", true),
                (", rich, a ", false),
                ("cool-leaning dark shades and crisp accents", true),
                (" such as deep pine green, true burgundy, deep plum, midnight blue, charcoal, and crisp white match your natural depth and contrast.", false)
            ])
        case .trueWinter:
            return Text.highlighted([
                ("You have ", false),
                ("purely cool (icy, blue-based) undertones", true),
                (" with ", false),
                ("high contrast", true),
                (" and ", false),
                ("sharp, dramatic clarity", true),
                (". Since your features have ", false),
                ("zero warmth or softness", true),
                (", bold, crisp, so ", false),
                ("pure cool tones", true),
                (" such as royal blue, emerald green, ruby red, sharp fuchsia, true black, and icicle white highlight your cool brilliance effortlessly.", false)
            ])
        case .brightWinter:
            return Text.highlighted([
                ("You have ", false),
                ("ultra-clear, bright features", true),
                (" with ", false),
                ("very high contrast", true),
                (" and ", false),
                ("neutral-cool undertones", true),
                (". Because your coloring is ", false),
                ("crisp and high-energy with zero muddiness", true),
                (", so ", false),
                ("electric and hyper-saturated shades", true),
                (" such as electric blue, vivid magenta, bright fuchsia, clear turquoise, optic white, and pure black match your natural intensity.", false)
            ])
        }
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
    .modelContainer(for: [UserProfile.self], inMemory: true)
}
