//
//  ColorSeasonWheelView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Circular seasonal color wheel visual used on the Color Analysis Result screen.
/// Visually highlights the 4 seasonal palettes (Spring, Summer, Autumn, Winter).
public struct ColorSeasonWheelView: View {
    
    // MARK: - Properties
    public let selectedSeasonName: String
    public var wheelDiameter: CGFloat
    
    private let seasonalColors: [Color] = [
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
    
    // MARK: - Initializer
    public init(
        selectedSeasonName: String = "Warm Spring",
        wheelDiameter: CGFloat = 200
    ) {
        self.selectedSeasonName = selectedSeasonName
        self.wheelDiameter = wheelDiameter
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            // Segmented circular pie / color wheel
            ForEach(0..<seasonalColors.count, id: \.self) { index in
                let startAngle = Angle.degrees(Double(index) / Double(seasonalColors.count) * 360)
                let endAngle = Angle.degrees(Double(index + 1) / Double(seasonalColors.count) * 360)
                
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
                .fill(seasonalColors[index])
            }
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            
            // Inner hollow center cutout / badge
            Circle()
                .fill(AppColors.cardBackground)
                .frame(width: wheelDiameter * 0.52, height: wheelDiameter * 0.52)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                .overlay {
                    VStack(spacing: 2) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.espressoTitle)
                        Text(selectedSeasonName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.espressoTitle)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 6)
                    }
                }
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
    }
}

// MARK: - Preview
#Preview {
    ColorSeasonWheelView(selectedSeasonName: "Warm Spring", wheelDiameter: 220)
        .padding()
}
