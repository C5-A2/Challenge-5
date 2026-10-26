//
//  CameraService.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

@Observable
public final class CameraManager: NSObject {
    public var session = AVCaptureSession()
    public var isSessionRunning = false
    public var capturedData: Data?
    public var isCameraAuthorized = false
    
    private let output = AVCapturePhotoOutput()
    private var currentPosition: AVCaptureDevice.Position = .front
    
    public override init() {
        super.init()
        checkAuthorization()
    }
    
    public func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isCameraAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isCameraAuthorized = granted
                    if granted {
                        self.setupSession()
                    }
                }
            }
        default:
            self.isCameraAuthorized = false
        }
    }
    
    public func setupSession() {
        guard !session.isRunning else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        start()
    }
    
    public func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    public func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
    
    public func switchCamera() {
        currentPosition = (currentPosition == .front) ? .back : .front
        setupSession()
    }
    
    public func capturePhoto(completion: @escaping (Data?) -> Void) {
        guard isSessionRunning else {
            completion(nil)
            return
        }
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate { data in
            completion(data)
        }
        photoCaptureDelegates.append(delegate)
        output.capturePhoto(with: settings, delegate: delegate)
    }
    
    private var photoCaptureDelegates: [PhotoCaptureDelegate] = []
}

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data?) -> Void
    
    init(completion: @escaping (Data?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = photo.fileDataRepresentation()
        completion(data)
    }
}

#if os(iOS)
public struct CameraPreviewView: UIViewRepresentable {
    public let session: AVCaptureSession
    
    public init(session: AVCaptureSession) {
        self.session = session
    }
    
    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

public class CameraPreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
#endif
