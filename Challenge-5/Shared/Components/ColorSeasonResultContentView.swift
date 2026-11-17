//
//  ColorSeasonResultContentView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 17/11/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
typealias ColorSeasonPlatformImage = UIImage
#else
typealias ColorSeasonPlatformImage = AnyObject
#endif

/// Shared Color Season summary card + swatch grids used identically across
/// `ProfileHubView` (Color Season tab) and `SkinResultView` (Analyze Result).
struct ColorSeasonResultContentView: View {
    let season: ColorSeason
    let faceImage: ColorSeasonPlatformImage?

    @State private var activeColorSheet: ColorListSheet? = nil

    private enum ColorListSheet: String, Identifiable {
        case suits, avoid
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // White Summary Card with Circular Color Ring + Face Photo
            VStack(spacing: 16) {
                ProfileSeasonRingAvatarView(
                    hexColors: season.wheelHexColors,
                    diameter: 226,
                    faceImage: faceImage
                )
                .padding(.top, 6)

                Text(season.rawValue)
                    .font(AppTypography.title2Bold.width(.expanded))
                    .foregroundStyle(AppColors.espressoTitle)

                Text(season.definition)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color(hex: "#7A7A7A"))
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

            // "Color that suit you the most" Swatch Grid
            VStack(alignment: .leading, spacing: 12) {
                swatchSectionHeader(title: "Color that suit you the most") {
                    activeColorSheet = .suits
                }

                swatchGrid(hexes: Array(displayedGridSwatches(for: season).prefix(8)))
            }

            // "Color doesn't suits you" Swatch Grid
            VStack(alignment: .leading, spacing: 12) {
                swatchSectionHeader(title: "Color doesn't suits you") {
                    activeColorSheet = .avoid
                }

                swatchGrid(hexes: Array(avoidHexes(for: season).prefix(8)))
            }
        }
        .sheet(item: $activeColorSheet) { sheet in
            switch sheet {
            case .suits:
                ColorSwatchListSheet(
                    title: "Color that Suit you the Most",
                    hexes: displayedGridSwatches(for: season)
                )
            case .avoid:
                ColorSwatchListSheet(
                    title: "Color Doesn't Suits you",
                    hexes: avoidHexes(for: season)
                )
            }
        }
    }

    private func displayedGridSwatches(for season: ColorSeason) -> [String] {
        season.palette.map(\.hex)
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

struct ProfileSeasonRingAvatarView: View {
    let hexColors: [String]
    let diameter: CGFloat
    let faceImage: ColorSeasonPlatformImage?

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
