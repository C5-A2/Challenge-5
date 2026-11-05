//
//  ProfilingFlowHostView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 02/11/26.
//

import SwiftUI
import SwiftData

/// Full-screen coordinator hosting the continuous end-to-end profiling flow (C5-98):
/// Phase 1: Personal Color / Skin Tone Scan -> Phase 2: 3D Body Scan & Measurements.
struct ProfilingFlowHostView: View {

    // MARK: - Navigation Phase

    enum Phase {
        case skinScan
        case bodyScan
    }

    // MARK: - State & Dependencies

    @State private var phase: Phase = .skinScan
    @State private var skinViewModel = SkinScanViewModel()
    @State private var bodyViewModel = BodyScanViewModel()

    var onComplete: () -> Void
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        Group {
            switch phase {
            case .skinScan:
                skinScanFlow
            case .bodyScan:
                bodyScanFlow
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
    }

    // MARK: - Phase 1: Skin Scan Subflow

    @ViewBuilder
    private var skinScanFlow: some View {
        switch skinViewModel.currentStep {
        case .guide:
            SkinScanGuideView(viewModel: skinViewModel) {
                closeFlow()
            }
        case .camera:
            FaceCameraView(viewModel: skinViewModel)
        case .review:
            FaceReviewView(viewModel: skinViewModel)
        case .result:
            SkinResultView(viewModel: skinViewModel) {
                // Advance seamlessly from Skin Scan result to Body Scan guide
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    phase = .bodyScan
                }
            }
        }
    }

    // MARK: - Phase 2: Body Scan Subflow

    @ViewBuilder
    private var bodyScanFlow: some View {
        switch bodyViewModel.currentStep {
        case .frontGuide:
            FrontBodyGuideView(viewModel: bodyViewModel) {
                closeFlow()
            }
        case .frontCamera:
            FrontBodyCameraView(viewModel: bodyViewModel)
        case .frontReview:
            FrontBodyReviewView(viewModel: bodyViewModel)
        case .sideGuide:
            SideBodyGuideView(viewModel: bodyViewModel) {
                closeFlow()
            }
        case .sideCamera:
            SideBodyCameraView(viewModel: bodyViewModel)
        case .sideReview:
            SideBodyReviewView(viewModel: bodyViewModel)
        case .metricsInput:
            PhysicalMetricsInputView(viewModel: bodyViewModel)
        case .analysisResult:
            BodyAnalysisResultView(viewModel: bodyViewModel) {
                onComplete()
            }
        }
    }

    private func closeFlow() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ProfilingFlowHostView(onComplete: {})
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
