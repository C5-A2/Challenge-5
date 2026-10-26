//
//  AsyncLookThumbnailView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Asynchronous thumbnail image loader for saved look cards in the Library.
///
/// Decodes binary image data off the main thread, caches decoded UIImages,
/// and displays a smooth placeholder with `AppColors.libraryCardPlaceholder`
/// during loading or in Lofi / placeholder state.
public struct AsyncLookThumbnailView: View {
    
    // MARK: - Properties
    
    public let imageData: Data?
    public var assetImageName: String? = nil
    public var contentMode: ContentMode = .fill
    public var showPlaceholderIcon: Bool = true
    
    // MARK: - State
    
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    
    // In-memory cache for decoded images
    private static let imageCache = NSCache<NSString, UIImage>()
    
    // MARK: - Initializer
    
    public init(
        imageData: Data?,
        assetImageName: String? = nil,
        contentMode: ContentMode = .fill,
        showPlaceholderIcon: Bool = false
    ) {
        self.imageData = imageData
        self.assetImageName = assetImageName
        self.contentMode = contentMode
        self.showPlaceholderIcon = showPlaceholderIcon
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            } else if let assetImageName, let uiImage = UIImage(named: assetImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholderView
            }
        }
        .task(id: imageData) {
            await loadImage()
        }
    }
    
    // MARK: - Placeholder View
    
    private var placeholderView: some View {
        // Clean solid placeholder color token matching Figma blue `#536493`
        AppColors.libraryCardPlaceholder
    }
    
    // MARK: - Async Image Loading
    
    private func loadImage() async {
        guard let imageData, !imageData.isEmpty else {
            loadedImage = nil
            return
        }
        
        let cacheKey = NSString(string: "\(imageData.hashValue)")
        if let cached = Self.imageCache.object(forKey: cacheKey) {
            self.loadedImage = cached
            return
        }
        
        isLoading = true
        
        // Decode off main actor
        let decoded = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            UIImage(data: imageData)
        }.value
        
        if let decoded {
            Self.imageCache.setObject(decoded, forKey: cacheKey)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.loadedImage = decoded
                    self.isLoading = false
                }
            }
        } else {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        AsyncLookThumbnailView(imageData: nil)
            .frame(width: 140, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        
        AsyncLookThumbnailView(imageData: nil, showPlaceholderIcon: false)
            .frame(width: 140, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
    }
    .padding()
    .background(AppColors.canvasBackground)
}
