//
//  CameraDemoView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI
import AVFoundation

/// Halaman demo kamera yang terintegrasi langsung dengan feed kamera fisik / AVCaptureSession.
public struct CameraDemoView: View {
    
    // MARK: - State
    @State private var cameraManager = CameraManager()
    @State private var currentMode: CameraGuideMode = .face
    @State private var lightingStatus: CameraLightingStatus = .optimal
    @State private var showsGrid: Bool = true
    @State private var capturedPhotoData: Data?
    @State private var isShowingReviewScreen: Bool = false
    @State private var shutterFlashOpacity: Double = 0.0
    @State private var isShowingDiscardDialog: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initializer
    public init() { }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            // 1. Live Camera Feed (AVCaptureVideoPreviewLayer)
            #if os(iOS)
            if cameraManager.isCameraAuthorized {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            #else
            Color.black.ignoresSafeArea()
            #endif
            
            // 2. Camera Overlay Component (Garis Panduan Oval/Siluet & Top Bar)
            CameraOverlayView(
                mode: currentMode,
                lightingStatus: lightingStatus,
                showsGrid: showsGrid,
                instructionText: nil, // Bersih sesuai sketch
                onClose: {
                    dismiss()
                },
                onFlipCamera: {
                    cameraManager.switchCamera()
                },
                onCapture: {
                    takePicture()
                }
            )
            
            // 3. Flash Effect saat tombol shutter ditekan
            Color.white
                .opacity(shutterFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
        // 4. Photo Review Screen saat foto terambil
        .sheet(isPresented: $isShowingReviewScreen) {
            simulatedReviewView
        }
    }
    
    // MARK: - Capture Logic
    private func takePicture() {
        withAnimation(.easeIn(duration: 0.08)) {
            shutterFlashOpacity = 0.9
        }
        
        cameraManager.capturePhoto { data in
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.shutterFlashOpacity = 0.0
                }
                self.capturedPhotoData = data
                self.isShowingReviewScreen = true
            }
        }
    }
    
    // MARK: - Photo Review View
    private var simulatedReviewView: some View {
        NavigationStack {
            ZStack {
                AppColors.canvasBackground.ignoresSafeArea()
                
                PhotoReviewLayout(
                    image: reviewImage,
                    checklistItems: [
                        .init(iconSystemName: "face.smiling", isPassing: true),
                        .init(iconSystemName: "sun.max.fill", isPassing: true),
                        .init(iconSystemName: "eyeglasses", isPassing: true)
                    ],
                    onRetake: {
                        isShowingDiscardDialog = true
                    },
                    onUsePhoto: {
                        isShowingReviewScreen = false
                    }
                )
                .padding(.top, 24)
            }
            .discardConfirmation(
                isPresented: $isShowingDiscardDialog,
                title: "Are you sure Discard?",
                message: "A message should be a short, complete sentence."
            ) {
                isShowingReviewScreen = false
            }
        }
    }
    
    private var reviewImage: Image {
        #if canImport(UIKit)
        if let data = capturedPhotoData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #endif
        return Image(systemName: "person.fill")
    }
}

// MARK: - Preview
#Preview("Camera Demo Screen") {
    CameraDemoView()
}
