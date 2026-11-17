//
//  CameraPreviewRepresentable.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 16/11/26.
//

import AVFoundation
import SwiftUI
import UIKit

/// Shared UIViewRepresentable wrapping `AVCaptureVideoPreviewLayer` with reliable
/// portrait orientation and mirroring synchronization across initial startup and camera switching.
struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    let isFrontCamera: Bool

    func makeUIView(context: Context) -> CameraPreviewContainerView {
        let view = CameraPreviewContainerView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.isFrontCamera = isFrontCamera
        view.attachSession(session)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewContainerView, context: Context) {
        uiView.isFrontCamera = isFrontCamera
        uiView.attachSession(session)
        uiView.updateOrientationAndMirroring()
    }
}

final class CameraPreviewContainerView: UIView {
    var isFrontCamera: Bool = false {
        didSet {
            if oldValue != isFrontCamera {
                setupRotationCoordinator()
                updateOrientationAndMirroring()
            }
        }
    }

    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var connectionObservation: NSKeyValueObservation?
    private var sessionRunningObserver: NSObjectProtocol?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    deinit {
        rotationObservation?.invalidate()
        connectionObservation?.invalidate()
        if let sessionRunningObserver {
            NotificationCenter.default.removeObserver(sessionRunningObserver)
        }
    }

    func attachSession(_ session: AVCaptureSession) {
        if previewLayer.session !== session {
            previewLayer.session = session
            setupRotationCoordinator()
            observeSessionAndConnection(for: session)
        } else if rotationCoordinator == nil {
            setupRotationCoordinator()
        }
        updateOrientationAndMirroring()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            setupRotationCoordinator()
            updateOrientationAndMirroring()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        updateOrientationAndMirroring()
    }

    private func observeSessionAndConnection(for session: AVCaptureSession) {
        connectionObservation?.invalidate()
        connectionObservation = previewLayer.observe(\.connection, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.setupRotationCoordinator()
                self?.updateOrientationAndMirroring()
            }
        }

        if let sessionRunningObserver {
            NotificationCenter.default.removeObserver(sessionRunningObserver)
        }
        sessionRunningObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureSession.didStartRunningNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.setupRotationCoordinator()
                self?.updateOrientationAndMirroring()
            }
        }
    }

    private func setupRotationCoordinator() {
        rotationObservation?.invalidate()
        rotationObservation = nil
        rotationCoordinator = nil

        guard let session = previewLayer.session else { return }
        let devices = session.inputs.compactMap { ($0 as? AVCaptureDeviceInput)?.device }
        guard let device = devices.first else {
            return
        }

        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        self.rotationCoordinator = coordinator

        // Observe dynamic preview rotation angle from the device coordinator
        rotationObservation = coordinator.observe(
            \.videoRotationAngleForHorizonLevelPreview,
            options: [.initial, .new]
        ) { [weak self] coord, _ in
            let angle = coord.videoRotationAngleForHorizonLevelPreview
            DispatchQueue.main.async {
                self?.applyRotation(angle: angle)
            }
        }
    }

    func updateOrientationAndMirroring() {
        guard let connection = previewLayer.connection else { return }

        // 1. Guarantee portrait video orientation
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        // 2. Apply hardware rotation coordinator angle on iOS 17+
        if let coordinator = rotationCoordinator {
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }

        // 3. Mirroring configuration
        if connection.isVideoMirroringSupported {
            if connection.automaticallyAdjustsVideoMirroring {
                connection.automaticallyAdjustsVideoMirroring = false
            }
            if connection.isVideoMirrored != isFrontCamera {
                connection.isVideoMirrored = isFrontCamera
            }
        }
    }

    private func applyRotation(angle: CGFloat) {
        guard let connection = previewLayer.connection else { return }

        if connection.isVideoRotationAngleSupported(angle) {
            if connection.videoRotationAngle != angle {
                connection.videoRotationAngle = angle
            }
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        if connection.isVideoMirroringSupported {
            if connection.automaticallyAdjustsVideoMirroring {
                connection.automaticallyAdjustsVideoMirroring = false
            }
            if connection.isVideoMirrored != isFrontCamera {
                connection.isVideoMirrored = isFrontCamera
            }
        }
    }
}
