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
    @State private var focusedMetricField: ProfileMetricField? = nil

    // MARK: - State

    @State private var selectedTab: ProfileTab = .colorSeason
    @State private var activeSheet: ActiveProfileSheet? = nil
    @State private var selectedBodyPhotoSide: Int = 0 // 0 = Front, 1 = Side, 2 = Torso Length
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

    private enum ActiveProfileSheet: Identifiable {
        case skinScan
        case bodyScan

        var id: Int { hashValue }
    }

    // MARK: - Computed Profile Values

    private var currentProfile: UserProfile? {
        userProfiles.first
    }

    private var hasSkinData: Bool {
        currentProfile?.hasCompletedSkinScan == true
    }

    private var hasBodyData: Bool {
        currentProfile?.hasCompletedBodyScan == true
    }

    private var isCurrentTabEmpty: Bool {
        switch selectedTab {
        case .colorSeason:
            return !hasSkinData
        case .bodyType:
            return !hasBodyData
        }
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

                segmentedTabBar
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.bottom, 16)

                mainContentCardContainer
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            }
        }
        .fullScreenCover(item: $activeSheet, onDismiss: {
            refreshCachedImages()
            syncProfileMetricInputs()
            if selectedTab == .bodyType {
                runOverlayPoseDetectionIfNeeded(force: true)
            }
        }) { sheet in
            switch sheet {
            case .skinScan:
                SkinScanFlowHostView()
            case .bodyScan:
                BodyScanFlowHostView()
            }
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
                        .font(isSelected ? AppTypography.calloutSemiBold : AppTypography.subheadlineRegular)
                        .foregroundStyle(AppColors.bodyText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(AppColors.cardBackground)
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
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
                .fill(AppColors.circularButtonBackground)
        )
    }

    // MARK: - Main Content Card Container

    private var mainContentCardContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )

            if isCurrentTabEmpty {
                emptyStateContent
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
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
                                .foregroundStyle(AppColors.primaryBlue)
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
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var emptyStateContent: some View {
        switch selectedTab {
        case .colorSeason:
            ProfileEmptyStateCard(
                imageName: "empty_state_skin",
                title: "Find the colors that feel like you.",
                subtitle: "Discover your personal color palette and see which shades complement your natural features.",
                buttonTitle: "Discover My Colors",
                action: handleRetakeTap
            )
        case .bodyType:
            ProfileEmptyStateCard(
                imageName: "empty_state_body",
                title: "Let's find the perfect look for you.",
                subtitle: "Every body is different. Let's explore your body shape and proportions to help you find silhouettes that work for you.",
                buttonTitle: "Start your Body Analysis",
                action: handleRetakeTap
            )
        }
    }

    // MARK: - Tab 1: Color Season Content

    private var colorSeasonTabContent: some View {
        #if canImport(UIKit)
        let resolvedFaceImage: ColorSeasonPlatformImage? = faceUIImage
        #else
        let resolvedFaceImage: ColorSeasonPlatformImage? = nil
        #endif

        return ColorSeasonResultContentView(
            season: activeSeason,
            faceImage: resolvedFaceImage
        )
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

                Text(selectedBodyPhotoSide == 2 ? activeTorsoBalance.displayName : activeBodyType.rawValue)
                    .font(AppTypography.title2Bold.width(.expanded))
                    .foregroundStyle(AppColors.espressoTitle)
                    .animation(.easeInOut(duration: 0.2), value: selectedBodyPhotoSide)

                Group {
                    if selectedBodyPhotoSide == 2 {
                        activeTorsoBalance.highlightedDescription
                    } else {
                        bodyTypeHighlightedText(for: activeBodyType)
                    }
                }
                .font(.system(size: 13.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                .animation(.easeInOut(duration: 0.2), value: selectedBodyPhotoSide)
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

            // 3. "Styles that suit you" Visual Recommendations Section
            BodyStylesThatSuitYouSection(bodyType: activeBodyType)
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

    @ViewBuilder
    private var bodyPhotoPreview: some View {
        let height = currentProfile?.measurements?.heightCm ?? 170.0

        VStack(spacing: 12) {
            #if canImport(UIKit)
            let resolvedFrontImage: BodyCarouselImage? = frontBodyUIImage
            let resolvedSideImage: BodyCarouselImage? = sideBodyUIImage
            #else
            let resolvedFrontImage: BodyCarouselImage? = nil
            let resolvedSideImage: BodyCarouselImage? = nil
            #endif

            BodyAnalysisCarouselView(
                selectedTab: $selectedBodyPhotoSide,
                frontImage: resolvedFrontImage,
                sideImage: resolvedSideImage,
                frontPose: cachedFrontPose,
                sidePose: cachedSidePose,
                frontBustY: cachedFrontBustY ?? 0.30,
                frontWaistY: cachedFrontWaistY ?? 0.45,
                frontHipY: cachedFrontHipY ?? 0.55,
                frontChestBounds: cachedFrontChestBounds,
                frontWaistBounds: cachedFrontWaistBounds,
                frontHipBounds: cachedFrontHipBounds,
                sideBustY: cachedSideBustY ?? 0.30,
                sideWaistY: cachedSideWaistY ?? 0.45,
                sideHipY: cachedSideHipY ?? 0.55,
                sideChestBounds: cachedSideChestBounds,
                sideWaistBounds: cachedSideWaistBounds,
                sideHipBounds: cachedSideHipBounds,
                torsoLengthCm: profileTorsoCm,
                heightCm: height,
                torsoBalance: activeTorsoBalance,
                showSkeleton: showSkeleton,
                showSlices: showSlices,
                frameHeight: 336
            )

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
}

// MARK: - Empty State Card

/// Empty state shown inside ProfileHubView when a tab has not been scanned yet.
private struct ProfileEmptyStateCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 16)

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 196)
                        .padding(.bottom, 28)

                    Text(title)
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.top, 8)
                        .padding(.horizontal, 28)

                    Button(action: action) {
                        Text(buttonTitle)
                            .font(AppTypography.buttonLabel)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppColors.primaryBlack)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 26)
                    .padding(.horizontal, 28)

                    Spacer(minLength: 16)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
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
                SkinResultView(viewModel: viewModel, onDismiss: { dismiss() }) {
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
            case .frontCamera, .frontReview:
                FrontBodyCameraView(viewModel: viewModel)
            case .sideGuide, .sideCamera, .sideReview, .metricsInput:
                SideBodyGuideView(viewModel: viewModel, onDismiss: { dismiss() })
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
