//
//  LibraryCardView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI

/// Individual outfit look card rendered inside the asymmetric staggered grid.
///
/// Features the blue thumbnail card on top, and garment specifications (name, material,
/// color bullet dot, and options ellipsis) directly below the card matching Sketch design specs.
public struct LibraryCardView: View {
    
    // MARK: - Properties
    
    public let look: SavedLookItem
    public var onSelect: () -> Void
    public var onToggleBookmark: () -> Void
    
    // MARK: - Internal Animation State
    
    @State private var isPressed: Bool = false
    
    // MARK: - Initializer
    
    public init(
        look: SavedLookItem,
        onSelect: @escaping () -> Void,
        onToggleBookmark: @escaping () -> Void
    ) {
        self.look = look
        self.onSelect = onSelect
        self.onToggleBookmark = onToggleBookmark
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Top: Blue Card Container with Bookmark Button
                ZStack(alignment: .topTrailing) {
                    AsyncLookThumbnailView(
                        imageData: look.lookImageData,
                        assetImageName: look.assetImageName,
                        contentMode: .fill
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius, style: .continuous)
                            .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                    
                    // Top-trailing Bookmark Toggle Button
                    BookmarkToggleButton(
                        isBookmarked: Binding(
                            get: { look.isBookmarked },
                            set: { _ in onToggleBookmark() }
                        ),
                        style: .glassmorphicOverlay,
                        size: 32,
                        iconSize: 14,
                        activeColor: AppColors.espressoTitle
                    )
                    .padding(10)
                }
                
                // Bottom: Keterangan garment persis di bawah card biru
                garmentDescriptionView
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(CardPressButtonStyle(isPressed: $isPressed))
    }
    
    // MARK: - Garment Description View (Matches Sketch media_1793008898076_aaaa761a)
    
    private var garmentDescriptionView: some View {
        let primaryGarment = look.garments.first
        let title = primaryGarment?.name ?? look.occasionTitle
        let material = primaryGarment?.material ?? look.dresscode
        let colorName = primaryGarment?.colorName
        let hexColor = primaryGarment?.hexColor ?? "#1C1C1E"
        
        return VStack(alignment: .leading, spacing: 3) {
            // Row 1: Garment Title ("Polo") and Ellipsis ("...")
            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.bodyText)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.mutedCaption)
            }
            
            // Row 2: Garment Material ("french terry Cotton")
            Text(material)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppColors.mutedCaption)
                .lineLimit(1)
            
            // Row 3: Color Bullet Dot & Name ("● Black")
            if let colorName, !colorName.isEmpty {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: hexColor))
                        .frame(width: 7, height: 7)
                    
                    Text(colorName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppColors.bodyText)
                }
                .padding(.top, 1)
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }
    
    // MARK: - Computed Dimensions
    
    private var cardHeight: CGFloat {
        // Base width standard: ~165pt on typical iPhone. Multiply by ratio for asymmetric staggered feel
        let baseHeight: CGFloat = 200
        return baseHeight * look.cardHeightRatio
    }
}

// MARK: - Card Press Button Style

private struct CardPressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview {
    HStack(alignment: .top, spacing: 14) {
        LibraryCardView(
            look: SavedLookItem.samples[0],
            onSelect: { print("Selected card 0") },
            onToggleBookmark: { print("Toggled bookmark 0") }
        )
        
        LibraryCardView(
            look: SavedLookItem.samples[1],
            onSelect: { print("Selected card 1") },
            onToggleBookmark: { print("Toggled bookmark 1") }
        )
    }
    .padding()
    .background(AppColors.canvasBackground)
}
