//
//  CameraServiceProtocol.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import UIKit
import AVFoundation

/// Protocol defining the camera hardware lifecycle, preview session, and capture capabilities.
/// Conforms to `APP_STRUCTURE.md` Section 9 to allow mock implementations in previews and tests.
@MainActor
public protocol CameraServiceProtocol: AnyObject {

    /// True if the capture session is actively running.
    var isRunning: Bool { get }

    /// Flash enabled state for still photo capture.
    var isFlashEnabled: Bool { get set }

    /// Currently active camera position (front or back).
    var cameraPosition: AVCaptureDevice.Position { get }

    /// Start the AVFoundation camera session asynchronously.
    func startSession() async throws

    /// Stop the capture session.
    func stopSession()

    /// Capture a single high-resolution still image.
    func capturePhoto() async throws -> UIImage

    /// Toggle between front-facing and back-facing cameras.
    func switchCamera() async throws
}
