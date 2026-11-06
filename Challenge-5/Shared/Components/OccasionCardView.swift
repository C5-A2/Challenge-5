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
    
    /// Maximum number of generated outfit avatars displayed side-by-side in the folder.
    /// If more looks are generated, the newest ones replace the oldest ones so the folder never overflows.
    private static let maxDisplayedOutfits = 5
    
    public let dayText: String
    public let monthText: String
    public let title: String
    public let subtitle: String
    public let tags: [String]
    public var backgroundImage: Image?
    public var outfitImagesData: [Data]
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
        outfitImagesData: [Data] = [],
        isPlaceholder: Bool = false,
        action: @escaping () -> Void
    ) {
        self.dayText = dayText
        self.monthText = monthText
        self.title = title
        self.subtitle = subtitle
        self.tags = tags
        self.backgroundImage = backgroundImage
        self.outfitImagesData = Array(outfitImagesData.suffix(Self.maxDisplayedOutfits))
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
        
        // Extract real generated outfit images sorted chronologically so newest replaces oldest when > 4
        let validLooks = occasion.generatedLooks.filter { look in
            guard let data = look.lookImageData, !data.isEmpty else { return false }
            return !OccasionOutputViewModel.isPlaceholderData(data, lookIndex: look.lookIndex)
        }
        let sortedLooks = validLooks.sorted { a, b in
            switch (a.imageGeneratedAt, b.imageGeneratedAt) {
            case let (dateA?, dateB?):
                return dateA < dateB
            case (nil, _?):
                return true
            case (_?, nil):
                return false
            case (nil, nil):
                return a.lookIndex < b.lookIndex
            }
        }
        self.outfitImagesData = Array(
            sortedLooks.compactMap(\.lookImageData).suffix(Self.maxDisplayedOutfits)
        )
        
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
    
    /// Top background gradient or custom background image, plus generated outfit avatars inside the folder.
    @ViewBuilder
    private var cardBackgroundLayer: some View {
        ZStack(alignment: .bottom) {
            if let backgroundImage {
                backgroundImage
                    .resizable()
                    .scaledToFill()
            } else {
                // Sisi Belakang (Back Layer): Linear Gradient #ECECEC (100%) -> #848484 (28%)
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#ECECEC"), location: 0.0),
                        .init(color: Color(hex: "#848484").opacity(0.28), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            
            if !outfitImagesData.isEmpty {
                generatedOutfitsLineup(isBlurred: false)
            }
        }
    }
    
    /// Renders up to 5 generated outfit avatars lined up tightly and large inside the folder card.
    private func generatedOutfitsLineup(isBlurred: Bool) -> some View {
        let count = outfitImagesData.count
        let itemWidth: CGFloat = {
            switch count {
            case 1: return 170
            case 2: return 156
            case 3: return 144
            case 4: return 132
            default: return 122
            }
        }()
        let spacing: CGFloat = {
            switch count {
            case 1: return 0
            case 2: return -68
            case 3: return -74
            case 4: return -72
            default: return -70
            }
        }()
        
        return HStack(alignment: .top, spacing: spacing) {
            ForEach(Array(outfitImagesData.enumerated()), id: \.offset) { idx, data in
                if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: itemWidth, height: 280, alignment: .top)
                        .offset(y: verticalOffset(for: idx, total: count))
                        .zIndex(zIndex(for: idx, total: count))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .blur(radius: isBlurred ? 12 : 0)
        .opacity(isBlurred ? 0.72 : 1.0)
    }
    
    private func verticalOffset(for index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 14 }
        switch total {
        case 2:
            return index == 0 ? 12 : 20
        case 3:
            return index == 1 ? 10 : 22
        case 4:
            return (index == 1 || index == 2) ? 10 : 24
        default:
            if index == 2 { return 10 }
            if index == 1 || index == 3 { return 18 }
            return 26
        }
    }
    
    private func zIndex(for index: Int, total: Int) -> Double {
        guard total > 2 else { return Double(index) }
        if total == 5 {
            if index == 2 { return 3.0 }
            if index == 1 || index == 3 { return 2.0 }
            return 1.0
        }
        // Center figures sit slightly in front of outer figures
        return (index == 1 || index == 2) ? 2.0 : 1.0
    }
    
    /// Lower metallic folder tab shape with directional arrow button and occasion metadata.
    private var folderTabOverlay: some View {
        let folderShape = FolderTabShape(
            tabPosition: .leading,
            tabWidthFraction: 0.62,
            tabHeight: 26,
            cornerRadius: AppDimensions.cardCornerRadius
        )
        
        return ZStack(alignment: .bottom) {
            // Folder shape fill with metallic silver gradient & frosted silhouette of outfits behind tab
            ZStack(alignment: .bottom) {
                // Frosted glass base material (lebih ringan agar lebih tembus pandang)
                folderShape
                    .fill(.ultraThinMaterial)
                    .opacity(0.50)
                
                // Sisi Depan (Front Tab): Warna tetap sama, transparansi dinaikkan (opacity diturunkan)
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#F0F0F0").opacity(0.48), location: 0.0),
                        .init(color: Color(hex: "#000000").opacity(0.38), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                if !outfitImagesData.isEmpty {
                    generatedOutfitsLineup(isBlurred: true)
                        .frame(height: 250)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 148)
            .clipShape(folderShape)
            .overlay(
                // Double layered stroke for luminous glass edge highlight
                ZStack {
                    folderShape
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.95), location: 0.0),
                                    .init(color: Color.white.opacity(0.70), location: 0.25),
                                    .init(color: Color.white.opacity(0.20), location: 0.70),
                                    .init(color: Color.white.opacity(0.40), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                    
                    folderShape
                        .stroke(Color.white.opacity(0.40), lineWidth: 0.5)
                        .blur(radius: 1)
                }
            )
            
            // Content Layout: Menempel rapat ke dasar kartu folder
            HStack(alignment: .bottom, spacing: 14) {
                if !isPlaceholder && !title.isEmpty {
                    // Date badge column
                    VStack(spacing: 0) {
                        Text(dayText)
                            .font(AppTypography.folderCardDayNumber)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(monthText.capitalized)
                            .font(AppTypography.folderCardMonth)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 52)
                    
                    // Title, subtitle/dresscode badge, and vision tags
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(AppTypography.folderCardTitle)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .offset(y: subtitle.isEmpty ? 3 : 0)
                        
                        if !subtitle.isEmpty {
                            dresscodeBadge(subtitle)
                                .lineLimit(1)
                        } else {
                            // Spacer penyeimbang agar judul tetap berada tepat di tengah ketinggian kolom tanggal
                            Spacer()
                                .frame(height: 2)
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
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: subtitle.isEmpty ? .leading : .bottomLeading)
                }
                
                // Circular directional action button: dinaikkan ke atas bahu kanan tab agar teks judul leluasa melebar
                arrowButton
                    .padding(.bottom, 62)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(height: 148, alignment: .bottom)
        }
    }
    
    /// Liquid glass capsule badge for dresscode using the reusable shared component.
    @ViewBuilder
    private func dresscodeBadge(_ text: String) -> some View {
        LiquidGlassBadge(text)
    }
    
    /// Circular black button with white diagonal arrow (arrow.up.right).
    private var arrowButton: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: 39, height: 39)
                .shadow(color: .black.opacity(0.32), radius: 6, x: 0, y: 3)
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 17, weight: .bold))
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
            dayText: "20",
            monthText: "Oct",
            title: "Inaugurasi",
            subtitle: "Performative Office Worker",
            tags: [],
            outfitImagesData: [1, 2, 3, 4].compactMap { UIImage(named: "mock_result_\($0)")?.pngData() }
        ) { }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.canvasBackground)
}
