//
//  PrimaryPillButton.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public struct PrimaryPillButton: View {
    
    // MARK: - Properties
    public let title: String
    public var isEnabled: Bool = true
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.buttonLabel)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isEnabled ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.4))
                .clipShape(Capsule())
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        PrimaryPillButton(title: "Start Now") { }
        PrimaryPillButton(title: "Next", isEnabled: false) { }
    }
    .padding()
}
