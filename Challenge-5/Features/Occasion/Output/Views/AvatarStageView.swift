//
//  AvatarStageView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI
import UIKit

struct AvatarStageView: View {
    
    var viewModel: OccasionOutputViewModel
    var onPlaygroundTap: (() -> Void)? = nil
    var isProcessingPlayground: Bool = false
    
    @State private var dragOffset: CGFloat = 0
    
    private let cardSpacing: CGFloat = 126
    
    init(
        viewModel: OccasionOutputViewModel,
        onPlaygroundTap: (() -> Void)? = nil,
        isProcessingPlayground: Bool = false
    ) {
        self.viewModel = viewModel
        self.onPlaygroundTap = onPlaygroundTap
        self.isProcessingPlayground = isProcessingPlayground
    }
    
    
    var body: some View {
        VStack(spacing: 8) {
            carouselTrack
                .frame(height: 330)
            
            if viewModel.looks.count > 1 {
                nativePageControlDots
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }
    
    
    private var carouselTrack: some View {
        ZStack {
            ForEach(0..<viewModel.totalCarouselCount, id: \.self) { index in
                cardItem(for: index)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func cardItem(for index: Int) -> some View {
        let progress = dragOffset / cardSpacing
        let relativeIndex = CGFloat(index - viewModel.selectedLookIndex) + progress
        
        if abs(relativeIndex) <= 1.85 {
            let centerFactor = max(0, 1.0 - abs(relativeIndex))
            let isCenter = centerFactor > 0.65
            
            let width: CGFloat = 110 + centerFactor * (190 - 110)
            let height: CGFloat = 245 + centerFactor * (455 - 245)
            let opacity: CGFloat = abs(relativeIndex) <= 1.0
                ? 1.0
                : max(0, 1.0 - (abs(relativeIndex) - 1.0) * 1.5)
            let saturation: Double = isCenter ? 1.0 : 0.65
            let xOffset = relativeIndex * cardSpacing
            
            ZStack(alignment: .center) {
                if viewModel.isLookLoading(at: index) {
                    loadingRingCard(for: index, width: width, height: height, isCenter: isCenter)
                } else if index < viewModel.looks.count,
                   let data = viewModel.looks[index].lookImageData,
                   !OccasionOutputViewModel.isPlaceholderData(data, lookIndex: viewModel.looks[index].lookIndex),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .saturation(saturation)
                        .frame(width: width, height: height)
                        .shadow(
                            color: Color.black.opacity(isCenter ? 0.08 : 0.02),
                            radius: isCenter ? 8 : 2,
                            y: isCenter ? 4 : 1
                        )
                } else {
                    playgroundPlaceholderView(for: index, isCenter: isCenter, width: width, height: height)
                        .saturation(saturation)
                        .frame(width: width, height: height)
                }
            }
            .frame(width: width, height: height)
            .offset(x: xOffset)
            .opacity(opacity)
            .zIndex(Double(centerFactor))
            .onTapGesture {
                let isUngenerated = index >= viewModel.looks.count 
                    || viewModel.looks[index].lookImageData == nil 
                    || OccasionOutputViewModel.isPlaceholderData(viewModel.looks[index].lookImageData ?? Data(), lookIndex: viewModel.looks[index].lookIndex)
                if isCenter && isUngenerated {
                    onPlaygroundTap?()
                } else {
                    handleCardTap(at: index)
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadingRingCard(for index: Int, width: CGFloat, height: CGFloat, isCenter: Bool) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppColors.espressoTitle.opacity(0.12), lineWidth: 3.5)
                    .frame(width: isCenter ? 54 : 36, height: isCenter ? 54 : 36)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.espressoTitle))
                    .scaleEffect(isCenter ? 1.3 : 0.85)
            }
            
            if isCenter {
                VStack(spacing: 4) {
                    Text("Curating Look \(index + 1)...")
                        .font(AppTypography.sfProSemiboldExtended(size: 14))
                        .foregroundStyle(AppColors.espressoTitle)
                        .multilineTextAlignment(.center)
                    
                    Text("Exploring silhouettes")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppColors.mutedCaption)
                }
                .padding(.horizontal, 10)
                .transition(.opacity)
            }
        }
        .frame(width: width, height: height, alignment: .center)
    }
    
    // MARK: - Image Playground Placeholder View (Cardless)
    
    @ViewBuilder
    private func playgroundPlaceholderView(for index: Int, isCenter: Bool, width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .center) {
            // Icon Orang (Avatar Silhouette) - dibuat proporsional dan pas di atas podium
            Image(systemName: "figure.stand")
                .resizable()
                .scaledToFit()
                .foregroundStyle(AppColors.espressoTitle.opacity(isCenter ? 0.16 : 0.06))
                .frame(height: height * 0.54)
                .offset(y: 4)
            
            if isCenter {
                VStack(spacing: 12) {
                    // Logo Image Playground Default
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#FF5E7E").opacity(0.25),
                                        Color(hex: "#8B5CF6").opacity(0.25),
                                        Color(hex: "#38BDF8").opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)
                        
                        Image(systemName: "apple.image.playground")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#8B5CF6"),
                                        Color(hex: "#EC4899"),
                                        Color(hex: "#F59E0B")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: Color.black.opacity(0.10), radius: 6, y: 2)
                    
                    // Tombol Generate
                    Button {
                        onPlaygroundTap?()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 11, weight: .bold))
                            Text("Generate Look")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppColors.espressoTitle)
                                .shadow(color: .black.opacity(0.20), radius: 6, y: 2)
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .offset(y: 6)
            }
        }
    }
    
    

    
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.width
                
                if viewModel.selectedLookIndex == 0 && translation > 0 {
                    dragOffset = translation * 0.25
                } else if viewModel.selectedLookIndex == viewModel.totalCarouselCount - 1 && translation < 0 {
                    dragOffset = translation * 0.25
                } else {
                    dragOffset = translation
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 40
                let translation = value.translation.width
                
                if translation < -threshold && viewModel.selectedLookIndex < viewModel.totalCarouselCount - 1 {
                    viewModel.goToNextLook()
                } else if translation > threshold && viewModel.selectedLookIndex > 0 {
                    viewModel.goToPreviousLook()
                }
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
    }
    
    private func handleCardTap(at index: Int) {
        guard index != viewModel.selectedLookIndex else { return }
        if index == viewModel.selectedLookIndex - 1 {
            viewModel.goToPreviousLook()
        } else if index == viewModel.selectedLookIndex + 1 {
            viewModel.goToNextLook()
        } else {
            viewModel.selectLook(at: index)
        }
    }
    
    // MARK: - Native Apple PageControl Dots
    
    private var nativePageControlDots: some View {
        NativePageControl(
            numberOfPages: viewModel.looks.count,
            currentPage: Binding(
                get: { viewModel.selectedLookIndex },
                set: { newIndex in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectLook(at: newIndex)
                    }
                }
            )
        )
        .frame(height: 20)
    }
                }
            )
        )
        .frame(height: 20)
    }
}

// MARK: - Native UIPageControl Wrapper

private struct NativePageControl: UIViewRepresentable {
    var numberOfPages: Int
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = numberOfPages
        control.currentPage = currentPage
        control.pageIndicatorTintColor = UIColor(white: 0.0, alpha: 0.22)
        control.currentPageIndicatorTintColor = UIColor(white: 0.1, alpha: 0.90)
        control.backgroundStyle = .minimal
        control.allowsContinuousInteraction = false
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return control
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = numberOfPages
        uiView.currentPage = currentPage
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NativePageControl
        
        init(_ parent: NativePageControl) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: UIPageControl) {
            parent.currentPage = sender.currentPage
        }
    }
}

#Preview {
    AvatarStageView(viewModel: .mock())
        .background(AppColors.canvasBackground)
}
