//
//  AvatarStageView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI

struct AvatarStageView: View {
    
    
    var viewModel: OccasionOutputViewModel
    
    @State private var dragOffset: CGFloat = 0
    
    private let cardSpacing: CGFloat = 126
    
    
    init(viewModel: OccasionOutputViewModel) {
        self.viewModel = viewModel
    }
    
    
    var body: some View {
        VStack(spacing: 0) {

            carouselTrack
                .frame(height: 420)
            
            groundShadowAndPagination
                .offset(y: -60)
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }
    
    
    private var carouselTrack: some View {
        ZStack {
            ForEach(0..<viewModel.looks.count, id: \.self) { index in
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
            let opacity = abs(relativeIndex) <= 1.0
                ? 0.90 + centerFactor * 0.10
                : max(0, 0.90 - (abs(relativeIndex) - 1.0) * 1.5)
            let xOffset = relativeIndex * cardSpacing
            
            ZStack(alignment: .center) {

                modelImageView(for: index)
                    .frame(width: width, height: height)
                    .shadow(
                        color: Color.black.opacity(isCenter ? 0.08 : 0.03),
                        radius: isCenter ? 8 : 3,
                        y: isCenter ? 4 : 2
                    )
            }
            .frame(width: width, height: height)
            .offset(x: xOffset)
            .opacity(opacity)
            .zIndex(Double(centerFactor))
            .onTapGesture {
                handleCardTap(at: index)
            }
        }
    }
    
    
    private func modelImageView(for index: Int) -> some View {
        let name = assetName(for: index)
        return Group {
            if let uiImage = UIImage(named: name) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                fallbackSilhouette(for: index)
            }
        }
    }
    
    private func assetName(for index: Int) -> String {
        let specificName = "mock_result_\(index + 1)"
        if UIImage(named: specificName) != nil {
            return specificName
        }
        let fallbackAssets = ["mock_result_1", "mock_result_2", "mock_result_3"]
        return fallbackAssets[index % fallbackAssets.count]
    }
    
    private func fallbackSilhouette(for index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#536493"))
            
            Image(systemName: "figure.stand")
                .font(.system(size: 76, weight: .light))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.width
                
                if viewModel.selectedLookIndex == 0 && translation > 0 {
                    dragOffset = translation * 0.25
                } else if viewModel.selectedLookIndex == viewModel.looks.count - 1 && translation < 0 {
                    dragOffset = translation * 0.25
                } else {
                    dragOffset = translation
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 40
                let translation = value.translation.width
                
                if translation < -threshold && viewModel.selectedLookIndex < viewModel.looks.count - 1 {
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
    
    
    private var groundShadowAndPagination: some View {
        ZStack {

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.black.opacity(0.20), Color.black.opacity(0.04), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 95
                    )
                )
                .frame(width: 200, height: 30)
            
            HStack(spacing: 6) {
                ForEach(0..<viewModel.looks.count, id: \.self) { index in
                    Circle()
                        .fill(
                            index == viewModel.selectedLookIndex
                                ? Color.white
                                : Color.white.opacity(0.45)
                        )
                        .frame(
                            width: index == viewModel.selectedLookIndex ? 7.5 : 5,
                            height: index == viewModel.selectedLookIndex ? 7.5 : 5
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.18), lineWidth: 0.5)
                        )
                        .onTapGesture {
                            viewModel.selectLook(at: index)
                        }
                }
            }
        }
    }
}

#Preview {
    AvatarStageView(viewModel: .mock())
        .background(AppColors.canvasBackground)
}
