//
//  MultiSelectChip.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public struct MultiSelectChip: View {
    
    // MARK: - Properties
    public let label: String
    public let isSelected: Bool
    public var showsPlusIcon: Bool = true
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        label: String,
        isSelected: Bool,
        showsPlusIcon: Bool = true,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isSelected = isSelected
        self.showsPlusIcon = showsPlusIcon
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                if showsPlusIcon {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .font(AppTypography.chipLabel)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? .white : AppColors.bodyText)
            .background(isSelected ? AppColors.primaryBlack : AppColors.inputBackground)
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : AppColors.inputBorder,
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    HStack {
        MultiSelectChip(label: "confident", isSelected: true) { }
        MultiSelectChip(label: "elegant", isSelected: false) { }
        MultiSelectChip(label: "M", isSelected: true, showsPlusIcon: false) { }
    }
    .padding()
}
