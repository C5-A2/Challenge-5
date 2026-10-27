//
//  BodyTypeBadge.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Capsule badge displaying analyzed body type and quick proportion metrics.
/// Tapping it expands the body shape fit details modal.
public struct BodyTypeBadge: View {
    
    // MARK: - Properties
    public let bodyTypeName: String
    public var metricsText: String?
    public let action: () -> Void
    
    // MARK: - Initializer
    public init(
        bodyTypeName: String = "Inverted Triangle",
        metricsText: String? = "Shoulder: 52 cm",
        action: @escaping () -> Void
    ) {
        self.bodyTypeName = bodyTypeName
        self.metricsText = metricsText
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.espressoTitle)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(bodyTypeName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    if let metricsText {
                        Text(metricsText)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(AppColors.mutedCaption)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.mutedCaption)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppColors.cardBackground)
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    BodyTypeBadge(
        bodyTypeName: "Inverted Triangle",
        metricsText: "Shoulder: 52 cm • Waist: 38 cm"
    ) { }
    .padding()
}
