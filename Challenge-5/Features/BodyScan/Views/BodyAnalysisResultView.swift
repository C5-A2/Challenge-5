//
//  BodyAnalysisResultView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Comprehensive Body Analysis Result view (C5-95).
///
/// Presents:
/// 1. Captured front body photograph with overlaid measurement contour lines (Shoulders, Bust, Waist, Hip).
/// 2. Primary Body Type badge and proportion ratio chips (Hourglass, Pear, Rectangle, Inverted Triangle, Apple).
/// 3. Vertical Torso Balance illustration with Torso-to-Height Ratio (THR) visual gauge.
/// 4. Actionable styling principles (Act) for silhouette balancing.
/// 5. Bottom action bar for saving results to profile and completing the scanning flow.
struct BodyAnalysisResultView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: BodyScanViewModel
    var onComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingFineTune: Bool = false

    // MARK: - Computed Properties

    private var activeBodyType: BodyType {
        viewModel.classifiedBodyType ?? .hourglass
    }

    private var activeTorsoBalance: TorsoBalance {
        viewModel.classifiedTorsoBalance ?? .balanced
    }

    private var shoulderCm: Double {
        viewModel.shoulderWidthCm ?? round((viewModel.heightCm * 0.235) * 10) / 10
    }

    private var bustCm: Double {
        viewModel.bustCircumferenceCm ?? round((viewModel.heightCm * 0.53) * 10) / 10
    }

    private var waistCm: Double {
        viewModel.waistCircumferenceCm ?? round((viewModel.heightCm * 0.41) * 10) / 10
    }

    private var hipCm: Double {
        viewModel.hipCircumferenceCm ?? round((viewModel.heightCm * 0.56) * 10) / 10
    }

    private var thrRatio: Double {
        viewModel.computedTorsoToHeightRatio ?? 31.5
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
                        bodyContourPosterCard

                        measuredDimensionsSummaryCard

                        torsoProportionCard

                        bodyTypeCard

                        torsoBalanceCard

                        stylingPrincipleCard

                        fineTuneDisclosureSection

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
                viewModel.currentStep = .metricsInput
            }

            Spacer()

            Text("Body Type Result")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            Button {
                viewModel.retakeFrontPhoto()
            } label: {
                Text("Retake")
                    .font(AppTypography.caption.weight(.medium))
                    .foregroundStyle(AppColors.espressoTitle)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppColors.circularButtonBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - 1. Body Contour Poster Card

    private var bodyContourPosterCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Color.black.opacity(0.04)

                #if canImport(UIKit)
                if let frontImg = viewModel.frontImage ?? (viewModel.frontImageData != nil ? UIImage(data: viewModel.frontImageData!) : nil) {
                    Image(uiImage: frontImg)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 380)
                        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius - 4))
                } else {
                    fallbackMannequinSilhouette
                }
                #else
                fallbackMannequinSilhouette
                #endif

                // Measurement contour line overlay
                measurementContourOverlay
            }
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius - 4))
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius - 4)
                    .stroke(AppColors.subtleBorder, lineWidth: 1)
            )

            // Explanatory footnote
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.primaryBlue)

                Text("Contour lines calibrated from Apple Vision 2D pose landmarks")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)
            }
            .padding(.top, 4)
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

    // MARK: - Measurement Contour Overlay

    private var measurementContourOverlay: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            // Landmark levels automatically extracted by Apple Vision Framework
            let shoulderY = h * (viewModel.detectedShoulderY ?? 0.22)
            let bustY = h * (viewModel.detectedBustY ?? 0.35)
            let waistY = h * (viewModel.detectedWaistY ?? 0.49)
            let hipY = h * (viewModel.detectedHipY ?? 0.63)

            ZStack {
                // 1. Shoulder Contour Line
                contourGuideRow(
                    title: "Shoulder",
                    value: String(format: "%.1f cm", shoulderCm),
                    color: Color(hex: "#009688"),
                    y: shoulderY,
                    width: w,
                    badgeOnLeft: false
                )

                // 2. Bust Contour Line
                contourGuideRow(
                    title: "Bust",
                    value: String(format: "%.1f cm", bustCm),
                    color: Color(hex: "#2196F3"),
                    y: bustY,
                    width: w,
                    badgeOnLeft: true
                )

                // 3. Waist Contour Line
                contourGuideRow(
                    title: "Waist",
                    value: String(format: "%.1f cm", waistCm),
                    color: Color(hex: "#FF9800"),
                    y: waistY,
                    width: w,
                    badgeOnLeft: false
                )

                // 4. Hip Contour Line
                contourGuideRow(
                    title: "Hip",
                    value: String(format: "%.1f cm", hipCm),
                    color: Color(hex: "#9C27B0"),
                    y: hipY,
                    width: w,
                    badgeOnLeft: true
                )
            }
        }
    }

    private func contourGuideRow(
        title: String,
        value: String,
        color: Color,
        y: CGFloat,
        width: CGFloat,
        badgeOnLeft: Bool
    ) -> some View {
        let margin: CGFloat = 16
        let lineStartX = margin + (badgeOnLeft ? 84 : 0)
        let lineEndX = width - margin - (badgeOnLeft ? 0 : 84)

        return ZStack {
            // Horizontal dashed guide line
            Path { path in
                path.move(to: CGPoint(x: lineStartX, y: y))
                path.addLine(to: CGPoint(x: lineEndX, y: y))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .foregroundStyle(color.opacity(0.85))

            // Left Endpoint Dot
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .position(x: lineStartX, y: y)

            // Right Endpoint Dot
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .position(x: lineEndX, y: y)

            // Measurement pill label
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.espressoTitle)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Color.white.opacity(0.92))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
            .position(x: badgeOnLeft ? margin + 38 : width - margin - 38, y: y)
        }
    }

    private var fallbackMannequinSilhouette: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.stand")
                .resizable()
                .scaledToFit()
                .frame(height: 280)
                .foregroundStyle(AppColors.espressoTitle.opacity(0.18))

            Text("Full Body Silhouette")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 2. Body Type Card

    private var bodyTypeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CLASSIFIED BODY SHAPE")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlue)

                    Text(activeBodyType.displayName)
                        .font(AppTypography.screenHeader)
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Spacer()

                bodyTypeIcon(activeBodyType)
                    .frame(width: 44, height: 44)
                    .background(AppColors.primaryBlue.opacity(0.1))
                    .clipShape(Circle())
            }

            Divider()

            // Proportions Summary Chips
            HStack(spacing: 8) {
                ratioMetricChip(label: "Bust/Waist", value: String(format: "%.2f", bustCm / max(1.0, waistCm)))
                ratioMetricChip(label: "Hip/Waist", value: String(format: "%.2f", hipCm / max(1.0, waistCm)))
                ratioMetricChip(label: "Height", value: "\(Int(viewModel.heightCm)) cm")
            }

            Text(activeBodyType.definition)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
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

    private func ratioMetricChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.mutedCaption)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.espressoTitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func bodyTypeIcon(_ type: BodyType) -> some View {
        let iconName: String
        switch type {
        case .hourglass:
            iconName = "hourglass"
        case .pear:
            iconName = "triangle.fill"
        case .rectangle:
            iconName = "rectangle.portrait.fill"
        case .invertedTriangle:
            iconName = "triangle.fill"
        case .apple:
            iconName = "circle.fill"
        }

        return Image(systemName: iconName)
            .font(.system(size: 20))
            .foregroundStyle(AppColors.primaryBlue)
            .rotationEffect(type == .invertedTriangle ? .degrees(180) : .zero)
    }

    // MARK: - 3. Torso Balance Card

    private var torsoBalanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERTICAL PROPORTION")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlue)

                    Text(activeTorsoBalance.rawValue)
                        .font(AppTypography.screenHeader)
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Spacer()

                Text(activeTorsoBalance.thrThresholdDescription)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.primaryBlue.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Torso-to-Height Ratio (THR) visual gauge
            torsoGaugeView

            Text(activeTorsoBalance.definition)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .fixedSize(horizontal: false, vertical: true)
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

    private var torsoGaugeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Torso-to-Height Ratio (THR)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.mutedCaption)

                Spacer()

                Text(String(format: "%.1f%%", thrRatio))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.espressoTitle)
            }

            // Segmented gauge bar: Short (<30%) | Balanced (30-33%) | Long (>33%)
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                // Map THR (range 25% to 38%) to 0...totalWidth
                let clampedTHR = min(38.0, max(25.0, thrRatio))
                let indicatorX = totalWidth * CGFloat((clampedTHR - 25.0) / (38.0 - 25.0))

                ZStack(alignment: .leading) {
                    HStack(spacing: 3) {
                        // Short zone (25% - 30%)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(activeTorsoBalance == .shortTorso ? AppColors.primaryBlue.opacity(0.85) : Color.black.opacity(0.08))
                            .frame(maxWidth: .infinity)

                        // Balanced zone (30% - 33%)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(activeTorsoBalance == .balanced ? AppColors.primaryBlue.opacity(0.85) : Color.black.opacity(0.08))
                            .frame(maxWidth: .infinity)

                        // Long zone (33% - 38%)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(activeTorsoBalance == .longTorso ? AppColors.primaryBlue.opacity(0.85) : Color.black.opacity(0.08))
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 10)

                    // Position cursor dot
                    Circle()
                        .fill(AppColors.espressoTitle)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                        .offset(x: max(0, min(totalWidth - 16, indicatorX - 8)))
                }
            }
            .frame(height: 16)

            // Zone labels
            HStack {
                Text("Short (<30%)")
                    .font(.system(size: 10))
                    .foregroundStyle(activeTorsoBalance == .shortTorso ? AppColors.primaryBlue : AppColors.mutedCaption)

                Spacer()

                Text("Balanced (30-33%)")
                    .font(.system(size: 10, weight: activeTorsoBalance == .balanced ? .bold : .regular))
                    .foregroundStyle(activeTorsoBalance == .balanced ? AppColors.primaryBlue : AppColors.mutedCaption)

                Spacer()

                Text("Long (>33%)")
                    .font(.system(size: 10))
                    .foregroundStyle(activeTorsoBalance == .longTorso ? AppColors.primaryBlue : AppColors.mutedCaption)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 4. Styling Principle Card (Act)

    private var stylingPrincipleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.primaryBlue)

                Text("Styling Direction")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
            }

            VStack(alignment: .leading, spacing: 10) {
                guidanceBulletRow(
                    title: "Silhouette Goal",
                    content: activeBodyType.actPrinciple
                )

                Divider()

                guidanceBulletRow(
                    title: "Waistline Placement",
                    content: activeTorsoBalance.actPrinciple
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

    private func guidanceBulletRow(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.primaryBlue)

            Text(content)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.bodyText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Auto-Detected Measurements Summary Card

    private var measuredDimensionsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.primaryBlue)

                        Text("DIMENSI TUBUH 3D")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.primaryBlue)
                    }

                    Text("Hasil Pemindaian AI")
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text("Ramanujan Ellipse")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#009688"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "#009688").opacity(0.12))
                .clipShape(Capsule())
            }

            Text("Ukuran lingkar dada, pinggang, dan pinggul dihitung otomatis menggunakan rekonstruksi elips 3D dari siluet tampak depan dan samping.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
                .fixedSize(horizontal: false, vertical: true)

            // 4 Grid Dimension Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                dimensionStatCard(
                    title: "Lingkar Dada",
                    subtitle: "Bust Circumference",
                    value: String(format: "%.1f cm", bustCm),
                    color: Color(hex: "#2196F3"),
                    icon: "circle.circle"
                )

                dimensionStatCard(
                    title: "Lingkar Pinggang",
                    subtitle: "Waist Circumference",
                    value: String(format: "%.1f cm", waistCm),
                    color: Color(hex: "#FF9800"),
                    icon: "circle.dotted"
                )

                dimensionStatCard(
                    title: "Lingkar Pinggul",
                    subtitle: "Hip Circumference",
                    value: String(format: "%.1f cm", hipCm),
                    color: Color(hex: "#9C27B0"),
                    icon: "oval.portrait"
                )

                dimensionStatCard(
                    title: "Lebar Bahu",
                    subtitle: "Shoulder Width",
                    value: String(format: "%.1f cm", shoulderCm),
                    color: Color(hex: "#009688"),
                    icon: "arrow.left.and.right"
                )
            }

            // Ratio summary
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Text("Rasio B/W:")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
                    Text(String(format: "%.2f", bustCm / max(1.0, waistCm)))
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppColors.espressoTitle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 6) {
                    Text("Rasio H/W:")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
                    Text(String(format: "%.2f", hipCm / max(1.0, waistCm)))
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppColors.espressoTitle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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

    private func dimensionStatCard(
        title: String,
        subtitle: String,
        value: String,
        color: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Spacer()
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.mutedCaption)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.espressoTitle)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.mutedCaption)
        }
        .padding(12)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.chipCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.chipCornerRadius)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Torso Proportion & Height Percentage Card (Section 6)

    private var torsoProportionCard: some View {
        let torsoPct = viewModel.torsoRatioPercent ?? 58.0
        let lowerPct = viewModel.lowerBodyRatioPercent ?? (100.0 - torsoPct)
        let torsoLen = viewModel.torsoLengthCm ?? round(viewModel.heightCm * 0.58)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PROPORSI TORSO & TINGGI BADAN")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)

                Spacer()

                Text(activeTorsoBalance.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.primaryBlue.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Headline banner from Section 6.2 format:
            // "Torsomu 60.5% dari badanmu (Panjang torso 96.8 cm dari total tinggi 160.0 cm)"
            Text(LocalizedStringKey("Torsomu **\(String(format: "%.1f", torsoPct))%** dari badanmu (Panjang torso **\(String(format: "%.1f", torsoLen)) cm** dari total tinggi **\(Int(viewModel.heightCm)) cm**)"))
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
                .fixedSize(horizontal: false, vertical: true)

            // Split visual proportion bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    let barW = geo.size.width
                    let torsoW = barW * (CGFloat(torsoPct) / 100.0)
                    let lowerW = max(CGFloat(0), barW - torsoW)

                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.primaryBlue)
                            .frame(width: max(CGFloat(10), torsoW))
                            .overlay(
                                Text(String(format: "%.0f%% Torso", torsoPct))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#009688"))
                            .frame(width: max(CGFloat(10), lowerW))
                            .overlay(
                                Text(String(format: "%.0f%% Kaki", lowerPct))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                }
                .frame(height: 26)

                HStack {
                    Text("Torso: \(String(format: "%.1f", torsoLen)) cm")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColors.primaryBlue)

                    Spacer()

                    Text("Kaki & Tubuh Bawah: \(String(format: "%.1f", viewModel.heightCm - torsoLen)) cm")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "#009688"))
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
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    // MARK: - Optional Fine-Tuning Section (C5-96)

    private var fineTuneDisclosureSection: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isShowingFineTune.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.mutedCaption)

                    Text(isShowingFineTune ? "Sembunyikan Penyesuaian Ukuran" : "Sesuaikan Ukuran Manual (Opsional)")
                        .font(AppTypography.caption.weight(.medium))
                        .foregroundStyle(AppColors.espressoTitle)

                    Spacer()

                    Image(systemName: isShowingFineTune ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.mutedCaption)
                }
                .padding(14)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppDimensions.chipCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.chipCornerRadius)
                        .stroke(AppColors.subtleBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if isShowingFineTune {
                EditableMeasurementsCard(viewModel: viewModel)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            PrimaryPillButton(title: "Save to Profile") {
                if let onComplete = onComplete {
                    onComplete()
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
    let vm = BodyScanViewModel()
    vm.classifiedBodyType = .hourglass
    vm.classifiedTorsoBalance = .balanced
    vm.shoulderWidthCm = 39.5
    vm.bustCircumferenceCm = 91.0
    vm.waistCircumferenceCm = 69.5
    vm.hipCircumferenceCm = 96.0
    vm.computedTorsoToHeightRatio = 31.8
    return BodyAnalysisResultView(viewModel: vm)
}
