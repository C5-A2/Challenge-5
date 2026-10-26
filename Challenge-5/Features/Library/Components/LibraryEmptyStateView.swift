//
//  LibraryEmptyStateView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI

/// Empty state view presented when the user hasn't bookmarked any looks yet.
public struct LibraryEmptyStateView: View {
    
    // MARK: - Properties
    
    public var onExploreOccasions: (() -> Void)? = nil
    public var onAddSampleLooks: (() -> Void)? = nil
    
    // MARK: - Initializer
    
    public init(
        onExploreOccasions: (() -> Void)? = nil,
        onAddSampleLooks: (() -> Void)? = nil
    ) {
        self.onExploreOccasions = onExploreOccasions
        self.onAddSampleLooks = onAddSampleLooks
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)
            
            // Stylized Bookmark Icon Container
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
                
                Image(systemName: "bookmark")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(AppColors.espressoTitle.opacity(0.75))
            }
            .padding(.bottom, 8)
            
            // Header & Description
            VStack(spacing: 8) {
                Text("No Saved Looks Yet")
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text("Looks you bookmark from your styling recommendations will appear here for future outfit inspiration.")
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.mutedCaption)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if let onAddSampleLooks {
                    Button(action: onAddSampleLooks) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Load Sample Looks")
                                .font(AppTypography.buttonLabel)
                        }
                        .foregroundStyle(AppColors.espressoTitle)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppColors.cardBackground)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                if let onExploreOccasions {
                    Button(action: onExploreOccasions) {
                        Text("Explore Occasions")
                            .font(AppTypography.buttonLabel)
                            .foregroundStyle(AppColors.espressoTitle)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding(.top, 12)
            
            Spacer(minLength: 60)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.canvasBackground.ignoresSafeArea()
        LibraryEmptyStateView(
            onExploreOccasions: { print("Explore tapped") },
            onAddSampleLooks: { print("Sample tapped") }
        )
    }
}
