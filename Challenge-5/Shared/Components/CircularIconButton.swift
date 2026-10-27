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
    public var isEnabled: Bool = true
    public var backgroundColor: Color? = nil
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        systemName: String,
        isFilled: Bool = false,
        isEnabled: Bool = true,
        backgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.isFilled = isFilled
        self.isEnabled = isEnabled
        self.backgroundColor = backgroundColor
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
                .background(backgroundColor ?? AppColors.circularButtonBackground)
                .clipShape(Circle())
                .shadow(color: .black.opacity(isEnabled ? 0.04 : 0.01), radius: 3, y: 1)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.45)
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
