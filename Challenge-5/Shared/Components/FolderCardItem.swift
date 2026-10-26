//
//  FolderCardItem.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// A reusable glassmorphic physical-folder card with a colored tab cut-out.
/// Used in the Profile screen to display profile sections (Color Season, Body Type, Measurements).
public struct FolderCardItem: View {
    
    // MARK: - Properties
    public let title: String
    public let subtitle: String?
    public let statusText: String
    public let isConfigured: Bool
    public let tabColor: Color
    public let tabPosition: FolderTabShape.TabPosition
    public let iconSystemName: String?
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        title: String,
        subtitle: String? = nil,
        statusText: String = "Not Set",
        isConfigured: Bool = false,
        tabColor: Color = AppColors.pastelPeach,
        tabPosition: FolderTabShape.TabPosition = .leading,
        iconSystemName: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.statusText = statusText
        self.isConfigured = isConfigured
        self.tabColor = tabColor
        self.tabPosition = tabPosition
        self.iconSystemName = iconSystemName
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
    }
    
    private var cardContent: some View {
        ZStack(alignment: .topLeading) {
            // Background folder shape
            FolderTabShape(
                tabPosition: tabPosition,
                tabWidthFraction: 0.48,
                tabHeight: 34,
                cornerRadius: AppDimensions.folderTabRadius
            )
            .fill(Color.white)
            .overlay(
                FolderTabShape(
                    tabPosition: tabPosition,
                    tabWidthFraction: 0.48,
                    tabHeight: 34,
                    cornerRadius: AppDimensions.folderTabRadius
                )
                .stroke(AppColors.subtleBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            
            // Colored tab accent fill
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    if let iconSystemName {
                        Image(systemName: iconSystemName)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(AppColors.espressoTitle)
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background(
                    tabColor.opacity(0.85)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
                
                Spacer()
            }
            
            // Main card content area
            VStack(alignment: .leading, spacing: 8) {
                Spacer().frame(height: 28)
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppTypography.cardHeadline)
                            .foregroundStyle(AppColors.espressoTitle)
                        
                        if let subtitle {
                            Text(subtitle)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.mutedCaption)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isConfigured ? AppColors.lightingOptimal : AppColors.mutedCaption.opacity(0.5))
                                .frame(width: 8, height: 8)
                            
                            Text(statusText)
                                .font(AppTypography.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(isConfigured ? AppColors.espressoTitle : AppColors.mutedCaption)
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.mutedCaption)
                        .padding(10)
                        .background(AppColors.canvasBackground)
                        .clipShape(Circle())
                }
            }
            .padding(AppDimensions.cardInternalPadding)
        }
        .frame(height: 130)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        FolderCardItem(
            title: "Color Season",
            subtitle: "Personalized palette based on skin undertones",
            statusText: "Not Set",
            isConfigured: false,
            tabColor: AppColors.pastelPeach,
            tabPosition: .leading,
            iconSystemName: "paintpalette"
        ) { }
        
        FolderCardItem(
            title: "Body Type",
            subtitle: "Silhouettes and proportion analysis",
            statusText: "Inverted Triangle",
            isConfigured: true,
            tabColor: AppColors.pastelSage,
            tabPosition: .trailing,
            iconSystemName: "figure.stand"
        ) { }
    }
    .padding()
    .background(AppColors.canvasBackground)
}
