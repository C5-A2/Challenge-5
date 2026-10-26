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
            HStack(spacing: 4) {
                Text(label)
                if showsPlusIcon && !isSelected {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .font(AppTypography.chipLabel)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : AppColors.bodyText)
            .background(isSelected ? AppColors.primaryBlack : Color.clear)
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : AppColors.mutedCaption.opacity(0.5),
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule())
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
