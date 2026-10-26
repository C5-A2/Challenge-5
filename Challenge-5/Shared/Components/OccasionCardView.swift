//
//  OccasionCardView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Signature frosted glass occasion card with the archive folder cut-out overlay.
/// As seen on the Occasions Home tab (Image 3 in design specs).
public struct OccasionCardView: View {
    
    // MARK: - Properties
    public let dayText: String
    public let monthText: String
    public let title: String
    public let subtitle: String
    public let tags: [String]
    public var backgroundImage: Image?
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        dayText: String = "13",
        monthText: String = "Oct",
        title: String,
        subtitle: String,
        tags: [String] = [],
        backgroundImage: Image? = nil,
        action: @escaping () -> Void
    ) {
        self.dayText = dayText
        self.monthText = monthText
        self.title = title
        self.subtitle = subtitle
        self.tags = tags
        self.backgroundImage = backgroundImage
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                // Background photo or subtle placeholder
                ZStack {
                    if let backgroundImage {
                        backgroundImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "#E8E2D9"), Color(hex: "#D0C7B9")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipped()
                
                // Frosted glass bottom container with folder tab cut
                ZStack(alignment: .topLeading) {
                    FolderTabShape(
                        tabPosition: .leading,
                        tabWidthFraction: 0.55,
                        tabHeight: 28,
                        cornerRadius: AppDimensions.cardCornerRadius
                    )
                    .fill(AppColors.cardBackground.opacity(0.88))
                    .overlay(
                        FolderTabShape(
                            tabPosition: .leading,
                            tabWidthFraction: 0.55,
                            tabHeight: 28,
                            cornerRadius: AppDimensions.cardCornerRadius
                        )
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                    
                    // Card contents
                    HStack(alignment: .top, spacing: 16) {
                        // Date badge column
                        VStack(spacing: 0) {
                            Text(dayText)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(AppColors.espressoTitle)
                            Text(monthText)
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.espressoTitle)
                        }
                        .frame(width: 48)
                        .padding(.top, 4)
                        
                        // Title, subtitle, and tags
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(AppTypography.cardHeadline)
                                .foregroundStyle(AppColors.espressoTitle)
                                .lineLimit(1)
                            
                            Text(subtitle)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.mutedCaption)
                                .lineLimit(1)
                            
                            if !tags.isEmpty {
                                HStack(spacing: 6) {
                                    ForEach(tags, id: \.self) { tag in
                                        TagChip(tag, isFrosted: true)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }
                .frame(height: 140)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
            .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        OccasionCardView(
            dayText: "13",
            monthText: "Oct",
            title: "Cousin's Wedding",
            subtitle: "Clean look, elegant, classy",
            tags: ["white dress", "satin"]
        ) { }
    }
    .padding()
    .background(AppColors.canvasBackground)
}
