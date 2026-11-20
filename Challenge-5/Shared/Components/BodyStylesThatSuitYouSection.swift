//
//  BodyStylesThatSuitYouSection.swift
//  Challenge-5
//
//  Created by Antigravity on 20/11/26.
//

import SwiftUI

/// Section displaying visual garment cuts and styling recommendations that suit the user's body shape.
/// Features horizontal scrolling shelves of garment cards grouped by category
/// (e.g., Necklines, Sleeves, Bottoms, Skirts & Dresses, Shorts).
public struct BodyStylesThatSuitYouSection: View {
    public let bodyType: BodyType
    public var title: String = "Styles that suits you"

    public init(bodyType: BodyType, title: String = "Styles that suits you") {
        self.bodyType = bodyType
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Main Section Title
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            // Categories (Necklines, Sleeves, Bottoms, etc.)
            ForEach(bodyType.styleRecommendations) { category in
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 12) {
                            ForEach(category.items) { item in
                                BodyStyleGarmentCard(item: item)
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

/// Square card displaying a single garment cut recommendation with its name below.
public struct BodyStyleGarmentCard: View {
    public let item: StyleGarmentItem

    public init(item: StyleGarmentItem) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Rounded Square Card
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )

                if let assetName = item.assetName,
                   UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                } else {
                    Image(systemName: item.systemFallbackIcon)
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Color(hex: "#3A3A3C").opacity(0.8))
                }
            }
            .frame(width: 74, height: 74)

            // Garment Cut Title
            Text(item.name)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .frame(width: 76, alignment: .top)
        }
    }
}

#Preview {
    ScrollView {
        BodyStylesThatSuitYouSection(bodyType: .invertedTriangle)
            .padding()
            .background(Color(hex: "#F3F3F5"))
    }
}
