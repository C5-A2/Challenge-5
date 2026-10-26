//
//  OccasionsEmptyStateView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Clean empty state view displayed when no occasions are scheduled yet (no card).
struct OccasionsEmptyStateView: View {
    
    // MARK: - Callbacks
    
    var onAddOccasion: (() -> Void)? = nil
    
    // MARK: - Initializer
    
    init(onAddOccasion: (() -> Void)? = nil) {
        self.onAddOccasion = onAddOccasion
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 32)
            
            // Stylized Icon Container
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(AppColors.espressoTitle.opacity(0.75))
            }
            .padding(.bottom, 4)
            
            // Header & Description
            VStack(spacing: 8) {
                Text("No Occasions Yet")
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text("Tap the + button below to add an event or celebration and get personalized outfit styling.")
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.mutedCaption)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }
            
            if let onAddOccasion {
                Button(action: onAddOccasion) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Occasion")
                            .font(AppTypography.buttonLabel)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AppColors.primaryBlack)
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
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
