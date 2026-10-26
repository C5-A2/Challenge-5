//
//  TagChip.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// A clean, non-interactive tag chip for displaying garment materials, dress codes, or style tags.
/// Seen on the Occasion Card ("white dress", "satin") and Result Stage garment labels.
public struct TagChip: View {
    
    // MARK: - Properties
    public let text: String
    public var iconSystemName: String?
    public var isFrosted: Bool
    
    // MARK: - Initializer
    public init(
        _ text: String,
        iconSystemName: String? = nil,
        isFrosted: Bool = true
    ) {
        self.text = text
        self.iconSystemName = iconSystemName
        self.isFrosted = isFrosted
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: 4) {
            if let iconSystemName {
                Image(systemName: iconSystemName)
                    .font(.system(size: 11, weight: .medium))
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(AppColors.bodyText)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            if isFrosted {
                Capsule()
                    .fill(AppColors.tagChipBackground)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5)
                    )
            } else {
                Capsule()
                    .fill(AppColors.cardBackground)
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                    )
            }
        }
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 8) {
        TagChip("white dress")
        TagChip("satin")
        TagChip("polo", iconSystemName: "tshirt")
        TagChip("Skinny Jeans", isFrosted: false)
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
