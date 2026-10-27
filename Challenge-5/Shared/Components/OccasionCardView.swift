//
//  OccasionCardView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Signature metallic folder card with archive tab cut-out overlay and directional action button.
/// Exactly matches the Occasions Home tab design specification.
public struct OccasionCardView: View {
    
    // MARK: - Properties
    
    public let dayText: String
    public let monthText: String
    public let title: String
    public let subtitle: String
    public let tags: [String]
    public var backgroundImage: Image?
    public let isPlaceholder: Bool
    public let action: () -> Void
    
    // MARK: - Initializers
    
    public init(
        dayText: String = "13",
        monthText: String = "Oct",
        title: String = "",
        subtitle: String = "",
        tags: [String] = [],
        backgroundImage: Image? = nil,
        isPlaceholder: Bool = false,
        action: @escaping () -> Void
    ) {
        self.dayText = dayText
        self.monthText = monthText
        self.title = title
        self.subtitle = subtitle
        self.tags = tags
        self.backgroundImage = backgroundImage
        self.isPlaceholder = isPlaceholder
        self.action = action
    }
    
    init(
        occasion: OccasionItem,
        action: @escaping () -> Void
    ) {
        self.dayText = occasion.dayText
        self.monthText = occasion.monthText
        self.title = occasion.title
        self.subtitle = occasion.dresscode
        // Chips are omitted for now; reserved for tags from recommended styling results in the future
        self.tags = []
        self.backgroundImage = nil
        self.isPlaceholder = false
        self.action = action
    }
    
    public static func placeholder(action: @escaping () -> Void) -> OccasionCardView {
        OccasionCardView(
            title: "",
            subtitle: "",
            tags: [],
            isPlaceholder: true,
            action: action
        )
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                // Card Top / Background Layer
                cardBackgroundLayer
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipped()
                
                // Frosted Silver Folder Tab Cut-Out Layer
                folderTabOverlay
                    .frame(height: 148)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews
    
    /// Top background gradient or custom background image.
    @ViewBuilder
    private var cardBackgroundLayer: some View {
        if let backgroundImage {
            backgroundImage
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [
                    Color(hex: "#E0E0E0"),
                    Color(hex: "#CACACA")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    /// Lower metallic folder tab shape with directional arrow button and occasion metadata.
    private var folderTabOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // Folder shape fill with metallic silver gradient
            FolderTabShape(
                tabPosition: .leading,
                tabWidthFraction: 0.62,
                tabHeight: 26,
                cornerRadius: AppDimensions.cardCornerRadius
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "#D2D2D2"),
                        Color(hex: "#5E5E5E")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                FolderTabShape(
                    tabPosition: .leading,
                    tabWidthFraction: 0.62,
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
            
            // Content Layout
            HStack(alignment: .top, spacing: 14) {
                if !isPlaceholder && !title.isEmpty {
                    // Date badge column
                    VStack(spacing: 0) {
                        Text(dayText)
                            .font(AppTypography.scheduleDayNumber)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(monthText.uppercased())
                            .font(AppTypography.scheduleMonth)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 56)
                    .padding(.top, 4)
                    
                    // Title, subtitle, and vision tags
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppTypography.cardHeadline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(AppTypography.caption)
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                        }
                        
                        if !tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(tags.prefix(3), id: \.self) { tag in
                                    TagChip(tag, isFrosted: true)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                
                Spacer()
                
                // Circular directional action button (top-right of shoulder)
                arrowButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }
    
    /// Circular black button with white diagonal arrow (arrow.up.right).
    private var arrowButton: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Previews

#Preview("Mockup Placeholder (Exact Figma Match)") {
    VStack(spacing: 20) {
        OccasionCardView.placeholder { }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.canvasBackground)
}

#Preview("Populated Occasion Card") {
    VStack(spacing: 20) {
        OccasionCardView(
            dayText: "28",
            monthText: "Oct",
            title: "Jjj",
            subtitle: "Clean look, elegant, classy",
            tags: []
        ) { }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        
        OccasionCardView(
            dayText: "13",
            monthText: "Oct",
            title: "Cousin's Wedding",
            subtitle: "Clean look, elegant, classy",
            tags: []
        ) { }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.canvasBackground)
}
