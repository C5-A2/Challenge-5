//
//  GuideDoDontCard.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public struct GuideDoDontCard: View {
    
    // MARK: - Properties
    public let image: Image
    public let label: String
    public let isDo: Bool
    
    // MARK: - Initializer
    public init(
        image: Image,
        label: String,
        isDo: Bool
    ) {
        self.image = image
        self.label = label
        self.isDo = isDo
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                
                Image(systemName: isDo ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(isDo ? .green : .red)
                    .offset(x: 4, y: -4)
            }
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.bodyText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    HStack {
        GuideDoDontCard(
            image: Image(systemName: "person.fill"),
            label: "Face the Camera\nDirectly",
            isDo: true
        )
        GuideDoDontCard(
            image: Image(systemName: "person.fill.turn.right"),
            label: "Tilt or Angle\nYour Body",
            isDo: false
        )
    }
    .padding()
}
