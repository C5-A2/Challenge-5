//
//  FaceCameraView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import SwiftUI
import AVFoundation

/// Live AVFoundation camera capture screen for facial personal color analysis (C5-82).
/// Features real-time video preview, golden facial framing grid, lighting indicator dot,
/// flash toggle, countdown timer, and high-resolution photo capture.
struct FaceCameraView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: SkinScanViewModel
    @State private var cameraService = CameraService()
    @State private var lightingAnalyzer = LightingAnalyzer()
    @State private var isCapturing: Bool = false
    @State private var countdownRemaining: Int = 3

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // 1. Live Camera Preview Layer
            cameraPreviewContent

            // 2. Facial Grid Framing Overlay
            facialFramingOverlay

            // 3. Floating Top Navigation & Lighting Status
            topControlBar

            // 4. Countdown Animation Overlay
            if viewModel.isCountingDown {
                countdownOverlay
            }

            // 5. Bottom Shutter & Camera Controls
            bottomControlBar
        }
        .task {
            let vm = viewModel
            let analyzer = lightingAnalyzer
            cameraService.onSampleBuffer = { [weak vm] sampleBuffer in
                guard let vm else { return }
                Task {
                    if let result = await analyzer.analyzeFrame(sampleBuffer) {
                        vm.applyRealTimeAnalysis(result)
                    }
                }
            }
            do {
                try await cameraService.startSession()
                viewModel.startCamera()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .onDisappear {
            cameraService.onSampleBuffer = nil
            cameraService.stopSession()
            viewModel.stopCamera()
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

    /// Placeholder canvas shown on Simulator or when camera access is restricted.
    private var simulatorPreviewPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1E1E24"), Color(hex: "#2B2D42")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(Color.white.opacity(0.2))

                Text("Simulated Camera View")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(Color.white.opacity(0.6))

                Text("Position face within the golden guide lines")
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
    }

    // MARK: - 2. Facial Grid Framing Overlay

    private var facialFramingOverlay: some View {
        GeometryReader { geometry in
            let frameWidth = min(geometry.size.width * 0.78, 300)
            let frameHeight = frameWidth * 1.35
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.44)
            let statusColor = viewModel.lightingStatusColor

            ZStack {
                // Rule-of-thirds background grid lines
                Path { path in
                    let left = center.x - frameWidth / 2
                    let top = center.y - frameHeight / 2

                    // Vertical thirds
                    path.move(to: CGPoint(x: left + frameWidth / 3, y: top))
                    path.addLine(to: CGPoint(x: left + frameWidth / 3, y: top + frameHeight))

                    path.move(to: CGPoint(x: left + (2 * frameWidth) / 3, y: top))
                    path.addLine(to: CGPoint(x: left + (2 * frameWidth) / 3, y: top + frameHeight))

                    // Horizontal thirds
                    path.move(to: CGPoint(x: left, y: top + frameHeight / 3))
                    path.addLine(to: CGPoint(x: left + frameWidth, y: top + frameHeight / 3))

                    path.move(to: CGPoint(x: left, y: top + (2 * frameHeight) / 3))
                    path.addLine(to: CGPoint(x: left + frameWidth, y: top + (2 * frameHeight) / 3))
                }
                .stroke(statusColor.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                // Facial Oval Silhouette Guide
                Ellipse()
                    .stroke(statusColor.opacity(viewModel.isReadyForOptimalCapture ? 0.75 : 0.35), lineWidth: 2)
                    .frame(width: frameWidth * 0.72, height: frameHeight * 0.82)
                    .position(center)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isReadyForOptimalCapture)

                // Corner Brackets (Green when optimal, Orange/Yellow when adjusting)
                CornerBracketsShape(bracketLength: 28)
                    .stroke(statusColor.opacity(0.9), lineWidth: 3.5)
                    .frame(width: frameWidth, height: frameHeight)
                    .position(center)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isReadyForOptimalCapture)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 3. Top Control Bar

    private var topControlBar: some View {
        VStack {
            HStack(alignment: .center) {
                // Back Button
                Button {
                    viewModel.currentStep = .guide
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }

                Spacer()

                // Real-time Lighting Status Pill (Green / Orange)
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.lightingStatusColor)
                        .frame(width: 8, height: 8)

                    Text(viewModel.lightingStatusText)
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
                    viewModel.toggleFlash()
                    cameraService.isFlashEnabled = viewModel.isFlashEnabled
                } label: {
                    Image(systemName: viewModel.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.isFlashEnabled ? .yellow : .white)
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

    // MARK: - 4. Countdown Overlay

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            Text("\(countdownRemaining)")
                .font(.system(size: 110, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 12)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - 5. Bottom Control Bar

    private var bottomControlBar: some View {
        VStack {
            Spacer()

            HStack(alignment: .center) {
                // Left: Flash Status / Quick Setting
                Button {
                    viewModel.toggleFlash()
                    cameraService.isFlashEnabled = viewModel.isFlashEnabled
                } label: {
                    Image(systemName: viewModel.isFlashEnabled ? "bolt.circle.fill" : "bolt.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(viewModel.isFlashEnabled ? .yellow : .white.opacity(0.85))
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

                // Right: Camera Switch Button (Front / Rear)
                Button {
                    Task {
                        try? await cameraService.switchCamera()
                    }
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 26))
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

    // MARK: - Actions

    private func triggerCaptureFlow() {
        guard !isCapturing else { return }

        // Start 3-second countdown for steady posture
        viewModel.isCountingDown = true
        countdownRemaining = 3

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownRemaining > 1 {
                countdownRemaining -= 1
            } else {
                timer.invalidate()
                viewModel.isCountingDown = false
                executeCapture()
            }
        }
    }

    private func executeCapture() {
        isCapturing = true
        Task {
            do {
                let photo = try await cameraService.capturePhoto()
                viewModel.setCapturedPhoto(photo)
                isCapturing = false
            } catch {
                viewModel.errorMessage = error.localizedDescription
                isCapturing = false
            }
        }
    }
}

// MARK: - Corner Brackets Shape

private struct CornerBracketsShape: Shape {
    let bracketLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Top-Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + bracketLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + bracketLength, y: rect.minY))

        // Top-Right
        path.move(to: CGPoint(x: rect.maxX - bracketLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + bracketLength))

        // Bottom-Right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - bracketLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - bracketLength, y: rect.maxY))

        // Bottom-Left
        path.move(to: CGPoint(x: rect.minX + bracketLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - bracketLength))

        return path
    }
}

// MARK: - UIKit Camera Preview Representable

private struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    let isFrontCamera: Bool

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.isFrontCamera = isFrontCamera
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if uiView.previewLayer.session != session {
            uiView.previewLayer.session = session
        }
        uiView.isFrontCamera = isFrontCamera
        uiView.updateOrientationAndMirroring()
    }
}

private final class CameraPreviewUIView: UIView {
    var isFrontCamera: Bool = true

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
    FaceCameraView(viewModel: SkinScanViewModel())
}
