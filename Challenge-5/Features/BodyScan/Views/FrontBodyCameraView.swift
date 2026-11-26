//
//  FrontBodyCameraView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import AVFoundation

/// Live AVFoundation camera capture screen for Front Body shape analysis (C5-88).
/// Features device verticality alignment via CoreMotion, zoom toggle (0.5x, 1x, 2x),
/// flash control, countdown timer, and high-resolution capture.
struct FrontBodyCameraView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: BodyScanViewModel
    @State private var cameraService = CameraService()
    @State private var motionManager = MotionLevelManager()
    @State private var poseMonitor = LiveBodyPoseMonitor()
    @State private var isCapturing: Bool = false
    @State private var countdownRemaining: Int = 3
    @State private var countdownTask: Task<Void, Never>? = nil

    private var effectiveAlignmentState: BodyAlignmentState {
        BodyAlignmentState.resolve(
            from: poseMonitor.latestResult,
            isDeviceLevel: motionManager.isLevel
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // 1. Live Camera Preview Layer
            cameraPreviewContent

            // 2. Full-Body Human Silhouette & Alignment Guide Overlay
            BodySilhouetteGuideOverlay(
                expectedType: .front,
                alignmentState: effectiveAlignmentState
            )

            // 3. Top Control Bar (Back, Level Status Pill, Flash)
            topControlBar

            // 4. Countdown Overlay
            if viewModel.isCountingDown {
                CameraCountdownOverlay(remainingSeconds: countdownRemaining) {
                    cancelCountdown()
                }
            }

            // 5. Bottom Shutter & Controls
            bottomControlBar
        }
        .task {
            motionManager.startMonitoring()
            cameraService.onSampleBuffer = { [poseMonitor] buffer in
                poseMonitor.processSampleBuffer(buffer, expectedType: .front)
            }
            do {
                try await cameraService.startSession()
                viewModel.startCamera()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .onDisappear {
            cancelCountdown()
            cameraService.onSampleBuffer = nil
            poseMonitor.reset()
            motionManager.stopMonitoring()
            cameraService.stopSession()
            viewModel.stopCamera()
        }
        .onChange(of: motionManager.isLevel) { _, isLevel in
            viewModel.isDeviceVertical = isLevel
        }
    }

    // MARK: - 1. Camera Preview Content

    @ViewBuilder
    private var cameraPreviewContent: some View {
        #if targetEnvironment(simulator)
        simulatorPreviewPlaceholder
        #else
        if cameraService.permissionGranted && cameraService.isRunning {
            CameraPreviewRepresentable(
                session: cameraService.session,
                isFrontCamera: cameraService.cameraPosition == .front
            )
            .ignoresSafeArea()
        } else {
            simulatorPreviewPlaceholder
        }
        #endif
    }

    private var simulatorPreviewPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1E1E24"), Color(hex: "#2B2D42")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 110))
                    .foregroundStyle(Color.white.opacity(0.2))

                Text("Simulated Front Body View")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(Color.white.opacity(0.65))

                Text("Position entire body inside frame")
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
    }

    // MARK: - 2. Top Control Bar

    private var topControlBar: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                // Back Button to Guide
                Button {
                    viewModel.currentStep = .frontGuide
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }

                Spacer()

                // Motion Level Status Pill
                HStack(spacing: 8) {
                    Circle()
                        .fill(motionManager.isLevel ? AppColors.lightingOptimal : AppColors.lightingWarning)
                        .frame(width: 8, height: 8)

                    Text(motionManager.isLevel ? "Device Level" : "Keep Phone Upright")
                        .font(AppTypography.caption)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())

                Spacer()

                // Flash Toggle Button
                Button {
                    cameraService.isFlashEnabled.toggle()
                } label: {
                    Image(systemName: cameraService.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(cameraService.isFlashEnabled ? .yellow : .white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.top, 8)

            CameraTimerSelectorPill(
                selectedSeconds: $viewModel.countdownSeconds,
                isDisabled: isCapturing || viewModel.isCountingDown
            )

            LiveBodyValidationPill(
                result: poseMonitor.latestResult,
                expectedType: .front,
                isDeviceLevel: motionManager.isLevel
            )
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)

            Spacer()
        }
    }

    // MARK: - 3. Bottom Control Bar

    private var bottomControlBar: some View {
        VStack {
            Spacer()

            HStack(alignment: .center) {
                // Left spacer to keep shutter button centered
                Color.clear
                    .frame(width: 48, height: 48)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Center: Shutter Capture Button
                Button {
                    triggerCaptureFlow()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 76, height: 76)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 62, height: 62)
                    }
                    .scaleEffect(isCapturing ? 0.92 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isCapturing)
                }
                .disabled(isCapturing || viewModel.isCountingDown)

                // Right: Switch Camera (Front / Rear)
                Button {
                    Task {
                        try? await cameraService.switchCamera()
                    }
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
        }
    }

    // MARK: - Capture Actions

    private func triggerCaptureFlow() {
        guard !isCapturing, !viewModel.isCountingDown else { return }

        let duration = max(1, viewModel.countdownSeconds)
        viewModel.isCountingDown = true
        countdownRemaining = duration

        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            while countdownRemaining > 1 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                countdownRemaining -= 1
            }
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            viewModel.isCountingDown = false
            countdownTask = nil
            executeCapture()
        }
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        viewModel.isCountingDown = false
    }

    private func executeCapture() {
        isCapturing = true
        Task {
            do {
                let photo = try await cameraService.capturePhoto()
                viewModel.setFrontPhoto(photo)
                isCapturing = false
            } catch {
                isCapturing = false
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FrontBodyCameraView(viewModel: BodyScanViewModel())
}
