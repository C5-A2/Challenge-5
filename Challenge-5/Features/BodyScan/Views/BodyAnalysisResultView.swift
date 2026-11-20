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
    @State private var focusedMetric: EditableField? = nil

    @State private var selectedPhotoTab: Int = 0 // 0 = Front View, 1 = Side View, 2 = Torso Length
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
        .invertedTriangle
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
                    VStack(spacing: 18) {
                        // 1. Top Card: Body Photo with Bust/Waist/Hips Overlay + Body Type Classification
                        bodyTypeHeroCard

                        // 2. Editable Measurements Card: Bust, Waist, Hips, Torso
                        measurementsListCard

                        // 3. Styling Direction
                        stylingPrincipleCard

                        BodyStylesThatSuitYouSection(bodyType: activeBodyType)
                            .padding(.top, 4)

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .environment(\.colorScheme, .light)
        .onAppear {
            syncTextFieldsFromViewModel()
        }
        .onChange(of: focusedMetric) { _, _ in
            syncTextFieldsFromViewModel()
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Left: Back (<) Button
            CircularIconButton(systemName: "chevron.left") {
                viewModel.currentStep = .metricsInput
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("Analyze Result")
                .font(AppTypography.bodySemiBold)
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            // Right: Confirm (Checkmark) Button — Saves to Profile & Completes
            CircularIconButton(systemName: "checkmark", isFilled: true) {
                focusedMetric = nil
                _ = viewModel.saveToProfile(in: modelContext)
                if let onComplete = onComplete {
                    onComplete()
                } else {
                    dismiss()
                }
            }
            .accessibilityLabel("Confirm")
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.vertical, 8)
    }

    // MARK: - 1. Body Type Hero Card (IG-Style Swipeable Front / Side / Torso Length + Body Shape Title & Description)

    private var bodyTypeHeroCard: some View {
        VStack(spacing: 14) {
            #if canImport(UIKit)
            let resolvedFrontImage: BodyCarouselImage? = viewModel.frontImage ?? (viewModel.frontImageData != nil ? UIImage(data: viewModel.frontImageData!) : nil)
            let resolvedSideImage: BodyCarouselImage? = viewModel.sideImage ?? (viewModel.sideImageData != nil ? UIImage(data: viewModel.sideImageData!) : nil)
            #else
            let resolvedFrontImage: BodyCarouselImage? = nil
            let resolvedSideImage: BodyCarouselImage? = nil
            #endif

            BodyAnalysisCarouselView(
                selectedTab: $selectedPhotoTab,
                frontImage: resolvedFrontImage,
                sideImage: resolvedSideImage,
                frontPose: viewModel.frontPoseResult,
                sidePose: viewModel.sidePoseResult,
                frontBustY: viewModel.detectedBustY,
                frontWaistY: viewModel.detectedWaistY,
                frontHipY: viewModel.detectedHipY,
                frontChestBounds: viewModel.frontChestBounds,
                frontWaistBounds: viewModel.frontWaistBounds,
                frontHipBounds: viewModel.frontHipBounds,
                sideBustY: viewModel.detectedSideBustY,
                sideWaistY: viewModel.detectedSideWaistY,
                sideHipY: viewModel.detectedSideHipY,
                sideChestBounds: viewModel.sideChestBounds,
                sideWaistBounds: viewModel.sideWaistBounds,
                sideHipBounds: viewModel.sideHipBounds,
                torsoLengthCm: torsoLenCm,
                heightCm: viewModel.heightCm,
                torsoBalance: activeTorsoBalance,
                showSkeleton: showSkeleton,
                showSlices: showSlices,
                frameHeight: 360
            )

            // Overlay Toggle Controls (Skeleton & Slice Lines — active across all views)
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

            // Dynamic Title & Highlighted Description (Body Type on Front/Side, Torso Type on Torso Length slide)
            Text(selectedPhotoTab == 2 ? activeTorsoBalance.displayName : activeBodyType.displayName)
                .font(.system(size: 21, weight: .bold).width(.expanded))
                .foregroundStyle(AppColors.espressoTitle)
                .animation(.easeInOut(duration: 0.2), value: selectedPhotoTab)

            Group {
                if selectedPhotoTab == 2 {
                    activeTorsoBalance.highlightedDescription
                } else {
                    bodyTypeHighlightedDescription(for: activeBodyType)
                }
            }
            .font(.system(size: 13.5))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
            .animation(.easeInOut(duration: 0.2), value: selectedPhotoTab)
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

    // MARK: - 2. Editable Measurements Card (Bust, Waist, Hips, Torso)

    private var measurementsListCard: some View {
        VStack(spacing: 0) {
            EditableMeasurementsCardHeader(
                showReset: viewModel.isMeasurementsEdited,
                onReset: {
                    focusedMetric = nil
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        viewModel.resetMeasurementsToBaseline()
                    }
                    syncTextFieldsFromViewModel()
                }
            )

            EditableMeasurementRow(
                title: "Bust",
                text: $bustText,
                field: .bust,
                focusedField: $focusedMetric
            ) { newValue in
                if let val = MeasurementTextFormatting.parse(newValue), val > 0 {
                    viewModel.updateMeasurement(bust: val)
                }
            }

            Divider()
                .padding(.horizontal, 18)

            EditableMeasurementRow(
                title: "Waist",
                text: $waistText,
                field: .waist,
                focusedField: $focusedMetric
            ) { newValue in
                if let val = MeasurementTextFormatting.parse(newValue), val > 0 {
                    viewModel.updateMeasurement(waist: val)
                }
            }

            Divider()
                .padding(.horizontal, 18)

            EditableMeasurementRow(
                title: "Hips",
                text: $hipsText,
                field: .hips,
                focusedField: $focusedMetric
            ) { newValue in
                if let val = MeasurementTextFormatting.parse(newValue), val > 0 {
                    viewModel.updateMeasurement(hip: val)
                }
            }

            Divider()
                .padding(.horizontal, 18)

            EditableMeasurementRow(
                title: "Torso",
                text: $torsoText,
                field: .torso,
                focusedField: $focusedMetric
            ) { newValue in
                if let val = MeasurementTextFormatting.parse(newValue), val > 0 {
                    viewModel.updateMeasurement(torso: val)
                }
            }
        }
        .padding(.bottom, 6)
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

    private func syncTextFieldsFromViewModel() {
        if focusedMetric != .bust {
            bustText = MeasurementTextFormatting.format(bustCm)
        }
        if focusedMetric != .waist {
            waistText = MeasurementTextFormatting.format(waistCm)
        }
        if focusedMetric != .hips {
            hipsText = MeasurementTextFormatting.format(hipCm)
        }
        if focusedMetric != .torso {
            torsoText = MeasurementTextFormatting.format(torsoLenCm)
        }
    }

    // MARK: - 3. Styling Principle Card (Act)

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
