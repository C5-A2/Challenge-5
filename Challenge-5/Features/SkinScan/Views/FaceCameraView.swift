//
//  FaceCameraView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import SwiftUI
import AVFoundation
import PhotosUI

/// Live AVFoundation camera capture screen for facial personal color analysis (C5-82 & C5-123).
/// Features real-time video preview, golden facial framing grid, smart obstruction/pose/lighting HUD,
/// flash toggle, countdown timer, gallery picker, and high-resolution photo capture.
struct FaceCameraView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: SkinScanViewModel
    @State private var cameraService = CameraService()
    @State private var lightingAnalyzer = LightingAnalyzer()
    @State private var isCapturing: Bool = false
    @State private var showWhiteScreenFlash: Bool = false
    @State private var countdownRemaining: Int = 3
    @State private var selectedPickerItem: PhotosPickerItem? = nil

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

            // 6. Controlled D65 White Screen Flash Overlay for Differential Illuminant Capture
            if showWhiteScreenFlash {
                Color.white
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .task {
            let vm = viewModel
            let analyzer = lightingAnalyzer
            let cam = cameraService
            cameraService.onSampleBuffer = { [weak vm, weak cam] sampleBuffer in
                guard let vm else { return }
                Task {
                    if let result = await analyzer.analyzeFrame(sampleBuffer) {
                        let kelvin = cam?.currentColorTemperatureKelvin
                        vm.applyRealTimeAnalysis(result, colorTemperatureKelvin: kelvin)
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
            FaceCameraPreviewRepresentable(
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

    // MARK: - 5. Bottom Control Bar & Smart Real-Time HUD (C5-123)

    private var canTriggerShutter: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return viewModel.isReadyForOptimalCapture
        #endif
    }

    private var bottomControlBar: some View {
        VStack(spacing: 14) {
            Spacer()

            // Real-time 4-criteria smart check pills (C5-123)
            realTimeSmartChecklistHUD
                .padding(.horizontal, 16)

            HStack(alignment: .center) {
                // Left: Photo Gallery Picker
                PhotosPicker(selection: $selectedPickerItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: selectedPickerItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                viewModel.setCapturedPhoto(uiImage)
                            }
                        }
                        await MainActor.run {
                            selectedPickerItem = nil
                        }
                    }
                }

                // Center: Shutter Capture Button (Gated until C5-123 checks pass)
                Button {
                    triggerCaptureFlow()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(canTriggerShutter ? Color.white : viewModel.lightingStatusColor.opacity(0.65), lineWidth: 4)
                            .frame(width: 76, height: 76)

                        Circle()
                            .fill(canTriggerShutter ? Color.white : Color.white.opacity(0.35))
                            .frame(width: 62, height: 62)
                    }
                    .scaleEffect(isCapturing ? 0.92 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isCapturing)
                }
                .disabled(!canTriggerShutter || isCapturing || viewModel.isCountingDown)

                // Right: Camera Switch Button (Front / Rear)
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
            .padding(.bottom, 32)
        }
    }

    private var realTimeSmartChecklistHUD: some View {
        HStack(spacing: 6) {
            smartCriterionBadge(
                title: "Uncovered",
                isPassed: viewModel.isFaceInFrame && viewModel.isFaceUnobstructed
            )
            smartCriterionBadge(
                title: "Daylight",
                isPassed: viewModel.isLightingAdequate
            )
            smartCriterionBadge(
                title: "Eye Level",
                isPassed: viewModel.isFaceInFrame && viewModel.isHeadPoseDirect
            )
            smartCriterionBadge(
                title: "Bare Face",
                isPassed: viewModel.isFaceInFrame && viewModel.isBareFaceDetected
            )
        }
    }

    private func smartCriterionBadge(title: String, isPassed: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isPassed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isPassed ? Color(hex: "#34C759") : Color(hex: "#FF9500"))

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.58))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isPassed ? Color(hex: "#34C759").opacity(0.55) : Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func triggerCaptureFlow() {
        guard !isCapturing, canTriggerShutter else { return }

        // Start 3-second countdown for steady posture
        viewModel.isCountingDown = true
        countdownRemaining = 3

        Task { @MainActor in
            while countdownRemaining > 1 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                #if !targetEnvironment(simulator)
                if !viewModel.isFaceInFrame || viewModel.obstructionReason != nil {
                    viewModel.isCountingDown = false
                    return
                }
                #endif
                countdownRemaining -= 1
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            #if !targetEnvironment(simulator)
            if !viewModel.isFaceInFrame || viewModel.obstructionReason != nil {
                viewModel.isCountingDown = false
                return
            }
            #endif
            viewModel.isCountingDown = false
            executeCapture()
        }
    }

    private func executeCapture() {
        isCapturing = true
        Task { @MainActor in
            #if targetEnvironment(simulator)
            do {
                let photo = try await cameraService.capturePhoto()
                viewModel.setCapturedPhoto(photo)
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
            isCapturing = false
            #else
            let shouldUseWhiteFlashPair = (cameraService.cameraPosition == .front && cameraService.permissionGranted)
            let activeScreen = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first(where: { $0.activationState == .foregroundActive })?
                .screen
            let originalBrightness = activeScreen?.brightness

            defer {
                showWhiteScreenFlash = false
                if let originalBrightness, let activeScreen {
                    activeScreen.brightness = originalBrightness
                }
                if shouldUseWhiteFlashPair {
                    cameraService.unlockExposureAndWhiteBalance()
                }
                isCapturing = false
            }

            do {
                if shouldUseWhiteFlashPair {
                    // 1. Lock AE & AWB so ambient and flash frames share identical sensor gain & white balance
                    cameraService.lockExposureAndWhiteBalance()
                    try? await Task.sleep(nanoseconds: 60_000_000)

                    // 2. Capture ambient baseline frame from the live video stream (zero shutter lag)
                    let ambientPhoto = try await cameraService.captureFreshVideoFrame()

                    // 3. Emit pure white D65 screen illumination and wait for OLED ramp + ISP pipeline
                    activeScreen?.brightness = 1.0
                    showWhiteScreenFlash = true
                    try? await Task.sleep(nanoseconds: 320_000_000)

                    // 4. Capture fresh white-screen-illuminated frame from the same locked ISP stream
                    let flashPhoto = try await cameraService.captureFreshVideoFrame()

                    viewModel.setCapturedPhoto(flashPhoto, ambientImage: ambientPhoto)
                } else {
                    let photo = try await cameraService.capturePhoto()
                    viewModel.setCapturedPhoto(photo)
                }
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
            #endif
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

private struct FaceCameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    let isFrontCamera: Bool

    func makeUIView(context: Context) -> FaceCameraPreviewUIView {
        let view = FaceCameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.isFrontCamera = isFrontCamera
        return view
    }

    func updateUIView(_ uiView: FaceCameraPreviewUIView, context: Context) {
        if uiView.previewLayer.session != session {
            uiView.previewLayer.session = session
        }
        uiView.isFrontCamera = isFrontCamera
        uiView.updateOrientationAndMirroring()
    }
}

private final class FaceCameraPreviewUIView: UIView {
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
