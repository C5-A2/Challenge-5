//
//  BodyAnalysisCarouselView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 17/11/26.
//

import SwiftUI
import Vision
#if canImport(UIKit)
import UIKit
typealias BodyCarouselImage = UIImage
#else
typealias BodyCarouselImage = AnyObject
#endif

/// IG-style 3-page swipeable body analysis carousel (`Front View`, `Side View`, and `Torso Length`)
/// with 3 pagination indicator dots underneath.
struct BodyAnalysisCarouselView: View {
    @Binding var selectedTab: Int

    let frontImage: BodyCarouselImage?
    let sideImage: BodyCarouselImage?

    let frontPose: PoseAnalysisResult?
    let sidePose: PoseAnalysisResult?

    let frontBustY: Double?
    let frontWaistY: Double?
    let frontHipY: Double?
    let frontChestBounds: (Double, Double)?
    let frontWaistBounds: (Double, Double)?
    let frontHipBounds: (Double, Double)?

    let sideBustY: Double?
    let sideWaistY: Double?
    let sideHipY: Double?
    let sideChestBounds: (Double, Double)?
    let sideWaistBounds: (Double, Double)?
    let sideHipBounds: (Double, Double)?

    let torsoLengthCm: Double
    let heightCm: Double
    let torsoBalance: TorsoBalance

    let showSkeleton: Bool
    let showSlices: Bool
    var frameHeight: CGFloat = 350

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.04))
                    .frame(height: frameHeight)

                TabView(selection: $selectedTab) {
                    frontViewSlide
                        .tag(0)

                    sideViewSlide
                        .tag(1)

                    torsoLengthSlide
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: frameHeight)
            }
            .frame(height: frameHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )

            // IG-style 3 bullet dots indicator
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(selectedTab == index ? Color(hex: "#1C1C1E") : Color(hex: "#D1D1D6"))
                        .frame(width: 7, height: 7)
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedTab = index
                            }
                        }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Body view page \(selectedTab + 1) of 3")
        }
    }

    // MARK: - Slide 0: Front View

    @ViewBuilder
    private var frontViewSlide: some View {
        #if canImport(UIKit)
        if let frontImg = frontImage {
            Image(uiImage: frontImg)
                .resizable()
                .scaledToFit()
                .frame(height: frameHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    BodyPoseOverlayView(
                        poseResult: frontPose,
                        chestY: frontBustY,
                        waistY: frontWaistY,
                        hipY: frontHipY,
                        chestBounds: frontChestBounds,
                        waistBounds: frontWaistBounds,
                        hipBounds: frontHipBounds,
                        showSkeleton: showSkeleton,
                        showSlices: showSlices
                    )
                )
        } else {
            fallbackSilhouette
        }
        #else
        fallbackSilhouette
        #endif
    }

    // MARK: - Slide 1: Side View

    @ViewBuilder
    private var sideViewSlide: some View {
        #if canImport(UIKit)
        if let sideImg = sideImage {
            Image(uiImage: sideImg)
                .resizable()
                .scaledToFit()
                .frame(height: frameHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    BodyPoseOverlayView(
                        poseResult: sidePose,
                        chestY: sideBustY ?? frontBustY,
                        waistY: sideWaistY ?? frontWaistY,
                        hipY: sideHipY ?? frontHipY,
                        chestBounds: sideChestBounds,
                        waistBounds: sideWaistBounds,
                        hipBounds: sideHipBounds,
                        showSkeleton: showSkeleton,
                        showSlices: showSlices
                    )
                )
        } else {
            fallbackSilhouette
        }
        #else
        fallbackSilhouette
        #endif
    }

    // MARK: - Slide 2: Torso Length

    @ViewBuilder
    private var torsoLengthSlide: some View {
        ZStack {
            #if canImport(UIKit)
            if let baseImg = frontImage ?? sideImage {
                Image(uiImage: baseImg)
                    .resizable()
                    .scaledToFit()
                    .frame(height: frameHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        TorsoLengthOverlayView(
                            poseResult: frontImage != nil ? frontPose : sidePose,
                            chestY: frontImage != nil ? frontBustY : (sideBustY ?? frontBustY),
                            hipY: frontImage != nil ? frontHipY : (sideHipY ?? frontHipY),
                            torsoLengthCm: torsoLengthCm,
                            heightCm: heightCm,
                            torsoBalance: torsoBalance
                        )
                    )
            } else {
                fallbackSilhouette
                    .overlay(
                        TorsoLengthOverlayView(
                            poseResult: nil,
                            chestY: nil,
                            hipY: nil,
                            torsoLengthCm: torsoLengthCm,
                            heightCm: heightCm,
                            torsoBalance: torsoBalance
                        )
                    )
            }
            #else
            fallbackSilhouette
            #endif
        }
    }

    private var fallbackSilhouette: some View {
        ZStack {
            Color(hex: "#F5F5F7")
            Image("bodyfront")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .padding(.vertical, 16)
        }
    }
}

// MARK: - Torso Length Vertical Proportion Overlay

private struct TorsoLengthOverlayView: View {
    let poseResult: PoseAnalysisResult?
    let chestY: Double?
    let hipY: Double?
    let torsoLengthCm: Double
    let heightCm: Double
    let torsoBalance: TorsoBalance

    private var neckNormY: Double {
        if let nk = poseResult?.joints[.neck]?.normalizedLocation {
            return Double(nk.y)
        }
        if let chest = chestY {
            return max(0.08, chest - 0.12)
        }
        return 0.20
    }

    private var hipNormY: Double {
        if let hip = hipY {
            return hip
        }
        if let poseHip = poseResult?.hipLevelUIKitY {
            return poseHip
        }
        return 0.54
    }

    private var feetNormY: Double {
        poseResult?.feetBottomUIKitY ?? 0.90
    }

    private var centerX: Double {
        if let ls = poseResult?.joints[.leftShoulder]?.normalizedLocation,
           let rs = poseResult?.joints[.rightShoulder]?.normalizedLocation {
            return Double(ls.x + rs.x) / 2.0
        }
        return 0.5
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let x = CGFloat(centerX) * w
            let yTop = CGFloat(neckNormY) * h
            let yHip = CGFloat(hipNormY) * h
            let yFeet = CGFloat(feetNormY) * h
            let torsoMidY = (yTop + yHip) / 2.0
            let lowerMidY = (yHip + yFeet) / 2.0
            let lowerBodyCm = max(0, heightCm - torsoLengthCm)

            ZStack(alignment: .topLeading) {
                // Torso vertical measurement span (Neck -> Hips)
                Path { path in
                    // Top cap
                    path.move(to: CGPoint(x: x - 18, y: yTop))
                    path.addLine(to: CGPoint(x: x + 18, y: yTop))
                    // Vertical shaft
                    path.move(to: CGPoint(x: x, y: yTop))
                    path.addLine(to: CGPoint(x: x, y: yHip))
                    // Bottom hip cap
                    path.move(to: CGPoint(x: x - 18, y: yHip))
                    path.addLine(to: CGPoint(x: x + 18, y: yHip))
                }
                .stroke(Color(hex: "#0A66C2"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                // Lower body vertical span (Hips -> Feet)
                Path { path in
                    path.move(to: CGPoint(x: x, y: yHip))
                    path.addLine(to: CGPoint(x: x, y: yFeet))
                    path.move(to: CGPoint(x: x - 14, y: yFeet))
                    path.addLine(to: CGPoint(x: x + 14, y: yFeet))
                }
                .stroke(Color(hex: "#34C759").opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 4]))

                // Torso Length pill badge
                Text(String(format: "Torso %.1f cm", torsoLengthCm))
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#0A66C2").opacity(0.92))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    .position(x: min(w - 58, max(58, x + 52)), y: torsoMidY)

                // Lower body pill badge
                Text(String(format: "Lower %.1f cm", lowerBodyCm))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#2B7A4B").opacity(0.9))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                    .position(x: min(w - 56, max(56, x + 50)), y: lowerMidY)

                // Bottom summary badge showing Torso type (without technical THR formula)
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Torso Length")
                            .font(.system(size: 11, weight: .bold))
                        Text("•")
                        Text(torsoBalance.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.68))
                    .clipShape(Capsule())
                    .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .allowsHitTesting(false)
    }
}

extension TorsoBalance {
    /// User-friendly highlighted description for the Torso Length carousel slide.
    var highlightedDescription: Text {
        switch self {
        case .shortTorso:
            return Text.highlighted([
                ("Your ", false),
                ("upper torso", true),
                (" is proportionately ", false),
                ("shorter", true),
                (" relative to your height, paired with ", false),
                ("longer legs.", true)
            ])
        case .balanced:
            return Text.highlighted([
                ("Your ", false),
                ("upper torso and leg length", true),
                (" are naturally ", false),
                ("balanced", true),
                (", creating an even ", false),
                ("1:1 vertical proportion.", true)
            ])
        case .longTorso:
            return Text.highlighted([
                ("Your ", false),
                ("upper torso", true),
                (" is proportionately ", false),
                ("longer", true),
                (" relative to your height, with ", false),
                ("legs appearing shorter.", true)
            ])
        }
    }
}
