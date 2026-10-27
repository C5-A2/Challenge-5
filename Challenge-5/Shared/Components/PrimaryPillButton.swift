//
//  PrimaryPillButton.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public struct PrimaryPillButton: View {
    
    // MARK: - Style Enum
    public enum Style: Sendable {
        case dark        // Solid Black (default: "Start Now", "Next", "Let's Get Started" in Sketch)
        case secondary   // Frosted white / card container with dark text and subtle border
        case blue        // Action blue fallback
        
        var backgroundColor: Color {
            switch self {
            case .dark: return AppColors.primaryBlack
            case .secondary: return AppColors.cardBackground
            case .blue: return AppColors.primaryBlue
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .dark, .blue: return .white
            case .secondary: return AppColors.espressoTitle
            }
        }
    }
    
    // MARK: - Properties
    public let title: String
    public var iconSystemName: String? = nil
    public var style: Style = .dark
    public var isEnabled: Bool = true
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        title: String,
        iconSystemName: String? = nil,
        style: Style = .dark,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconSystemName = iconSystemName
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let iconSystemName {
                    Image(systemName: iconSystemName)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(AppTypography.buttonLabel)
            }
            .foregroundStyle(style.foregroundColor.opacity(isEnabled ? 1.0 : 0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(style.backgroundColor.opacity(isEnabled ? 1.0 : 0.4))
            .overlay {
                if style == .secondary {
                    Capsule()
                        .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                }
            }
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isEnabled ? 0.08 : 0.0), radius: 6, y: 3)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        PrimaryPillButton(title: "Start Now") { }
        PrimaryPillButton(title: "Let's Get Started", iconSystemName: "sparkles") { }
        PrimaryPillButton(title: "Next") { }
        PrimaryPillButton(title: "Where to Buy", iconSystemName: "cart.fill", style: .secondary) { }
        PrimaryPillButton(title: "Disabled State", isEnabled: false) { }
    }
    .padding()
}
