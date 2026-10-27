//
//  ColorSeasonWheelView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Circular seasonal color wheel visual used on the Color Analysis Result screen.
/// Visually highlights the 4 seasonal palettes (Spring, Summer, Autumn, Winter)
/// or specific personal color season chromatic wedges with optional center face portrait.
public struct ColorSeasonWheelView: View {
    
    // MARK: - Properties
    public let selectedSeasonName: String
    public var wheelDiameter: CGFloat
    public var hexColors: [String]?
    #if canImport(UIKit)
    public var faceImage: UIImage?
    #endif
    
    private let defaultSeasonalColors: [Color] = [
        Color(hex: "#FFB085"), // Warm Spring peach
        Color(hex: "#FFD384"), // Light Spring gold
        Color(hex: "#A8D8EA"), // Light Summer sky
        Color(hex: "#AA96DA"), // Soft Summer lavender
        Color(hex: "#FCBAD3"), // Cool Summer rose
        Color(hex: "#957DAD"), // Soft Autumn plum
        Color(hex: "#D291BC"), // True Autumn muted rose
        Color(hex: "#E0BBE4"), // True Winter icy violet
        Color(hex: "#50B498"), // Warm Spring green
        Color(hex: "#4682B4"), // Deep Winter royal blue
        Color(hex: "#C06C84"), // Deep Autumn berry
        Color(hex: "#F67280")  // Warm coral
    ]
    
    private var activeColors: [Color] {
        if let hexColors = hexColors, !hexColors.isEmpty {
            return hexColors.map { Color(hex: $0) }
        }
        return defaultSeasonalColors
    }
    
    // MARK: - Initializers
    #if canImport(UIKit)
    public init(
        selectedSeasonName: String = "Warm Spring",
        wheelDiameter: CGFloat = 200,
        hexColors: [String]? = nil,
        faceImage: UIImage? = nil
    ) {
        self.selectedSeasonName = selectedSeasonName
        self.wheelDiameter = wheelDiameter
        self.hexColors = hexColors
        self.faceImage = faceImage
    }
    #else
    public init(
        selectedSeasonName: String = "Warm Spring",
        wheelDiameter: CGFloat = 200,
        hexColors: [String]? = nil
    ) {
        self.selectedSeasonName = selectedSeasonName
        self.wheelDiameter = wheelDiameter
        self.hexColors = hexColors
    }
    #endif
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            // Segmented circular pie / color wheel
            ForEach(0..<activeColors.count, id: \.self) { index in
                let sliceAngle = 360.0 / Double(activeColors.count)
                let startAngle = Angle.degrees(Double(index) * sliceAngle - 90)
                let endAngle = Angle.degrees(Double(index + 1) * sliceAngle - 90)
                
                Path { path in
                    let center = CGPoint(x: wheelDiameter / 2, y: wheelDiameter / 2)
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: wheelDiameter / 2,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .fill(activeColors[index])
                .overlay(
                    Path { path in
                        let center = CGPoint(x: wheelDiameter / 2, y: wheelDiameter / 2)
                        path.move(to: center)
                        path.addArc(
                            center: center,
                            radius: wheelDiameter / 2,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false
                        )
                        path.closeSubpath()
                    }
                    .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                )
            }
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
            
            // Outer thin ring
            Circle()
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                .frame(width: wheelDiameter, height: wheelDiameter)
            
            // Inner center cutout (face portrait or season badge)
            Circle()
                .fill(AppColors.cardBackground)
                .frame(width: wheelDiameter * 0.58, height: wheelDiameter * 0.58)
                .overlay {
                    centerContent
                }
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3.5)
                        .shadow(color: .black.opacity(0.10), radius: 3)
                )
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
    }

    @ViewBuilder
    private var centerContent: some View {
        #if canImport(UIKit)
        if let faceImage = faceImage {
            Image(uiImage: faceImage)
                .resizable()
                .scaledToFill()
                .frame(width: wheelDiameter * 0.58, height: wheelDiameter * 0.58)
                .clipShape(Circle())
        } else {
            defaultCenterBadge
        }
        #else
        defaultCenterBadge
        #endif
    }

    private var defaultCenterBadge: some View {
        VStack(spacing: 3) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#C68B59"))
            Text(selectedSeasonName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.espressoTitle)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 6)
        }
    }
}

// MARK: - Preview
#Preview {
    ColorSeasonWheelView(selectedSeasonName: "Warm Spring", wheelDiameter: 220)
        .padding()
}
