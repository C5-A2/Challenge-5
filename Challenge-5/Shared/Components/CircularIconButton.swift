//
//  CircularIconButton.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

/// Deprecated / Unified: All circular icon buttons across the app now use the liquid glass visual style.
/// This alias delegates directly to `LiquidGlassCircularButton` to preserve API compatibility
/// while standardizing on the reflective, translucent liquid glass material design.
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
        LiquidGlassCircularButton(
            systemName: systemName,
            isFilled: isFilled,
            isEnabled: isEnabled,
            action: action
        )
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
    .padding(24)
    .background(Color.gray.opacity(0.2))
}
