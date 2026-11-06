//
//  LiquidGlassBadge.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 06/11/26.
//

import SwiftUI

/// Reusable Liquid Glass capsule badge component.
/// Provides a luminous, frosted liquid glass appearance with customizable specular reflection.
public struct LiquidGlassBadge: View {
    
    public let text: String
    public var font: Font
    public var textColor: Color
    public var isHighlighted: Bool
    
    public init(
        _ text: String,
        font: Font = AppTypography.folderCardDresscode,
        textColor: Color = AppColors.espressoTitle,
        isHighlighted: Bool = true
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.isHighlighted = isHighlighted
    }
    
    public var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.horizontal, 13)
            .padding(.vertical, 5.5)
            .background(
                ZStack {
                    // Thin translucent material layer (ringan dan tidak terlalu keruh)
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.40))
                    
                    // Terang bercahaya dengan specular gradient putih
                    Capsule()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.95), location: 0.0),
                                    .init(color: Color.white.opacity(0.72), location: 0.45),
                                    .init(color: Color.white.opacity(0.50), location: 0.52),
                                    .init(color: Color.white.opacity(0.85), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.98), location: 0.0),
                                .init(color: Color.white.opacity(0.75), location: 0.35),
                                .init(color: Color.white.opacity(0.45), location: 0.65),
                                .init(color: Color.white.opacity(0.85), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)
            .shadow(color: Color.white.opacity(0.40), radius: 3, x: 0, y: -1)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.6)
            .ignoresSafeArea()
        
        LiquidGlassBadge("Performative Office Worker")
    }
}
