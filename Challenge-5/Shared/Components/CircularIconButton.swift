//
//  CircularIconButton.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public struct CircularIconButton: View {
    
    // MARK: - Properties
    public let systemName: String
    public var isFilled: Bool = false
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        systemName: String,
        isFilled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.isFilled = isFilled
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isFilled ? AppColors.primaryBlack : AppColors.bodyText)
                .frame(
                    width: AppDimensions.circularIconSize,
                    height: AppDimensions.circularIconSize
                )
                .background(AppColors.cardBackground)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 12) {
        CircularIconButton(systemName: "clock.arrow.circlepath") { }
        CircularIconButton(systemName: "circle") { }
        CircularIconButton(systemName: "xmark") { }
        CircularIconButton(systemName: "arrow.up") { }
        CircularIconButton(systemName: "bookmark.fill", isFilled: true) { }
    }
    .padding()
}
