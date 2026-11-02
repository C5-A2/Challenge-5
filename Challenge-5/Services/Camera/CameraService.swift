//
//  CameraService.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import UIKit
import AVFoundation
import Observation

/// Native AVFoundation camera service managing camera sessions, preview streams,
/// photo capture, and video frames for real-time lighting analysis.
@Observable
@MainActor
public final class CameraService: NSObject, CameraServiceProtocol {

    // MARK: - Published State

    public private(set) var isRunning: Bool = false
    public var isFlashEnabled: Bool = false
    public private(set) var cameraPosition: AVCaptureDevice.Position = .front
    @ObservationIgnored nonisolated(unsafe) public private(set) var session = AVCaptureSession()
    public private(set) var permissionGranted: Bool = false
    public var errorMessage: String? = nil

    // MARK: - Callbacks

    /// Real-time video sample buffer hook for LightingAnalyzer (C5-83).
    public var onSampleBuffer: (@MainActor @Sendable (CMSampleBuffer) -> Void)? = nil

    // MARK: - Internal AVFoundation Components

    @ObservationIgnored nonisolated(unsafe) private let photoOutput = AVCapturePhotoOutput()
    @ObservationIgnored nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.challenge5.camera.sessionQueue")
    private let sampleQueue = DispatchQueue(label: "com.challenge5.camera.sampleQueue")

    @ObservationIgnored nonisolated(unsafe) private var currentInput: AVCaptureDeviceInput?
    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    // MARK: - Initializer

    public override init() {
        super.init()
    }

    // MARK: - Session Lifecycle

    public func startSession() async throws {
        guard !isRunning else { return }

        // Verify camera authorization
        let authorized = await checkCameraAuthorization()
        self.permissionGranted = authorized

        guard authorized else {
            // Running on Simulator or permission denied — fallback mode enabled
            self.isRunning = true
            return
        }

        let targetPosition = self.cameraPosition
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                do {
                    self.session.beginConfiguration()
                    self.session.sessionPreset = .photo

                    // Configure default input (front camera for Face Scan)
                    try self.configureDeviceInput(position: targetPosition)

                    // Configure Photo Output
                    if self.session.canAddOutput(self.photoOutput) {
                        self.session.addOutput(self.photoOutput)

                        if let photoConnection = self.photoOutput.connection(with: .video) {
                            if photoConnection.isVideoRotationAngleSupported(90) {
                                photoConnection.videoRotationAngle = 90
                            }
                            if photoConnection.isVideoMirroringSupported && targetPosition == .front {
                                photoConnection.isVideoMirrored = true
                            }
                        }
                    }

                    // Configure Video Output for Lighting Analysis
                    if self.session.canAddOutput(self.videoOutput) {
                        self.videoOutput.alwaysDiscardsLateVideoFrames = true
                        self.videoOutput.videoSettings = [
                            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                        ]
                        self.videoOutput.setSampleBufferDelegate(self, queue: self.sampleQueue)
                        self.session.addOutput(self.videoOutput)

                        if let connection = self.videoOutput.connection(with: .video) {
                            if connection.isVideoRotationAngleSupported(90) {
                                connection.videoRotationAngle = 90
                            }
                            if connection.isVideoMirroringSupported && targetPosition == .front {
                                connection.isVideoMirrored = true
                            }
                        }
                    }

                    self.session.commitConfiguration()
                    self.session.startRunning()

                    Task { @MainActor in
                        self.isRunning = self.session.isRunning
                        continuation.resume()
                    }
                } catch {
                    self.session.commitConfiguration()
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    public func stopSession() {
        guard isRunning else { return }
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            Task { @MainActor in
                self.isRunning = false
            }
        }
    }

    // MARK: - Camera Switching

    public func switchCamera() async throws {
        let newPosition: AVCaptureDevice.Position = (cameraPosition == .front) ? .back : .front
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                do {
                    self.session.beginConfiguration()
                    try self.configureDeviceInput(position: newPosition)
                    if let photoConnection = self.photoOutput.connection(with: .video) {
                        if photoConnection.isVideoRotationAngleSupported(90) {
                            photoConnection.videoRotationAngle = 90
                        }
                        if photoConnection.isVideoMirroringSupported {
                            photoConnection.isVideoMirrored = (newPosition == .front)
                        }
                    }
                    if let connection = self.videoOutput.connection(with: .video) {
                        if connection.isVideoRotationAngleSupported(90) {
                            connection.videoRotationAngle = 90
                        }
                        if connection.isVideoMirroringSupported {
                            connection.isVideoMirrored = (newPosition == .front)
                        }
                    }
                    self.session.commitConfiguration()

                    Task { @MainActor in
                        self.cameraPosition = newPosition
                        continuation.resume()
                    }
                } catch {
                    self.session.commitConfiguration()
                    Task { @MainActor in
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Still Photo Capture

    public func capturePhoto() async throws -> UIImage {
        // If running in simulator or without physical camera, generate simulated photo
        #if targetEnvironment(simulator)
        return makeSimulatorTestImage()
        #else
        guard session.isRunning else {
            return makeSimulatorTestImage()
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation

            var photoSettings = AVCapturePhotoSettings()
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }

            if self.currentInput?.device.hasFlash == true {
                photoSettings.flashMode = self.isFlashEnabled ? .on : .off
            }

            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
        #endif
    }

    // MARK: - Private Configuration Helpers

    private func checkCameraAuthorization() async -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return false
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
        #endif
    }

    nonisolated private func configureDeviceInput(position: AVCaptureDevice.Position) throws {
        if let current = currentInput {
            session.removeInput(current)
        }

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )

        guard let device = discovery.devices.first else {
            // On simulator, no device is found
            return
        }

        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
            self.currentInput = input
        }
    }

    /// Generates a clean placeholder portrait image for iOS Simulator testing.
    private func makeSimulatorTestImage() -> UIImage {
        let size = CGSize(width: 720, height: 960)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Canvas background
            UIColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 1.0).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Simulated Face Oval
            let faceRect = CGRect(x: 180, y: 220, width: 360, height: 460)
            UIColor(red: 0.92, green: 0.78, blue: 0.68, alpha: 1.0).setFill()
            let facePath = UIBezierPath(ovalIn: faceRect)
            facePath.fill()

            // Eyes
            UIColor(red: 0.25, green: 0.20, blue: 0.18, alpha: 1.0).setFill()
            let leftEye = UIBezierPath(ovalIn: CGRect(x: 270, y: 400, width: 32, height: 20))
            let rightEye = UIBezierPath(ovalIn: CGRect(x: 418, y: 400, width: 32, height: 20))
            leftEye.fill()
            rightEye.fill()

            // Lips
            UIColor(red: 0.85, green: 0.45, blue: 0.45, alpha: 0.8).setFill()
            let lips = UIBezierPath(ovalIn: CGRect(x: 320, y: 550, width: 80, height: 24))
            lips.fill()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    public nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            Task { @MainActor in
                self.photoContinuation?.resume(throwing: error)
                self.photoContinuation = nil
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { @MainActor in
                self.photoContinuation?.resume(throwing: NSError(
                    domain: "com.challenge5.camera",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to extract image data from capture photo"]
                ))
                self.photoContinuation = nil
            }
            return
        }

        Task { @MainActor in
            self.photoContinuation?.resume(returning: image)
            self.photoContinuation = nil
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    public nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Hand off frame to real-time LightingAnalyzer service (C5-83)
        nonisolated(unsafe) let buffer = sampleBuffer
        Task { @MainActor in
            self.onSampleBuffer?(buffer)
        }
    }
}
