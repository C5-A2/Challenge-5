//
//  ColorPaletteSwatchRow.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Horizontal row of recommended outfit color swatches inside a rounded container.
/// Seen on the Occasion Result stage in the design specs.
public struct ColorPaletteSwatchRow: View {
    
    // MARK: - Properties
    public let hexColors: [String]
    public var dotSize: CGFloat
    public var onSelectColor: ((String) -> Void)?
    
    // MARK: - Initializer
    public init(
        hexColors: [String],
        dotSize: CGFloat = 24,
        onSelectColor: ((String) -> Void)? = nil
    ) {
        self.hexColors = hexColors
        self.dotSize = dotSize
        self.onSelectColor = onSelectColor
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: 10) {
            ForEach(hexColors, id: \.self) { hex in
                Button {
                    onSelectColor?(hex)
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: dotSize, height: dotSize)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColors.cardBackground.opacity(0.92))
                .overlay(
                    Capsule()
                        .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    ColorPaletteSwatchRow(hexColors: [
        "#1B263B",
        "#E0A96D",
        "#778DA9",
        "#F4F1DE"
    ])
    .padding()
    .background(Color.gray.opacity(0.2))
}
