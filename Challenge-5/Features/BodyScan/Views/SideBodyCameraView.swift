//
//  SideBodyCameraView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import AVFoundation

/// Live AVFoundation camera capture screen for Side Body posture and silhouette analysis (C5-88).
/// Features CoreMotion device verticality tracking, zoom toggles, and countdown capture.
struct SideBodyCameraView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: BodyScanViewModel
    @State private var cameraService = CameraService()
    @State private var motionManager = MotionLevelManager()
    @State private var poseMonitor = LiveBodyPoseMonitor()
    @State private var isCapturing: Bool = false
    @State private var isValidatingPhoto: Bool = false
    @State private var countdownRemaining: Int = 3
    @State private var countdownTask: Task<Void, Never>? = nil
    #if canImport(UIKit)
    @State private var invalidCapture: BodyCaptureValidationFailure? = nil
    #endif

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
                expectedType: .side,
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

            // 5. Post-capture verification indicator
            if isValidatingPhoto {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                        Text("Verifying photo...")
                            .font(AppTypography.caption.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                }
            }

            // 6. Bottom Shutter & Controls
            bottomControlBar
        }
        #if canImport(UIKit)
        .sheet(item: $invalidCapture) { failure in
            BodyCaptureInvalidModal(failure: failure) {
                invalidCapture = nil
            }
        }
        #endif
        .task {
            motionManager.startMonitoring()
            cameraService.onSampleBuffer = { [poseMonitor] buffer in
                poseMonitor.processSampleBuffer(buffer, expectedType: .side)
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
                Image(systemName: "figure.walk.arrival")
                    .font(.system(size: 110))
                    .foregroundStyle(Color.white.opacity(0.2))

                Text("Simulated Side Body View")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(Color.white.opacity(0.65))

                Text("Position entire side profile inside frame")
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
    }

    // MARK: - 2. Top Control Bar

    private var topControlBar: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                // Back Button to Guide
                Button {
                    viewModel.currentStep = .sideGuide
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }

                Spacer(minLength: 4)

                // Single Unified Status Pill (Device Upright + Full Body & Pose Alignment)
                LiveBodyValidationPill(
                    result: poseMonitor.latestResult,
                    expectedType: .side,
                    isDeviceLevel: motionManager.isLevel
                )

                Spacer(minLength: 4)

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
                isDisabled: isCapturing || isValidatingPhoto || viewModel.isCountingDown
            )

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
                .disabled(isCapturing || isValidatingPhoto || viewModel.isCountingDown)

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
        guard !isCapturing, !isValidatingPhoto, !viewModel.isCountingDown else { return }

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
        let wasDeviceLevel = motionManager.isLevel
        Task {
            do {
                let photo = try await cameraService.capturePhoto()
                isCapturing = false
                #if canImport(UIKit)
                isValidatingPhoto = true
                let fixedPhoto = ImageOrientationHelper.fixOrientation(image: photo)
                let failure = await BodyCaptureValidator.validate(
                    photo: fixedPhoto,
                    expectedType: .side,
                    wasDeviceLevel: wasDeviceLevel
                )
                isValidatingPhoto = false
                if let failure {
                    invalidCapture = failure
                } else {
                    viewModel.setSidePhoto(fixedPhoto)
                }
                #else
                viewModel.setSidePhoto(photo)
                #endif
            } catch {
                isCapturing = false
                isValidatingPhoto = false
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SideBodyCameraView(viewModel: BodyScanViewModel())
}
