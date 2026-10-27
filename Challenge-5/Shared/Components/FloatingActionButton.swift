//
//  FloatingActionButton.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Floating Action Button (FAB) positioned at the bottom trailing corner of screens.
/// Seen on the Occasions Home tab for creating a new occasion.
public struct FloatingActionButton: View {
    
    // MARK: - Properties
    public let iconSystemName: String
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        iconSystemName: String = "plus",
        action: @escaping () -> Void
    ) {
        self.iconSystemName = iconSystemName
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            Image(systemName: iconSystemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(
                    width: AppDimensions.floatingButtonSize,
                    height: AppDimensions.floatingButtonSize
                )
                .background(AppColors.primaryDark)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppColors.canvasBackground.ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton { }
                    .padding()
            }
        }
    }
}
