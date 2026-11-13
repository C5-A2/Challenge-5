//
//  ProfileHubView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// Profile screen displaying the user's analyzed Color Season and Body Type
/// in a clean two-tab layout ("Color Season" and "Body Type").
struct ProfileHubView: View {

    // MARK: - Tab Definition

    enum ProfileTab: String, CaseIterable, Identifiable {
        case colorSeason = "Color Season"
        case bodyType = "Body Type"

        var id: String { rawValue }
    }

    // MARK: - Properties & Navigation

    var onBack: (() -> Void)? = nil
    var onSelectColorSeason: (() -> Void)? = nil
    var onSelectBodyType: (() -> Void)? = nil
    var onSelectMeasurements: (() -> Void)? = nil
    var onSelectCharacter: (() -> Void)? = nil

    // MARK: - SwiftData Query & Environment

    @Query private var userProfiles: [UserProfile]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Namespace private var tabAnimationNamespace
    @FocusState private var focusedMetricField: ProfileMetricField?

    // MARK: - State

    @State private var selectedTab: ProfileTab = .colorSeason
    @State private var activeSheet: ActiveProfileSheet? = nil
    @State private var activeColorSheet: ColorListSheet? = nil
    private let showManualProfileDebug: Bool = true
    @State private var isShowingDebugSheet: Bool = false
    @State private var selectedBodyPhotoSide: Int = 0 // 0 = Front, 1 = Side
    @State private var showSkeleton: Bool = true
    @State private var showSlices: Bool = true

    @State private var bustInputText: String = ""
    @State private var waistInputText: String = ""
    @State private var hipsInputText: String = ""
    @State private var torsoInputText: String = ""
    @State private var editedTorsoCm: Double? = nil

    #if canImport(UIKit)
    @State private var cachedFaceImage: UIImage? = nil
    @State private var cachedFrontBodyImage: UIImage? = nil
    @State private var cachedSideBodyImage: UIImage? = nil
    #endif
    @State private var cachedFrontPose: PoseAnalysisResult? = nil
    @State private var cachedSidePose: PoseAnalysisResult? = nil
    @State private var cachedFrontBustY: Double? = nil
    @State private var cachedFrontWaistY: Double? = nil
    @State private var cachedFrontHipY: Double? = nil
    @State private var cachedSideBustY: Double? = nil
    @State private var cachedSideWaistY: Double? = nil
    @State private var cachedSideHipY: Double? = nil
    @State private var cachedFrontChestBounds: (Double, Double)? = nil
    @State private var cachedFrontWaistBounds: (Double, Double)? = nil
    @State private var cachedFrontHipBounds: (Double, Double)? = nil
    @State private var cachedSideChestBounds: (Double, Double)? = nil
    @State private var cachedSideWaistBounds: (Double, Double)? = nil
    @State private var cachedSideHipBounds: (Double, Double)? = nil

    private enum ProfileMetricField: Hashable {
        case bust
        case waist
        case hips
        case torso
    }

    private enum ColorListSheet: String, Identifiable {
        case suits, avoid
        var id: String { rawValue }
    }

    private enum ActiveProfileSheet: Identifiable {
        case skinScan
        case bodyScan

        var id: Int { hashValue }
    }

    // MARK: - Computed Profile Values

    private var currentProfile: UserProfile? {
        userProfiles.first
    }

    private var activeSeason: ColorSeason {
        currentProfile?.colorSeason ?? .trueSpring
    }

    private var activeBodyType: BodyType {
        currentProfile?.bodyType ?? .hourglass
    }

    private var activeTorsoBalance: TorsoBalance {
        currentProfile?.torsoBalance ?? .balanced
    }

    #if canImport(UIKit)
    private var faceUIImage: UIImage? {
        cachedFaceImage
    }

    private var frontBodyUIImage: UIImage? {
        cachedFrontBodyImage
    }

    private var sideBodyUIImage: UIImage? {
        cachedSideBodyImage
    }
    #endif

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                headerBar

                titleSection
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.bottom, 12)

                if showManualProfileDebug {
                    debugAutoFillSection
                        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                        .padding(.bottom, 12)
                }

                segmentedTabBar
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.bottom, 16)

                mainContentCardContainer
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            }
        }
        .fullScreenCover(item: $activeSheet) { sheet in
            switch sheet {
            case .skinScan:
                SkinScanFlowHostView()
            case .bodyScan:
                BodyScanFlowHostView()
            }
        }
        .sheet(isPresented: $isShowingDebugSheet) {
            TemporaryProfileFormSheet()
        }
        .environment(\.colorScheme, .light)
        .onAppear {
            refreshCachedImages()
            syncProfileMetricInputs()
            if selectedTab == .bodyType {
                runOverlayPoseDetectionIfNeeded()
            }
        }
        .onDisappear {
            commitMetricField(focusedMetricField)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .bodyType {
                runOverlayPoseDetectionIfNeeded()
            }
        }
        .onChange(of: currentProfile?.facePhotoData) { _, _ in
            refreshCachedImages()
        }
        .onChange(of: currentProfile?.frontBodyPhotoData) { _, _ in
            refreshCachedImages()
            runOverlayPoseDetectionIfNeeded(force: true)
        }
        .onChange(of: currentProfile?.sideBodyPhotoData) { _, _ in
            refreshCachedImages()
            runOverlayPoseDetectionIfNeeded(force: true)
        }
        .onChange(of: currentProfile?.updatedAt) { _, _ in
            syncProfileMetricInputs()
        }
        .onChange(of: focusedMetricField) { oldField, _ in
            commitMetricField(oldField)
            syncProfileMetricInputs()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedMetricField = nil
                }
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(Color.black)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button {
                commitMetricField(focusedMetricField)
                focusedMetricField = nil
                if let onBack = onBack {
                    onBack()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppColors.espressoTitle)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(hex: "#F7F7F7"))
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        Text("Profile")
            .font(AppTypography.titleBold)
            .foregroundStyle(AppColors.espressoTitle)
            .padding(.top, 2)
    }

    // MARK: - Debug Manual Profile Form Section (from dev)

    private var debugAutoFillSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                isShowingDebugSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Set Profile Manually (Debug)")
                        .font(.system(size: 14.5, weight: .semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(AppColors.primaryBlack)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Segmented Tab Bar (Color Season | Body Type)

    private var segmentedTabBar: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                        .foregroundStyle(Color(hex: "#1C1C1E"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
                                    .matchedGeometryEffect(id: "ActiveProfileTab", in: tabAnimationNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(hex: "#EFEFF0"))
        )
    }

    // MARK: - Main Content Card Container

    private var mainContentCardContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: "#F3F3F5"))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    switch selectedTab {
                    case .colorSeason:
                        colorSeasonTabContent
                    case .bodyType:
                        bodyTypeTabContent
                    }

                    // Bottom "Retake the photo" Button (inside ScrollView, not floating)
                    Button {
                        handleRetakeTap()
                    } label: {
                        Text("Retake the photo")
                            .font(AppTypography.calloutSemiBold)
                            .foregroundStyle(Color(hex: "#007AFF"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(.bottom, 8)
    }

    // MARK: - Tab 1: Color Season Content

    private var colorSeasonTabContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            // White Summary Card with Circular Color Ring + Face Photo
            VStack(spacing: 16) {
                ProfileSeasonRingAvatarView(
                    hexColors: seasonRingHexColors(for: activeSeason),
                    diameter: 226,
                    faceImage: {
                        #if canImport(UIKit)
                        return faceUIImage
                        #else
                        return nil
                        #endif
                    }()
                )
                .padding(.top, 6)

                Text(seasonDisplayName(for: activeSeason))
                    .font(AppTypography.title2Bold.width(.expanded))
                    .foregroundStyle(AppColors.espressoTitle)

                undertoneHighlightedText(for: activeSeason)
                    .font(.system(size: 13.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            )

            // "Color suits you the most" Swatch Grid
            VStack(alignment: .leading, spacing: 12) {
                swatchSectionHeader(title: "Color suits you the most") {
                    activeColorSheet = .suits
                }

                swatchGrid(hexes: Array(displayedGridSwatches(for: activeSeason).prefix(8)))
            }

            // "Color doesn't suits you" Swatch Grid
            VStack(alignment: .leading, spacing: 12) {
                swatchSectionHeader(title: "Color doesn't suits you") {
                    activeColorSheet = .avoid
                }

                swatchGrid(hexes: Array(avoidHexes(for: activeSeason).prefix(8)))
            }
        }
        .sheet(item: $activeColorSheet) { sheet in
            switch sheet {
            case .suits:
                ColorSwatchListSheet(
                    title: "Color Suits you the Most",
                    hexes: displayedGridSwatches(for: activeSeason)
                )
            case .avoid:
                ColorSwatchListSheet(
                    title: "Color Doesn't Suits you",
                    hexes: avoidHexes(for: activeSeason)
                )
            }
        }
    }

    private func avoidHexes(for season: ColorSeason) -> [String] {
        season.colorsToAvoidPalette.map(\.hex)
    }

    private func swatchSectionHeader(title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.calloutSemiBold)
                .foregroundStyle(Color(hex: "#1C1C1E"))
            Spacer()
            Button(action: action) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .frame(width: 30, height: 30)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func swatchGrid(hexes: [String]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(hexes.enumerated()), id: \.offset) { _, hex in
                colorSwatchSquare(hex: hex)
            }
        }
    }

    private func colorSwatchSquare(hex: String) -> some View {
        let normalizedHex = hex.uppercased()
        let isDark = isDarkHex(normalizedHex)

        return ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: normalizedHex))

            Text(normalizedHex)
                .font(AppTypography.caption2Regular)
                .foregroundStyle(isDark ? Color.white.opacity(0.92) : Color(hex: "#2C2C2E"))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 4)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    // MARK: - Tab 2: Body Type Content

    private var profileBustCm: Double {
        let height = currentProfile?.measurements?.heightCm ?? 170.0
        return currentProfile?.measurements?.bustCircumferenceCm ?? round((height * 0.53) * 10) / 10
    }

    private var profileWaistCm: Double {
        let height = currentProfile?.measurements?.heightCm ?? 170.0
        return currentProfile?.measurements?.waistCircumferenceCm ?? round((height * 0.41) * 10) / 10
    }

    private var profileHipCm: Double {
        let height = currentProfile?.measurements?.heightCm ?? 170.0
        return currentProfile?.measurements?.hipCircumferenceCm ?? round((height * 0.56) * 10) / 10
    }

    private var profileTorsoCm: Double {
        if let editedTorsoCm { return editedTorsoCm }
        if let savedTorso = currentProfile?.measurements?.torsoLengthCm {
            return savedTorso
        }
        let height = currentProfile?.measurements?.heightCm ?? 170.0
        let ratio: Double = {
            switch activeTorsoBalance {
            case .shortTorso: return 0.285
            case .balanced: return 0.315
            case .longTorso: return 0.345
            }
        }()
        return round((height * ratio) * 10) / 10
    }

    private var bodyTypeTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 1. White Summary Card with CobaBodyScan Front/Side Photo + Body Shape Title & Description
            VStack(spacing: 14) {
                bodyPhotoPreview

                Divider()
                    .padding(.vertical, 2)

                Text(activeBodyType.rawValue)
                    .font(AppTypography.title2Bold.width(.expanded))
                    .foregroundStyle(AppColors.espressoTitle)

                bodyTypeHighlightedText(for: activeBodyType)
                    .font(.system(size: 13.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            )

            // 2. Editable Bust, Waist, Hips, Torso Measurements Card
            VStack(spacing: 0) {
                EditableMeasurementsCardHeader()

                EditableMeasurementRow(
                    title: "Bust",
                    text: $bustInputText,
                    field: .bust,
                    focusedField: $focusedMetricField
                ) { _ in }
                Divider().padding(.horizontal, 18)
                EditableMeasurementRow(
                    title: "Waist",
                    text: $waistInputText,
                    field: .waist,
                    focusedField: $focusedMetricField
                ) { _ in }
                Divider().padding(.horizontal, 18)
                EditableMeasurementRow(
                    title: "Hips",
                    text: $hipsInputText,
                    field: .hips,
                    focusedField: $focusedMetricField
                ) { _ in }
                Divider().padding(.horizontal, 18)
                EditableMeasurementRow(
                    title: "Torso",
                    text: $torsoInputText,
                    field: .torso,
                    focusedField: $focusedMetricField
                ) { _ in }
            }
            .padding(.bottom, 6)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )

            // 3. Torso Classification Card (Kept below Body Type)
            profileTorsoClassificationCard

            // 4. "Styles that suit you the most" Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Styles that suit you the most")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))

                VStack(spacing: 10) {
                    garmentRecommendationRow(
                        icon: "tshirt",
                        title: "Tops & Necklines",
                        detail: activeBodyType.suitableNecklines
                    )
                    garmentRecommendationRow(
                        icon: "jacket",
                        title: "Jackets & Sleeves",
                        detail: activeBodyType.suitableTopsAndJackets
                    )
                    garmentRecommendationRow(
                        icon: "figure.walk",
                        title: "Bottoms & Trousers",
                        detail: activeBodyType.suitableBottoms
                    )
                    garmentRecommendationRow(
                        icon: "sparkles",
                        title: "Skirts & Dresses",
                        detail: activeBodyType.suitableSkirtsAndDresses
                    )
                }
            }
        }
    }

    private func commitMetricField(_ field: ProfileMetricField?) {
        guard let field else { return }
        switch field {
        case .bust:
            if let v = MeasurementTextFormatting.parse(bustInputText), v > 0, v != profileBustCm {
                applyProfileMeasurementUpdate(bust: v)
            }
        case .waist:
            if let v = MeasurementTextFormatting.parse(waistInputText), v > 0, v != profileWaistCm {
                applyProfileMeasurementUpdate(waist: v)
            }
        case .hips:
            if let v = MeasurementTextFormatting.parse(hipsInputText), v > 0, v != profileHipCm {
                applyProfileMeasurementUpdate(hip: v)
            }
        case .torso:
            if let v = MeasurementTextFormatting.parse(torsoInputText), v > 0, v != profileTorsoCm {
                editedTorsoCm = v
                applyProfileMeasurementUpdate(torso: v)
            }
        }
    }

    private func syncProfileMetricInputs() {
        if focusedMetricField != .bust {
            bustInputText = MeasurementTextFormatting.format(profileBustCm)
        }
        if focusedMetricField != .waist {
            waistInputText = MeasurementTextFormatting.format(profileWaistCm)
        }
        if focusedMetricField != .hips {
            hipsInputText = MeasurementTextFormatting.format(profileHipCm)
        }
        if focusedMetricField != .torso {
            torsoInputText = MeasurementTextFormatting.format(profileTorsoCm)
        }
    }

    private func applyProfileMeasurementUpdate(
        bust: Double? = nil,
        waist: Double? = nil,
        hip: Double? = nil,
        torso: Double? = nil
    ) {
        let currentM = currentProfile?.measurements
        let height = currentM?.heightCm ?? 170.0
        let newBust = bust ?? profileBustCm
        let newWaist = waist ?? profileWaistCm
        let newHip = hip ?? profileHipCm
        let newTorso = torso ?? profileTorsoCm
        let shoulder = currentM?.shoulderWidthCm ?? round((height * 0.235) * 10) / 10

        let updatedMeasurements = BodyMeasurements(
            age: currentM?.age ?? 23,
            weightKg: currentM?.weightKg ?? 60.0,
            heightCm: height,
            usualSize: currentM?.usualSize ?? .m,
            shoulderWidthCm: shoulder,
            bustCircumferenceCm: newBust,
            waistCircumferenceCm: newWaist,
            hipCircumferenceCm: newHip,
            torsoLengthCm: newTorso
        )

        let classification = BodyClassifier.classify(
            bustCm: newBust,
            waistCm: newWaist,
            hipCm: newHip,
            shoulderWidthCm: shoulder,
            enteredHeightCm: height,
            torsoLengthCm: newTorso
        )

        if let profile = currentProfile {
            profile.measurements = updatedMeasurements
            profile.bodyType = classification.bodyType
            profile.torsoBalance = classification.torsoBalance
            profile.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private var profileTorsoClassificationCard: some View {
        let height = currentProfile?.measurements?.heightCm ?? 170.0
        let thrRatio: Double = height > 0
            ? round(((profileTorsoCm / height) * 100.0) * 10) / 10
            : 31.5

        return VStack(alignment: .leading, spacing: 14) {
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
            }
            .padding(12)
            .background(Color.black.opacity(0.025))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(activeTorsoBalance.definition)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
        )
    }

    @ViewBuilder
    private var bodyPhotoPreview: some View {
        VStack(spacing: 12) {
            Picker("View", selection: $selectedBodyPhotoSide) {
                Text("Front View").tag(0)
                Text("Side View").tag(1)
            }
            .pickerStyle(.segmented)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.04))

                #if canImport(UIKit)
                if selectedBodyPhotoSide == 0, let frontImg = frontBodyUIImage {
                    Image(uiImage: frontImg)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 320)
                        .overlay(
                            BodyPoseOverlayView(
                                poseResult: cachedFrontPose,
                                chestY: cachedFrontBustY ?? 0.30,
                                waistY: cachedFrontWaistY ?? 0.45,
                                hipY: cachedFrontHipY ?? 0.55,
                                chestBounds: cachedFrontChestBounds,
                                waistBounds: cachedFrontWaistBounds,
                                hipBounds: cachedFrontHipBounds,
                                showSkeleton: showSkeleton,
                                showSlices: showSlices
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else if selectedBodyPhotoSide == 1, let sideImg = sideBodyUIImage {
                    Image(uiImage: sideImg)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 320)
                        .overlay(
                            BodyPoseOverlayView(
                                poseResult: cachedSidePose,
                                chestY: cachedSideBustY ?? 0.30,
                                waistY: cachedSideWaistY ?? 0.45,
                                hipY: cachedSideHipY ?? 0.55,
                                chestBounds: cachedSideChestBounds,
                                waistBounds: cachedSideWaistBounds,
                                hipBounds: cachedSideHipBounds,
                                showSkeleton: showSkeleton,
                                showSlices: showSlices
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    defaultBodyIllustration
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                #else
                defaultBodyIllustration
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                #endif
            }
            .frame(height: 336)

            HStack(spacing: 16) {
                Button {
                    withAnimation { showSkeleton.toggle() }
                } label: {
                    Label("Skeleton", systemImage: showSkeleton ? "eye.fill" : "eye.slash")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(showSkeleton ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1))
                        .foregroundStyle(showSkeleton ? .green : .secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation { showSlices.toggle() }
                } label: {
                    Label("Slice Lines", systemImage: showSlices ? "eye.fill" : "eye.slash")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(showSlices ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.1))
                        .foregroundStyle(showSlices ? .orange : .secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func refreshCachedImages() {
        #if canImport(UIKit)
        cachedFaceImage = currentProfile?.facePhotoData.flatMap { UIImage(data: $0) }
        cachedFrontBodyImage = currentProfile?.frontBodyPhotoData.flatMap { UIImage(data: $0) }
        cachedSideBodyImage = currentProfile?.sideBodyPhotoData.flatMap { UIImage(data: $0) }
        #endif
    }

    private func runOverlayPoseDetectionIfNeeded(force: Bool = false) {
        #if canImport(UIKit)
        if !force, cachedFrontPose != nil { return }
        guard let frontImg = frontBodyUIImage else { return }
        let sideImg = sideBodyUIImage ?? frontImg
        let heightCm = currentProfile?.measurements?.heightCm ?? 170.0

        Task {
            guard let fPose = try? await BodyPoseAnalyzer.analyzePose(image: frontImg) else { return }
            let sPose = try? await BodyPoseAnalyzer.analyzePose(image: sideImg)
            let dims = await BodyDimensionCalculator.calculateDimensions(
                frontImage: frontImg,
                sideImage: sideImg,
                enteredHeightCm: heightCm,
                frontPose: fPose,
                sidePose: sPose
            )
            await MainActor.run {
                self.cachedFrontPose = fPose
                self.cachedSidePose = sPose
                self.cachedFrontBustY = dims.frontChestY
                self.cachedFrontWaistY = dims.frontWaistY
                self.cachedFrontHipY = dims.frontHipY
                self.cachedSideBustY = dims.sideChestY
                self.cachedSideWaistY = dims.sideWaistY
                self.cachedSideHipY = dims.sideHipY
                self.cachedFrontChestBounds = dims.frontChestSlice.map { ($0.normalizedLeft, $0.normalizedRight) }
                self.cachedFrontWaistBounds = dims.frontWaistSlice.map { ($0.normalizedLeft, $0.normalizedRight) }
                self.cachedFrontHipBounds = dims.frontHipSlice.map { ($0.normalizedLeft, $0.normalizedRight) }
                self.cachedSideChestBounds = dims.sideChestSlice.map { ($0.normalizedLeft, $0.normalizedRight) }
                self.cachedSideWaistBounds = dims.sideWaistSlice.map { ($0.normalizedLeft, $0.normalizedRight) }
                self.cachedSideHipBounds = dims.sideHipSlice.map { ($0.normalizedLeft, $0.normalizedRight) }
            }
        }
        #endif
    }

    private var defaultBodyIllustration: some View {
        ZStack {
            Color(hex: "#F5F5F7")
            Image("bodyfront")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .padding(.vertical, 14)
        }
    }

    private func garmentRecommendationRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.canvasBackground)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.espressoTitle)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppColors.espressoTitle)

                Text(detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppColors.bodyText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Actions

    private func handleRetakeTap() {
        switch selectedTab {
        case .colorSeason:
            if let onSelectColorSeason = onSelectColorSeason {
                onSelectColorSeason()
            } else {
                activeSheet = .skinScan
            }
        case .bodyType:
            if let onSelectBodyType = onSelectBodyType {
                onSelectBodyType()
            } else {
                activeSheet = .bodyScan
            }
        }
    }

    // MARK: - Formatting & Palette Helpers

    private func seasonDisplayName(for season: ColorSeason) -> String {
        season.rawValue
    }

    private func undertoneHighlightedText(for season: ColorSeason) -> Text {
        Text(season.definition)
            .foregroundColor(Color(hex: "#7A7A7A"))
    }

    private func bodyTypeHighlightedText(for bodyType: BodyType) -> Text {
        switch bodyType {
        case .hourglass:
            return Text.highlighted([
                ("Your bust and hip proportions are ", false),
                ("naturally balanced", true),
                (" with a ", false),
                ("well-defined, narrower waistline.", true)
            ])
        case .pear:
            return Text.highlighted([
                ("Your lower frame features ", false),
                ("fuller hips and thighs", true),
                (" paired with a ", false),
                ("defined waist and narrower shoulders.", true)
            ])
        case .rectangle:
            return Text.highlighted([
                ("Your silhouette has ", false),
                ("aligned shoulder, bust, and hip widths", true),
                (" with a ", false),
                ("clean, athletic vertical frame.", true)
            ])
        case .invertedTriangle:
            return Text.highlighted([
                ("Your upper frame features ", false),
                ("broader shoulders and bust", true),
                (" tapering down to ", false),
                ("narrower hips and sleek legs.", true)
            ])
        case .apple:
            return Text.highlighted([
                ("Your silhouette carries ", false),
                ("fullness around the bust and midsection", true),
                (" paired with ", false),
                ("slender legs and narrow hips.", true)
            ])
        }
    }

    /// 20 chromatic ring segments matching the circular color wheel in the design mockup.
    private func seasonRingHexColors(for season: ColorSeason) -> [String] {
        season.wheelHexColors
    }

    /// Curated grid swatches displayed under "Color suits you the most", returning all 35 swatches from the model palette.
    private func displayedGridSwatches(for season: ColorSeason) -> [String] {
        season.palette.map(\.hex)
    }

    /// Computes relative luminance of a hex color to choose readable dark/light label text.
    private func isDarkHex(_ hex: String) -> Bool {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let intVal = UInt64(cleaned, radix: 16) else {
            return false
        }
        let r = Double((intVal >> 16) & 0xFF) / 255.0
        let g = Double((intVal >> 8) & 0xFF) / 255.0
        let b = Double(intVal & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance < 0.52
    }
}

// MARK: - Profile Season Ring Avatar View

private struct ProfileSeasonRingAvatarView: View {
    let hexColors: [String]
    let diameter: CGFloat
    #if canImport(UIKit)
    let faceImage: UIImage?
    #endif

    private var innerDiameter: CGFloat {
        diameter * 0.74
    }

    var body: some View {
        ZStack {
            // Outer segmented color ring (borderless wedges matching the design)
            ForEach(0..<hexColors.count, id: \.self) { index in
                let sliceAngle = 360.0 / Double(max(1, hexColors.count))
                // Offset by half a slice so the first (white/light) wedge is centered at 12 o'clock
                let startAngle = Angle.degrees(Double(index) * sliceAngle - 90.0 - (sliceAngle / 2.0))
                let endAngle = Angle.degrees(Double(index + 1) * sliceAngle - 90.0 - (sliceAngle / 2.0))

                Path { path in
                    let center = CGPoint(x: diameter / 2, y: diameter / 2)
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: diameter / 2,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .fill(Color(hex: hexColors[index]))
            }
            .clipShape(Circle())

            // Center circular portrait
            ZStack {
                Circle()
                    .fill(Color(hex: "#EAE8E4"))

                #if canImport(UIKit)
                if let faceImage = faceImage {
                    Image(uiImage: faceImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: innerDiameter, height: innerDiameter)
                        .clipShape(Circle())
                        .overlay(alignmentGridOverlay)
                } else {
                    placeholderAvatar
                }
                #else
                placeholderAvatar
                #endif
            }
            .frame(width: innerDiameter, height: innerDiameter)
            .clipShape(Circle())
        }
        .frame(width: diameter, height: diameter)
    }

    /// Subtle rule-of-thirds alignment grid over the face portrait matching the mockup.
    private var alignmentGridOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                // Vertical grid lines
                path.move(to: CGPoint(x: w * 0.22, y: 0))
                path.addLine(to: CGPoint(x: w * 0.22, y: h))
                path.move(to: CGPoint(x: w * 0.50, y: 0))
                path.addLine(to: CGPoint(x: w * 0.50, y: h))
                path.move(to: CGPoint(x: w * 0.78, y: 0))
                path.addLine(to: CGPoint(x: w * 0.78, y: h))

                // Horizontal grid lines
                path.move(to: CGPoint(x: 0, y: h * 0.16))
                path.addLine(to: CGPoint(x: w, y: h * 0.16))
                path.move(to: CGPoint(x: 0, y: h * 0.36))
                path.addLine(to: CGPoint(x: w, y: h * 0.36))
                path.move(to: CGPoint(x: 0, y: h * 0.64))
                path.addLine(to: CGPoint(x: w, y: h * 0.64))
            }
            .stroke(Color.yellow.opacity(0.28), lineWidth: 0.7)
        }
        .clipShape(Circle())
        .allowsHitTesting(false)
    }

    private var placeholderAvatar: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.espressoTitle.opacity(0.35))
            Text("Tap Retake to Scan")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.mutedCaption)
        }
    }
}

// MARK: - Subflow Hosts

private struct SkinScanFlowHostView: View {
    @State private var viewModel = SkinScanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .guide:
                SkinScanGuideView(viewModel: viewModel, onDismiss: { dismiss() })
            case .camera:
                FaceCameraView(viewModel: viewModel)
            case .review:
                FaceReviewView(viewModel: viewModel)
            case .result:
                SkinResultView(viewModel: viewModel) {
                    dismiss()
                }
            }
        }
    }
}

private struct BodyScanFlowHostView: View {
    @State private var viewModel = BodyScanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .frontGuide:
                FrontBodyGuideView(viewModel: viewModel, onDismiss: { dismiss() })
            case .frontCamera:
                FrontBodyCameraView(viewModel: viewModel)
            case .frontReview:
                FrontBodyReviewView(viewModel: viewModel)
            case .sideGuide:
                SideBodyGuideView(viewModel: viewModel, onDismiss: { dismiss() })
            case .sideCamera:
                SideBodyCameraView(viewModel: viewModel)
            case .sideReview, .metricsInput:
                SideBodyReviewView(viewModel: viewModel)
            case .analysisResult:
                BodyAnalysisResultView(viewModel: viewModel) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileHubView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}

// MARK: - Color Swatch List Sheet

/// Full-height sheet listing every swatch (4 per row) with a title and close button.
struct ColorSwatchListSheet: View {
    let title: String
    let hexes: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(title)
                    .font(.system(size: 17, weight: .semibold).width(.expanded))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1C1C1E"))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(hex: "#EFEFF0")))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                    ForEach(Array(hexes.enumerated()), id: \.offset) { _, hex in
                        let upper = hex.uppercased()
                        ZStack {
                            Rectangle().fill(Color(hex: upper))
                            Text(upper)
                                .font(.system(size: 10))
                                .foregroundStyle(isDark(upper) ? Color.white.opacity(0.92) : Color(hex: "#2C2C2E"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .aspectRatio(1.0, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color.white)
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .light)
    }

    private func isDark(_ hex: String) -> Bool {
        let c = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard c.count == 6, let v = UInt64(c, radix: 16) else { return false }
        let r = Double((v >> 16) & 0xFF) / 255, g = Double((v >> 8) & 0xFF) / 255, b = Double(v & 0xFF) / 255
        return 0.299 * r + 0.587 * g + 0.114 * b < 0.52
    }
}
