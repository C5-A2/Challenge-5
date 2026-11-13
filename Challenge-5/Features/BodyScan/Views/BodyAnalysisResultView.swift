//
//  BodyAnalysisResultView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import SwiftUI
import SwiftData
import Vision
#if canImport(UIKit)
import UIKit
#endif

/// Comprehensive Body Analysis Result view ("Analyze Result" — C5-95).
///
/// Presents:
/// 1. Body Type summary card with the front body photo, Bust / Waist / Hips slice lines & callout labels,
///    classified Body Type title, and highlighted explanation.
/// 2. Editable Measurements card for Bust, Waist, Hips, and Torso (in cm).
/// 3. Torso Proportion & Vertical Balance classification cards.
/// 4. Actionable styling direction card.
struct BodyAnalysisResultView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: BodyScanViewModel
    var onComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedMetric: EditableField?

    @State private var selectedPhotoTab: Int = 0 // 0 = Front View, 1 = Side View
    @State private var showSkeleton: Bool = true
    @State private var showSlices: Bool = true

    @State private var bustText: String = ""
    @State private var waistText: String = ""
    @State private var hipsText: String = ""
    @State private var torsoText: String = ""

    private enum EditableField: Hashable {
        case bust
        case waist
        case hips
        case torso
    }

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

    private var torsoLenCm: Double {
        viewModel.torsoLengthCm ?? round((viewModel.heightCm * 0.315) * 10) / 10
    }

    private var thrRatio: Double {
        viewModel.computedTorsoToHeightRatio ?? 31.5
    }

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

                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // 1. Top Card: Body Photo with Bust/Waist/Hips Overlay + Body Type Classification
                        bodyTypeHeroCard

                        // 2. Editable Measurements Card: Bust, Waist, Hips, Torso
                        measurementsListCard

                        // 3. Torso Classification Cards (kept intact below Body Type & Measurements)
                        torsoProportionCard

                        torsoBalanceCard

                        stylingPrincipleCard

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
        }
        .environment(\.colorScheme, .light)
        .onAppear {
            syncTextFieldsFromViewModel()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedMetric = nil
                }
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(Color.black)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Left: Back (<) Button
            Button {
                viewModel.currentStep = .metricsInput
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#EFEFF0"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Analyze Result")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Spacer()

            // Right: Confirm (Checkmark) Button — Saves to Profile & Completes
            Button {
                focusedMetric = nil
                _ = viewModel.saveToProfile(in: modelContext)
                if let onComplete = onComplete {
                    onComplete()
                } else {
                    dismiss()
                }
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

    // MARK: - 1. Body Type Hero Card (CobaBodyScan Front/Side Photo + Body Shape Title & Description)

    private var bodyTypeHeroCard: some View {
        VStack(spacing: 14) {
            // View Selector (Front View vs Side View — CobaBodyScan style)
            Picker("View", selection: $selectedPhotoTab) {
                Text("Front View").tag(0)
                Text("Side View").tag(1)
            }
            .pickerStyle(.segmented)

            // Photo with Direct Pose & Slice Overlays (Matched 1:1 to rendered Image bounds like CobaBodyScan)
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.04))
                    .frame(height: 360)

                #if canImport(UIKit)
                if selectedPhotoTab == 0 {
                    if let frontImg = viewModel.frontImage ?? (viewModel.frontImageData != nil ? UIImage(data: viewModel.frontImageData!) : nil) {
                        Image(uiImage: frontImg)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                BodyPoseOverlayView(
                                    poseResult: viewModel.frontPoseResult,
                                    chestY: viewModel.detectedBustY,
                                    waistY: viewModel.detectedWaistY,
                                    hipY: viewModel.detectedHipY,
                                    chestBounds: viewModel.frontChestBounds,
                                    waistBounds: viewModel.frontWaistBounds,
                                    hipBounds: viewModel.frontHipBounds,
                                    showSkeleton: showSkeleton,
                                    showSlices: showSlices
                                )
                            )
                    } else {
                        fallbackMannequinSilhouette
                    }
                } else {
                    if let sideImg = viewModel.sideImage ?? (viewModel.sideImageData != nil ? UIImage(data: viewModel.sideImageData!) : nil) {
                        Image(uiImage: sideImg)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                BodyPoseOverlayView(
                                    poseResult: viewModel.sidePoseResult,
                                    chestY: viewModel.detectedSideBustY ?? viewModel.detectedBustY,
                                    waistY: viewModel.detectedSideWaistY ?? viewModel.detectedWaistY,
                                    hipY: viewModel.detectedSideHipY ?? viewModel.detectedHipY,
                                    chestBounds: viewModel.sideChestBounds,
                                    waistBounds: viewModel.sideWaistBounds,
                                    hipBounds: viewModel.sideHipBounds,
                                    showSkeleton: showSkeleton,
                                    showSlices: showSlices
                                )
                            )
                    } else {
                        fallbackMannequinSilhouette
                    }
                }
                #else
                fallbackMannequinSilhouette
                #endif
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )

            // Overlay Toggle Controls (Skeleton & Slice Lines — CobaBodyScan style)
            HStack(spacing: 12) {
                Toggle("Skeleton", isOn: $showSkeleton)
                    .toggleStyle(.button)
                    .font(.caption.bold())
                    .tint(.cyan)

                Toggle("Slice Lines", isOn: $showSlices)
                    .toggleStyle(.button)
                    .font(.caption.bold())
                    .tint(.green)

                Spacer()
            }

            Divider()
                .padding(.vertical, 2)

            // Body Type Title & Simple Highlighted Description
            Text(activeBodyType.displayName)
                .font(.system(size: 21, weight: .bold).width(.expanded))
                .foregroundStyle(AppColors.espressoTitle)

            bodyTypeHighlightedDescription(for: activeBodyType)
                .font(.system(size: 13.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private func bodyTypeHighlightedDescription(for bodyType: BodyType) -> Text {
        switch bodyType {
        case .invertedTriangle:
            return Text.highlighted([
                ("Your ", false),
                ("upper body", true),
                (" is naturally ", false),
                ("wider", true),
                (" than your lower body, with ", false),
                ("broader shoulders", true),
                (" and comparatively ", false),
                ("narrower hips.", true)
            ])
        case .hourglass:
            return Text.highlighted([
                ("Your ", false),
                ("upper and lower body", true),
                (" are naturally ", false),
                ("balanced", true),
                (", with a ", false),
                ("well-defined waistline", true),
                (" between your bust and hips.", false)
            ])
        case .pear:
            return Text.highlighted([
                ("Your ", false),
                ("lower body", true),
                (" is naturally ", false),
                ("wider", true),
                (" than your upper body, with ", false),
                ("fuller hips", true),
                (" and comparatively ", false),
                ("narrower shoulders.", true)
            ])
        case .rectangle:
            return Text.highlighted([
                ("Your ", false),
                ("bust, waist, and hips", true),
                (" are naturally ", false),
                ("aligned", true),
                (", creating a ", false),
                ("balanced, straight silhouette.", true)
            ])
        case .apple:
            return Text.highlighted([
                ("Your ", false),
                ("upper body and midsection", true),
                (" are naturally ", false),
                ("fuller", true),
                (", paired with ", false),
                ("slender hips and legs.", true)
            ])
        }
    }

    private var fallbackMannequinSilhouette: some View {
        ZStack {
            Color(hex: "#F5F5F7")
            Image("bodyfront")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .padding(.vertical, 16)
        }
    }

    // MARK: - 2. Editable Measurements Card (Bust, Waist, Hips, Torso)

    private var measurementsListCard: some View {
        VStack(spacing: 0) {
            measurementRow(
                title: "Bust",
                text: $bustText,
                field: .bust
            ) { newValue in
                if let val = parseDouble(newValue), val > 0 {
                    viewModel.updateMeasurement(bust: val)
                }
            }

            Divider()
                .padding(.horizontal, 18)

            measurementRow(
                title: "Waist",
                text: $waistText,
                field: .waist
            ) { newValue in
                if let val = parseDouble(newValue), val > 0 {
                    viewModel.updateMeasurement(waist: val)
                }
            }

            Divider()
                .padding(.horizontal, 18)

            measurementRow(
                title: "Hips",
                text: $hipsText,
                field: .hips
            ) { newValue in
                if let val = parseDouble(newValue), val > 0 {
                    viewModel.updateMeasurement(hip: val)
                }
            }

            Divider()
                .padding(.horizontal, 18)

            measurementRow(
                title: "Torso",
                text: $torsoText,
                field: .torso
            ) { newValue in
                if let val = parseDouble(newValue), val > 0 {
                    viewModel.updateMeasurement(torso: val)
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private func measurementRow(
        title: String,
        text: Binding<String>,
        field: EditableField,
        onChange: @escaping (String) -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.black)

            Spacer()

            HStack(spacing: 4) {
                TextField("0", text: text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .focused($focusedMetric, equals: field)
                    .frame(width: 64)
                    .onChange(of: text.wrappedValue) { _, newValue in
                        onChange(newValue)
                    }

                Text("cm")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "#8E8E93"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func syncTextFieldsFromViewModel() {
        bustText = "\(Int(round(bustCm)))"
        waistText = "\(Int(round(waistCm)))"
        hipsText = "\(Int(round(hipCm)))"
        torsoText = "\(Int(round(torsoLenCm)))"
    }

    private func parseDouble(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    // MARK: - 3. Torso Proportion & Height Percentage Card (Kept Below Body Type)

    private var torsoProportionCard: some View {
        let torsoPct = viewModel.torsoRatioPercent ?? 58.0
        let lowerPct = viewModel.lowerBodyRatioPercent ?? (100.0 - torsoPct)
        let torsoLen = viewModel.torsoLengthCm ?? round(viewModel.heightCm * 0.58)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PROPORSI TORSO & TINGGI BADAN")
                    .font(AppTypography.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AppColors.mutedCaption)

                Spacer()

                Text(activeTorsoBalance.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.espressoTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.pastelPeach.opacity(0.40))
                    .clipShape(Capsule())
            }

            Text(LocalizedStringKey("Torsomu **\(String(format: "%.1f", torsoPct))%** dari badanmu (Panjang torso **\(String(format: "%.1f", torsoLen)) cm** dari total tinggi **\(Int(viewModel.heightCm)) cm**)"))
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 6) {
                GeometryReader { geo in
                    let barW = geo.size.width
                    let torsoW = barW * (CGFloat(torsoPct) / 100.0)
                    let lowerW = max(CGFloat(0), barW - torsoW)

                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.pastelPeach)
                            .frame(width: max(CGFloat(10), torsoW))
                            .overlay(
                                Text(String(format: "%.0f%% Torso", torsoPct))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.espressoTitle)
                            )

                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.pastelSage)
                            .frame(width: max(CGFloat(10), lowerW))
                            .overlay(
                                Text(String(format: "%.0f%% Kaki", lowerPct))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.espressoTitle)
                            )
                    }
                }
                .frame(height: 26)

                HStack {
                    Text("Torso: \(String(format: "%.1f", torsoLen)) cm")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColors.espressoTitle)

                    Spacer()

                    Text("Kaki & Tubuh Bawah: \(String(format: "%.1f", max(0, viewModel.heightCm - torsoLen))) cm")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColors.espressoTitle)
                }
            }
        }
        .padding(AppDimensions.cardInternalPadding)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    // MARK: - 4. Torso Balance Card (Kept Below Body Type)

    private var torsoBalanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERTICAL PROPORTION")
                        .font(AppTypography.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(AppColors.mutedCaption)

                    Text(activeTorsoBalance.rawValue)
                        .font(AppTypography.screenHeader)
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Spacer()

                Text(activeTorsoBalance.thrThresholdDescription)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.espressoTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.pastelGold.opacity(0.35))
                    .clipShape(Capsule())
            }

            torsoGaugeView

            Text(activeTorsoBalance.definition)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppDimensions.cardInternalPadding)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
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

            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let clampedTHR = min(38.0, max(25.0, thrRatio))
                let indicatorX = totalWidth * CGFloat((clampedTHR - 25.0) / (38.0 - 25.0))

                ZStack(alignment: .leading) {
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(activeTorsoBalance == .shortTorso ? AppColors.espressoTitle : Color.black.opacity(0.08))
                            .frame(maxWidth: .infinity)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(activeTorsoBalance == .balanced ? AppColors.espressoTitle : Color.black.opacity(0.08))
                            .frame(maxWidth: .infinity)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(activeTorsoBalance == .longTorso ? AppColors.espressoTitle : Color.black.opacity(0.08))
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 10)

                    Circle()
                        .fill(AppColors.espressoTitle)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                        .offset(x: max(0, min(totalWidth - 16, indicatorX - 8)))
                }
            }
            .frame(height: 16)

            HStack {
                Text("Short (<30%)")
                    .font(.system(size: 10, weight: activeTorsoBalance == .shortTorso ? .bold : .regular))
                    .foregroundStyle(activeTorsoBalance == .shortTorso ? AppColors.espressoTitle : AppColors.mutedCaption)

                Spacer()

                Text("Balanced (30-33%)")
                    .font(.system(size: 10, weight: activeTorsoBalance == .balanced ? .bold : .regular))
                    .foregroundStyle(activeTorsoBalance == .balanced ? AppColors.espressoTitle : AppColors.mutedCaption)

                Spacer()

                Text("Long (>33%)")
                    .font(.system(size: 10, weight: activeTorsoBalance == .longTorso ? .bold : .regular))
                    .foregroundStyle(activeTorsoBalance == .longTorso ? AppColors.espressoTitle : AppColors.mutedCaption)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 5. Styling Principle Card (Act)

    private var stylingPrincipleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.espressoTitle)

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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private func guidanceBulletRow(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.espressoTitle)

            Text(content)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.bodyText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Body Measurement Diagram Overlay (Red Bust/Waist/Hips Slices + Blue Triangle)

struct BodyMeasurementDiagramOverlay: View {
    let bustY: Double
    let waistY: Double
    let hipY: Double
    let bustBounds: (Double, Double)?
    let waistBounds: (Double, Double)?
    let hipBounds: (Double, Double)?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let bL = CGFloat(bustBounds?.0 ?? 0.20) * w
            let bR = CGFloat(bustBounds?.1 ?? 0.80) * w
            let wL = CGFloat(waistBounds?.0 ?? 0.27) * w
            let wR = CGFloat(waistBounds?.1 ?? 0.73) * w
            let hL = CGFloat(hipBounds?.0 ?? 0.22) * w
            let hR = CGFloat(hipBounds?.1 ?? 0.78) * w

            let yBust = CGFloat(bustY) * h
            let yWaist = CGFloat(waistY) * h
            let yHip = CGFloat(hipY) * h

            ZStack {
                // Blue proportion triangle from Bust endpoints down to Hip center
                Path { path in
                    path.move(to: CGPoint(x: bL, y: yBust))
                    path.addLine(to: CGPoint(x: bR, y: yBust))
                    path.addLine(to: CGPoint(x: (hL + hR) / 2.0, y: yHip))
                    path.closeSubpath()
                }
                .stroke(Color(hex: "#0A66C2"), lineWidth: 1.4)

                // Red horizontal slice lines at Bust, Waist, and Hips
                Path { path in
                    path.move(to: CGPoint(x: bL, y: yBust))
                    path.addLine(to: CGPoint(x: bR, y: yBust))

                    path.move(to: CGPoint(x: wL, y: yWaist))
                    path.addLine(to: CGPoint(x: wR, y: yWaist))

                    path.move(to: CGPoint(x: hL, y: yHip))
                    path.addLine(to: CGPoint(x: hR, y: yHip))
                }
                .stroke(Color(hex: "#D92B2B"), lineWidth: 1.8)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Body Pose & Slice Overlay View (Ported from CobaBodyScan/PoseOverlayView.swift)

struct BodyPoseOverlayView: View {
    let poseResult: PoseAnalysisResult?
    let chestY: Double?
    let waistY: Double?
    let hipY: Double?
    let chestBounds: (Double, Double)?
    let waistBounds: (Double, Double)?
    let hipBounds: (Double, Double)?
    let showSkeleton: Bool
    let showSlices: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if showSkeleton, let pose = poseResult {
                    drawSkeleton(pose: pose, size: geo.size)
                }

                if showSlices {
                    drawSliceLines(size: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func drawSkeleton(pose: PoseAnalysisResult, size: CGSize) -> some View {
        Canvas { context, _ in
            let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                (.nose, .neck),
                (.neck, .leftShoulder),
                (.neck, .rightShoulder),
                (.leftShoulder, .leftElbow),
                (.leftElbow, .leftWrist),
                (.rightShoulder, .rightElbow),
                (.rightElbow, .rightWrist),
                (.leftShoulder, .leftHip),
                (.rightShoulder, .rightHip),
                (.leftHip, .rightHip),
                (.leftHip, .leftKnee),
                (.leftKnee, .leftAnkle),
                (.rightHip, .rightKnee),
                (.rightKnee, .rightAnkle)
            ]

            for (j1, j2) in connections {
                if let p1 = pose.joints[j1], let p2 = pose.joints[j2] {
                    var path = Path()
                    path.move(to: CGPoint(x: p1.normalizedLocation.x * size.width, y: p1.normalizedLocation.y * size.height))
                    path.addLine(to: CGPoint(x: p2.normalizedLocation.x * size.width, y: p2.normalizedLocation.y * size.height))
                    context.stroke(path, with: .color(.cyan.opacity(0.8)), lineWidth: 2.5)
                }
            }

            for (_, joint) in pose.joints {
                let center = CGPoint(x: joint.normalizedLocation.x * size.width, y: joint.normalizedLocation.y * size.height)
                let rect = CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: rect), with: .color(.white))
                context.stroke(Path(ellipseIn: rect), with: .color(.cyan), lineWidth: 1.5)
            }
        }
    }

    @ViewBuilder
    private func drawSliceLines(size: CGSize) -> some View {
        ZStack {
            if let y = chestY {
                sliceMarker(
                    label: "Bust",
                    color: .cyan,
                    y: y * size.height,
                    width: size.width,
                    bounds: chestBounds
                )
            }

            if let y = waistY {
                sliceMarker(
                    label: "Waist",
                    color: .green,
                    y: y * size.height,
                    width: size.width,
                    bounds: waistBounds
                )
            }

            if let y = hipY {
                sliceMarker(
                    label: "Hips",
                    color: .orange,
                    y: y * size.height,
                    width: size.width,
                    bounds: hipBounds
                )
            }
        }
    }

    private func sliceMarker(
        label: String,
        color: Color,
        y: CGFloat,
        width: CGFloat,
        bounds: (Double, Double)?
    ) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(color.opacity(0.4))
                .frame(width: width, height: 1)
                .position(x: width / 2, y: y)

            if let (l, r) = bounds, r > l {
                let startX = CGFloat(l) * width
                let segW = CGFloat(r - l) * width
                Rectangle()
                    .fill(color)
                    .frame(width: segW, height: 3)
                    .position(x: startX + (segW / 2), y: y)
            }

            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .position(x: 40, y: max(12, y - 12))
        }
    }
}

// MARK: - Preview

#Preview {
    let vm = BodyScanViewModel()
    vm.classifiedBodyType = .invertedTriangle
    vm.classifiedTorsoBalance = .balanced
    vm.shoulderWidthCm = 39.5
    vm.bustCircumferenceCm = 60.0
    vm.waistCircumferenceCm = 50.0
    vm.hipCircumferenceCm = 55.0
    vm.torsoLengthCm = 54.0
    vm.computedTorsoToHeightRatio = 31.8
    return BodyAnalysisResultView(viewModel: vm)
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
