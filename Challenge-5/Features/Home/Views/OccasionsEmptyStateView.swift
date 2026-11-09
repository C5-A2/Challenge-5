//
//  OccasionsEmptyStateView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Archive folder empty state view displayed when no occasions are scheduled yet.
struct OccasionsEmptyStateView: View {
    
    // MARK: - Callbacks
    
    var onAddOccasion: (() -> Void)? = nil
    
    // MARK: - Initializer
    
    init(onAddOccasion: (() -> Void)? = nil) {
        self.onAddOccasion = onAddOccasion
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            onAddOccasion?()
        } label: {
            ZStack(alignment: .bottom) {
                // Card Top / Inner Backplate Layer with Prompt Text
                cardBackplateLayer
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                
                // Frosted Metallic Folder Tab Cut-Out Layer
                folderTabOverlay
                    .frame(height: 152)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
            .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Subviews
    
    private var cardBackplateLayer: some View {
        ZStack(alignment: .top) {
            // Background gradient matching back of archive folder
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#D8D6D2"), location: 0.0),
                    .init(color: Color(hex: "#C6C3BD"), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Empty State Prompt Text (Centered at the top exposed portion)
            VStack(spacing: 6) {
                Text("Got somewhere to be?")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text("Tell us where you're headed, and let's find the\nperfect look for you.")
                    .font(AppTypography.caption)
                    .foregroundStyle(Color(hex: "#6B6761"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.top, 22)
            .padding(.horizontal, 20)
        }
    }
    
    private var folderTabOverlay: some View {
        ZStack {
            FolderTabShape(
                tabPosition: .leading,
                tabWidthFraction: 0.58,
                tabHeight: 26,
                cornerRadius: AppDimensions.cardCornerRadius
            )
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#D4D4D4"), location: 0.0),
                        .init(color: Color(hex: "#9E9E9E"), location: 0.35),
                        .init(color: Color(hex: "#565656"), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                FolderTabShape(
                    tabPosition: .leading,
                    tabWidthFraction: 0.58,
                    tabHeight: 26,
                    cornerRadius: AppDimensions.cardCornerRadius
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.canvasBackground.ignoresSafeArea()
        OccasionsEmptyStateView(
            onAddOccasion: { print("Add Occasion tapped") }
        )
    }
}
