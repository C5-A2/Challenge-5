//
//  LiquidGlassCircularButton.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 06/11/26.
//

import SwiftUI

/// Reusable small circular button with a frosted, reflective liquid glass appearance.
/// Supports custom vector content (e.g., profile silhouette, SF Symbols, custom icons).
public struct LiquidGlassCircularButton<Content: View>: View {
    
    public var size: CGFloat
    public var isEnabled: Bool
    public let action: () -> Void
    public let content: () -> Content
    
    public init(
        size: CGFloat = AppDimensions.circularIconSize,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
        self.content = content
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                // Translucent frosted glass material base
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.40))
                
                // Specular liquid reflective gradient
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.95), location: 0.0),
                                .init(color: Color.white.opacity(0.70), location: 0.45),
                                .init(color: Color.white.opacity(0.45), location: 0.52),
                                .init(color: Color.white.opacity(0.85), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Custom Icon Content
                content()
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.98), location: 0.0),
                                .init(color: Color.white.opacity(0.70), location: 0.40),
                                .init(color: Color.white.opacity(0.40), location: 0.65),
                                .init(color: Color.white.opacity(0.85), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(isEnabled ? 0.08 : 0.02), radius: 4, x: 0, y: 2)
            .shadow(color: Color.white.opacity(isEnabled ? 0.35 : 0.10), radius: 2, x: 0, y: -1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.45)
    }
}

extension LiquidGlassCircularButton where Content == AnyView {
    /// Convenience initializer for SF Symbol icon.
    public init(
        systemName: String,
        size: CGFloat = AppDimensions.circularIconSize,
        iconSize: CGFloat = 16,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(size: size, isEnabled: isEnabled, action: action) {
            AnyView(
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
            )
        }
    }
    
    /// Profile avatar silhouette button.
    public static func profile(
        size: CGFloat = AppDimensions.circularIconSize,
        action: @escaping () -> Void
    ) -> some View {
        LiquidGlassCircularButton(size: size, action: action) {
            AnyView(
                VStack(spacing: 2) {
                    Circle()
                        .fill(Color(hex: "#1A1A1A"))
                        .frame(width: 8, height: 8)
                    
                    UnevenRoundedRectangle(
                        topLeadingRadius: 7,
                        bottomLeadingRadius: 3,
                        bottomTrailingRadius: 3,
                        topTrailingRadius: 7
                    )
                    .fill(Color(hex: "#1A1A1A"))
                    .frame(width: 17, height: 8)
                }
            )
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        LiquidGlassCircularButton.profile { }
        LiquidGlassCircularButton(systemName: "plus") { }
        LiquidGlassCircularButton(systemName: "pencil") { }
    }
    .padding(30)
    .background(Color.gray.opacity(0.3))
}
