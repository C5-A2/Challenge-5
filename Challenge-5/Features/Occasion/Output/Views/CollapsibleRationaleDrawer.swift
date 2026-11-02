//
//  CollapsibleRationaleDrawer.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI
import SwiftData

struct CollapsibleRationaleDrawer: View {
    
    // MARK: - SwiftData Query & ViewModel
    
    @Query private var userProfiles: [UserProfile]
    var viewModel: OccasionOutputViewModel
    
    // MARK: - Computed Active Profile Helpers
    
    private var activeProfile: UserProfile {
        viewModel.profile ?? userProfiles.first ?? UserProfile.mockSample
    }
    
    private var activeBodyType: BodyType {
        activeProfile.bodyType ?? .hourglass
    }
    
    private var activeTorsoBalance: TorsoBalance {
        activeProfile.torsoBalance ?? .balanced
    }
    
    private var activeColorSeason: ColorSeason {
        activeProfile.colorSeason ?? .trueAutumn
    }
    
    // MARK: - Initializer
    
    init(viewModel: OccasionOutputViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
            SheetDragHandle()
                .padding(.top, 4)
            
            headerSection
                .padding(.top, 4)
                .padding(.bottom, 12)
            
            FitRationaleSegmentBar(selectedTab: Binding(
                get: { viewModel.selectedFitTab },
                set: { viewModel.selectedFitTab = $0 }
            ))
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.bottom, 14)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    switch viewModel.selectedFitTab {
                    case .bodyShape:
                        bodyShapeContent
                    case .colorAnalyze:
                        colorAnalyzeContent
                    case .torso:
                        torsoBalanceContent
                    }
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                .padding(.bottom, 48)
            }
        }
        .background(
            AppColors.cardBackground
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Subviews: Header
    
    private var headerSection: some View {
        Text("Details")
            .font(AppTypography.sfProSemiboldExtended(size: 18))
            .foregroundStyle(AppColors.espressoTitle)
    }
    
    // MARK: - Subviews: Body Shape Tab
    
    private var bodyShapeContent: some View {
        VStack(spacing: 14) {
            
            HStack(alignment: .center, spacing: 16) {
                bodyIllustration
                    .frame(width: 105, height: 125)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(activeBodyType.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    // Dummy metrics preserved per design requirement
                    metricBadge(title: "Shoulder", value: "70 Cm")
                    metricBadge(title: "Waist", value: "50 Cm")
                    metricBadge(title: "Hips", value: "40 Cm")
                }
                Spacer()
            }
            .padding(.vertical, 2)
            
            if !viewModel.currentGarments.isEmpty {
                ForEach(viewModel.currentGarments) { garment in
                    garmentCutRationaleCard(
                        garmentName: "\(garment.name) (\(garment.category.rawValue))",
                        rationale: !garment.rationale.isEmpty ? garment.rationale : (viewModel.currentLook?.fitRationale ?? "Specially selected to complement your body silhouette and balance proportions.")
                    )
                }
            } else {
                garmentCutRationaleCard(
                    garmentName: "AI Recommended Fit",
                    rationale: viewModel.currentLook?.fitRationale
                        ?? "The slim-fit polo with a sharp collar softens the broad shoulder line without adding upper bulk. Paired with straight-leg burgundy trousers, it draws the gaze downward to create a well-balanced silhouette."
                )
            }
        }
    }
    
    private var bodyIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#FAF6F0"))
            
            VStack(spacing: 6) {
                bodyTypeIcon
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.pastelPeach)
                
                Text(bodyTypeSubtitle)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppColors.mutedCaption)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var bodyTypeIcon: some View {
        switch activeBodyType {
        case .hourglass:
            Image(systemName: "hourglass")
        case .pear:
            Image(systemName: "triangle.fill")
        case .rectangle:
            Image(systemName: "rectangle.portrait.fill")
        case .invertedTriangle:
            Image(systemName: "triangle.fill")
                .rotationEffect(.degrees(180))
        case .apple:
            Image(systemName: "circle.fill")
        }
    }
    
    private var bodyTypeSubtitle: String {
        switch activeBodyType {
        case .hourglass:
            return "Curved Waist"
        case .pear:
            return "Wider Hips"
        case .rectangle:
            return "Balanced Frame"
        case .invertedTriangle:
            return "Bahu Lebar"
        case .apple:
            return "Round Curve"
        }
    }
    
    private func metricBadge(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(title):")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppColors.bodyText)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.espressoTitle)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(hex: "#F5F3EF"))
        )
    }

    private func garmentCutRationaleCard(garmentName: String, rationale: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                blueWireframeIcon
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(garmentName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Text("AI Recommended Fit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#007AFF"))
                }
            }
            
            Text(rationale)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#FAF8F5"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var blueWireframeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#E8F2FF"))
            
            Path { path in
                for i in 1...3 {
                    path.move(to: CGPoint(x: CGFloat(i) * 12, y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(i) * 12, y: 48))
                    path.move(to: CGPoint(x: 0, y: CGFloat(i) * 12))
                    path.addLine(to: CGPoint(x: 48, y: CGFloat(i) * 12))
                }
            }
            .stroke(Color(hex: "#007AFF").opacity(0.4), lineWidth: 0.8)
            
            Image(systemName: "tshirt")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "#007AFF"))
        }
    }
    
    // MARK: - Subviews: Color Analyze Tab
    
    private var colorAnalyzeContent: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                colorAnalysisIllustration
                    .frame(width: 105, height: 125)

                VStack(alignment: .leading, spacing: 6) {
                    Text(activeColorSeason.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    metricBadge(title: "Tone", value: activeColorSeason.hue)
                    metricBadge(title: "Value", value: activeColorSeason.value)
                    metricBadge(title: "Contrast", value: activeColorSeason.chroma)
                }
                Spacer()
            }
            .padding(.vertical, 2)
            
            garmentColorRationaleCard(
                paletteName: "\(activeColorSeason.rawValue) Harmony",
                rationale: activeColorSeason.definition
            )
        }
    }
    
    private var colorAnalysisIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#FAF6F0"))
            
            ColorSeasonWheelView(selectedSeasonName: colorSeasonWheelLabel, wheelDiameter: 96)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var colorSeasonWheelLabel: String {
        let words = activeColorSeason.rawValue.split(separator: " ")
        if words.count == 2 {
            return "\(words[0])\n\(words[1])"
        }
        return activeColorSeason.rawValue
    }
    
    private func garmentColorRationaleCard(paletteName: String, rationale: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                blueColorWireframeIcon
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(paletteName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Text("AI Color Harmony")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#007AFF"))
                }
            }
            
            ColorPaletteSwatchRow(
                hexColors: activeColorSeason.sampleSwatches.map(\.hex),
                dotSize: 22
            )
            .padding(.vertical, 2)
            
            Text(rationale)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#FAF8F5"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private var blueColorWireframeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#E8F2FF"))
            
            Path { path in
                for i in 1...3 {
                    path.move(to: CGPoint(x: CGFloat(i) * 12, y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(i) * 12, y: 48))
                    path.move(to: CGPoint(x: 0, y: CGFloat(i) * 12))
                    path.addLine(to: CGPoint(x: 48, y: CGFloat(i) * 12))
                }
            }
            .stroke(Color(hex: "#007AFF").opacity(0.4), lineWidth: 0.8)
            
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#007AFF"))
        }
    }
    
    // MARK: - Subviews: Torso Balance Tab
    
    private var torsoBalanceContent: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                torsoIllustration
                    .frame(width: 105, height: 125)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(activeTorsoBalance.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    // Dummy metrics preserved per design requirement
                    metricBadge(title: "Upper Body", value: "38 Cm")
                    metricBadge(title: "Leg Length", value: "79 Cm")
                    metricBadge(title: "Torso Ratio", value: "32% (Balanced)")
                }
                Spacer()
            }
            .padding(.vertical, 2)
            
            garmentTorsoRationaleCard(
                proportionTitle: "Optimal Waist Placement",
                rationale: "\(activeTorsoBalance.suitableGarments.top) \(activeTorsoBalance.suitableGarments.bottom)"
            )
        }
    }
    
    private var torsoIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#FAF6F0"))
            
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#C5A880"), lineWidth: 1.5)
                        .frame(width: 54, height: 72)
                    
                    Rectangle()
                        .fill(Color(hex: "#007AFF"))
                        .frame(width: 62, height: 1.5)
                        .offset(y: torsoLineOffset)
                    
                    Image(systemName: "figure.stand")
                        .font(.system(size: 38))
                        .foregroundStyle(AppColors.espressoTitle.opacity(0.75))
                }
                
                Text(torsoBalanceTag)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppColors.mutedCaption)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var torsoLineOffset: CGFloat {
        switch activeTorsoBalance {
        case .shortTorso:
            return -8
        case .balanced:
            return 0
        case .longTorso:
            return 8
        }
    }
    
    private var torsoBalanceTag: String {
        switch activeTorsoBalance {
        case .shortTorso:
            return "High Rise"
        case .balanced:
            return "1:1 Balance"
        case .longTorso:
            return "Low Rise"
        }
    }
    
    private func garmentTorsoRationaleCard(proportionTitle: String, rationale: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                blueTorsoWireframeIcon
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(proportionTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Text("AI Torso Alignment")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#007AFF"))
                }
            }
            
            Text(rationale)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#FAF8F5"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private var blueTorsoWireframeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#E8F2FF"))
            
            Path { path in
                for i in 1...3 {
                    path.move(to: CGPoint(x: CGFloat(i) * 12, y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(i) * 12, y: 48))
                    path.move(to: CGPoint(x: 0, y: CGFloat(i) * 12))
                    path.addLine(to: CGPoint(x: 48, y: CGFloat(i) * 12))
                }
            }
            .stroke(Color(hex: "#007AFF").opacity(0.4), lineWidth: 0.8)
            
            Image(systemName: "ruler.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#007AFF"))
        }
    }
}

// MARK: - Preview

#Preview("Details Drawer") {
    CollapsibleRationaleDrawer(viewModel: .mock())
        .background(Color.black.opacity(0.2))
        .modelContainer(for: [UserProfile.self, OccasionItem.self], inMemory: true)
}
