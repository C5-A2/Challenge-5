//
//  PhotoReviewLayout.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public struct PhotoReviewLayout: View {
    
    // MARK: - Types
    public struct ChecklistItem: Identifiable, Sendable {
        public let id = UUID()
        public let iconSystemName: String
        public let isPassing: Bool
        
        public init(iconSystemName: String, isPassing: Bool) {
            self.iconSystemName = iconSystemName
            self.isPassing = isPassing
        }
    }
    
    // MARK: - Properties
    public let capturedImage: UIImage
    public let checklistItems: [ChecklistItem]
    public let onRetake: () -> Void
    public let onUsePhoto: () -> Void
    
    // MARK: - Initializer
    public init(
        capturedImage: UIImage,
        checklistItems: [ChecklistItem],
        onRetake: @escaping () -> Void,
        onUsePhoto: @escaping () -> Void
    ) {
        self.capturedImage = capturedImage
        self.checklistItems = checklistItems
        self.onRetake = onRetake
        self.onUsePhoto = onUsePhoto
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: AppDimensions.sectionSpacing) {
            Image(uiImage: capturedImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            
            VStack(spacing: AppDimensions.elementSpacing) {
                Text("Check:")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.bodyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: AppDimensions.elementSpacing) {
                    ForEach(checklistItems) { item in
                        VStack(spacing: 6) {
                            Image(systemName: item.iconSystemName)
                                .font(.system(size: 24))
                                .frame(height: 40)
                                .foregroundStyle(AppColors.bodyText)
                            
                            Image(systemName: item.isPassing ? "checkmark" : "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(item.isPassing ? .green : .red)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            
            Spacer()
            
            HStack {
                Button("Retake", action: onRetake)
                    .font(AppTypography.buttonLabel)
                    .foregroundStyle(AppColors.bodyText)
                
                Spacer()
                
                Button("Use Photo", action: onUsePhoto)
                    .font(AppTypography.buttonLabel)
                    .foregroundStyle(AppColors.primaryBlue)
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoReviewLayout(
        capturedImage: UIImage(systemName: "person.crop.rectangle") ?? UIImage(),
        checklistItems: [
            .init(iconSystemName: "face.smiling", isPassing: true),
            .init(iconSystemName: "sun.max", isPassing: true),
            .init(iconSystemName: "camera", isPassing: false)
        ],
        onRetake: { },
        onUsePhoto: { }
    )
}
