//
//  ImageSourceActionSheet.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public enum ImageSourceOption: String, CaseIterable, Identifiable, Sendable {
    case camera = "Camera"
    case photoLibrary = "Open from Photos"
    case savedLibrary = "From Library"
    
    public var id: String { rawValue }
    
    public var iconSystemName: String {
        switch self {
        case .camera: return "camera"
        case .photoLibrary: return "photo.on.rectangle"
        case .savedLibrary: return "bookmark"
        }
    }
}

public struct ImageSourceMenu: View {
    
    // MARK: - Properties
    public let onSelect: (ImageSourceOption) -> Void
    
    // MARK: - Initializer
    public init(onSelect: @escaping (ImageSourceOption) -> Void) {
        self.onSelect = onSelect
    }
    
    // MARK: - Body
    public var body: some View {
        Menu {
            ForEach(ImageSourceOption.allCases) { option in
                Button {
                    onSelect(option)
                } label: {
                    Label(option.rawValue, systemImage: option.iconSystemName)
                }
            }
        } label: {
            Image(systemName: "camera")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.bodyText)
                .frame(width: 36, height: 36)
                .background(AppColors.cardBackground)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
    }
}

// MARK: - Preview
#Preview {
    ImageSourceMenu { selectedOption in
        print("Selected: \(selectedOption.rawValue)")
    }
    .padding()
}
