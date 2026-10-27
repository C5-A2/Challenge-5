//
//  ContentView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 22/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var viewModel = SkinScanViewModel()

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .guide:
                SkinScanGuideView(viewModel: viewModel)
            case .camera:
                FaceCameraView(viewModel: viewModel)
            case .review:
                FaceReviewView(viewModel: viewModel)
            case .result:
                SkinResultView(viewModel: viewModel) {
                    // Action when tapping 'Next' on result
                    viewModel.currentStep = .guide
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
