//
//  FrontBodyCameraView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import AVFoundation

/// Live AVFoundation camera capture screen for Front Body shape analysis (C5-88).
/// Features full-body level lines (shoulders, waist, hips, feet), device verticality
/// alignment via CoreMotion, zoom toggle (0.5x, 1x, 2x), flash control, countdown timer,
/// and high-resolution capture.
struct FrontBodyCameraView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: BodyScanViewModel
    @State private var cameraService = CameraService()
    @State private var motionManager = MotionLevelManager()
    @State private var isCapturing: Bool = false
    @State private var countdownRemaining: Int = 3
    @State private var selectedZoom: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // 1. Live Camera Preview Layer
            cameraPreviewContent

            // 2. Full-Body Level Lines & Alignment Grid
            fullBodyLevelGrid

            // 3. Top Control Bar (Back, Level Status Pill, Flash)
            topControlBar

            // 4. Zoom Selector Pill (0.5x, 1x, 2x)
            zoomSelectorBar

            // 5. Countdown Overlay
            if viewModel.isCountingDown {
                countdownOverlay
            }

            // 6. Bottom Shutter & Controls
            bottomControlBar
        }
        .task {
            motionManager.startMonitoring()
            do {
                try await cameraService.startSession()
                viewModel.startCamera()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .onDisappear {
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
            BodyCameraPreviewRepresentable(
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

                Text("Position entire body inside alignment guidelines")
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
    }

    // MARK: - 2. Full-Body Level Lines & Alignment Grid

    private var fullBodyLevelGrid: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let guideColor = motionManager.isLevel ? Color(hex: "#34C759") : Color.white

            ZStack {
                // Vertical Center Plumb Line (Alignment)
                Path { path in
                    path.move(to: CGPoint(x: w / 2, y: h * 0.12))
                    path.addLine(to: CGPoint(x: w / 2, y: h * 0.92))
                }
                .stroke(guideColor.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))

                // Horizontal Level Lines across anatomical landmarks
                levelLine(y: h * 0.18, label: "Head", width: w * 0.5, color: guideColor)
                levelLine(y: h * 0.28, label: "Shoulders", width: w * 0.76, color: guideColor)
                levelLine(y: h * 0.50, label: "Waist", width: w * 0.62, color: guideColor)
                levelLine(y: h * 0.60, label: "Hips", width: w * 0.70, color: guideColor)
                levelLine(y: h * 0.90, label: "Feet", width: w * 0.85, color: guideColor)

                // Silhouette Outer Framing Bounding Box
                RoundedRectangle(cornerRadius: 24)
                    .stroke(guideColor.opacity(motionManager.isLevel ? 0.75 : 0.35), lineWidth: 1.5)
                    .frame(width: w * 0.80, height: h * 0.78)
                    .position(x: w / 2, y: h * 0.52)
                    .animation(.easeInOut(duration: 0.25), value: motionManager.isLevel)
            }
        }
        .allowsHitTesting(false)
    }

    private func levelLine(y: CGFloat, label: String, width: CGFloat, color: Color) -> some View {
        GeometryReader { geometry in
            let xStart = (geometry.size.width - width) / 2
            let xEnd = xStart + width

            ZStack(alignment: .leading) {
                Path { path in
                    path.move(to: CGPoint(x: xStart, y: y))
                    path.addLine(to: CGPoint(x: xEnd, y: y))
                }
                .stroke(color.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.65))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Capsule())
                    .position(x: xStart + 36, y: y - 10)
            }
        }
    }

    // MARK: - 3. Top Control Bar

    private var topControlBar: some View {
        VStack {
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
                        .fill(motionManager.isLevel ? Color(hex: "#34C759") : Color.orange)
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

            Spacer()
        }
    }

    // MARK: - 4. Zoom Selector Bar

    private var zoomSelectorBar: some View {
        VStack {
            Spacer()

            HStack(spacing: 16) {
                zoomButton(factor: 0.5, label: "0.5")
                zoomButton(factor: 1.0, label: "1x")
                zoomButton(factor: 2.0, label: "2")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.50))
            .clipShape(Capsule())
            .padding(.bottom, 120)
        }
    }

    private func zoomButton(factor: CGFloat, label: String) -> some View {
        Button {
            selectedZoom = factor
            cameraService.setZoomFactor(factor)
        } label: {
            Text(label)
                .font(.system(size: 13, weight: selectedZoom == factor ? .bold : .medium))
                .foregroundStyle(selectedZoom == factor ? Color(hex: "#F5C249") : .white)
                .frame(minWidth: 26)
        }
    }

    // MARK: - 5. Countdown Overlay

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            Text("\(countdownRemaining)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 12)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - 6. Bottom Control Bar

    private var bottomControlBar: some View {
        VStack {
            Spacer()

            HStack(alignment: .center) {
                // Left: Close Button
                Button {
                    viewModel.currentStep = .frontGuide
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
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
        guard !isCapturing else { return }

        // Start 3-second countdown to allow user to take upright stance
        viewModel.isCountingDown = true
        countdownRemaining = 3

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                if countdownRemaining > 1 {
                    countdownRemaining -= 1
                } else {
                    timer.invalidate()
                    viewModel.isCountingDown = false
                    executeCapture()
                }
            }
        }
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

// MARK: - UIKit Camera Preview Layer Representable

private struct BodyCameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    let isFrontCamera: Bool

    func makeUIView(context: Context) -> BodyCameraPreviewUIView {
        let view = BodyCameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.isFrontCamera = isFrontCamera
        return view
    }

    func updateUIView(_ uiView: BodyCameraPreviewUIView, context: Context) {
        if uiView.previewLayer.session != session {
            uiView.previewLayer.session = session
        }
        uiView.isFrontCamera = isFrontCamera
        uiView.updateOrientationAndMirroring()
    }
}

private final class BodyCameraPreviewUIView: UIView {
    var isFrontCamera: Bool = false

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        updateOrientationAndMirroring()
    }

    func updateOrientationAndMirroring() {
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = isFrontCamera
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FrontBodyCameraView(viewModel: BodyScanViewModel())
}
