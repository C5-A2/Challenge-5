//
//  CameraOverlayView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

public enum CameraGuideMode: Sendable {
    case face
    case bodyFront
    case bodySide
    case none
}

public enum CameraLightingStatus: String, Sendable {
    case optimal = "Optimal Lighting"
    case tooDark = "Too Dark"
    case tooBright = "Too Bright"
    case backlit = "Backlit Subject"
    
    public var indicatorColor: Color {
        switch self {
        case .optimal: return AppColors.lightingOptimal
        case .tooDark, .tooBright, .backlit: return AppColors.lightingWarning
        }
    }
}

/// Overlay guide providing real-time positioning frames, lighting feedback,
/// and camera capture controls across Face Scan, Front Body Scan, and Side Body Scan.
public struct CameraOverlayView: View {
    
    // MARK: - Properties
    public let mode: CameraGuideMode
    public var lightingStatus: CameraLightingStatus
    public var showsGrid: Bool
    public var instructionText: String?
    public let onClose: () -> Void
    public var onFlipCamera: (() -> Void)?
    public var onCapture: (() -> Void)?
    
    // MARK: - Initializer
    public init(
        mode: CameraGuideMode,
        lightingStatus: CameraLightingStatus = .optimal,
        showsGrid: Bool = true,
        instructionText: String? = nil,
        onClose: @escaping () -> Void,
        onFlipCamera: (() -> Void)? = nil,
        onCapture: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.lightingStatus = lightingStatus
        self.showsGrid = showsGrid
        self.instructionText = instructionText
        self.onClose = onClose
        self.onFlipCamera = onFlipCamera
        self.onCapture = onCapture
    }
    
    // MARK: - Body
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimming mask with transparent cut-out guide
                guideLayer(in: geometry.size)
                
                // Top control bar
                VStack {
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.black.opacity(0.45))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Real-time lighting feedback pill
                        HStack(spacing: 6) {
                            Circle()
                                .fill(lightingStatus.indicatorColor)
                                .frame(width: 8, height: 8)
                            
                            Text(lightingStatus.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        if let onFlipCamera {
                            Button(action: onFlipCamera) {
                                Image(systemName: "camera.rotate")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Color.black.opacity(0.45))
                                    .clipShape(Circle())
                            }
                        } else {
                            Color.clear.frame(width: 38, height: 38)
                        }
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Bottom Controls & Guidance
                    VStack(spacing: 20) {
                        if let instructionText {
                            Text(instructionText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.55))
                                .clipShape(Capsule())
                        }
                        
                        if let onCapture {
                            Button(action: onCapture) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 4)
                                        .frame(width: 72, height: 72)
                                    
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 58, height: 58)
                                }
                            }
                            .buttonStyle(.plain)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Guide Cut-out & Silhouette Drawing
    @ViewBuilder
    private func guideLayer(in size: CGSize) -> some View {
        switch mode {
        case .face:
            faceGuide(in: size)
        case .bodyFront:
            bodyFrontGuide(in: size)
        case .bodySide:
            bodySideGuide(in: size)
        case .none:
            EmptyView()
        }
    }
    
    private func faceGuide(in size: CGSize) -> some View {
        let ovalWidth = size.width * 0.65
        let ovalHeight = ovalWidth * 1.35
        
        return ZStack {
            // Face oval outline
            Ellipse()
                .strokeBorder(
                    Color.white.opacity(0.85),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
                .frame(width: ovalWidth, height: ovalHeight)
            
            // Center alignment cross
            if showsGrid {
                Path { path in
                    let midX = size.width / 2
                    let midY = size.height / 2
                    
                    path.move(to: CGPoint(x: midX - 16, y: midY))
                    path.addLine(to: CGPoint(x: midX + 16, y: midY))
                    path.move(to: CGPoint(x: midX, y: midY - 16))
                    path.addLine(to: CGPoint(x: midX, y: midY + 16))
                }
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
            }
        }
    }
    
    private func bodyFrontGuide(in size: CGSize) -> some View {
        let guideWidth = size.width * 0.70
        let guideHeight = size.height * 0.72
        
        return ZStack {
            RoundedRectangle(cornerRadius: 32)
                .strokeBorder(
                    Color.white.opacity(0.8),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .frame(width: guideWidth, height: guideHeight)
            
            // Shoulder & hip horizontal helper guides
            VStack {
                Spacer().frame(height: guideHeight * 0.22)
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: guideWidth * 0.8, height: 1)
                
                Spacer().frame(height: guideHeight * 0.28)
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: guideWidth * 0.75, height: 1)
                
                Spacer()
            }
            .frame(width: guideWidth, height: guideHeight)
        }
    }
    
    private func bodySideGuide(in size: CGSize) -> some View {
        let guideWidth = size.width * 0.55
        let guideHeight = size.height * 0.72
        
        return ZStack {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(
                    Color.white.opacity(0.8),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .frame(width: guideWidth, height: guideHeight)
            
            // Vertical posture spine line
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 1, height: guideHeight * 0.85)
        }
    }
}

// MARK: - Interactive Preview Demo
#Preview("Camera Viewfinder Demo") {
    CameraPreviewDemo()
}

private struct CameraPreviewDemo: View {
    @State private var mode: CameraGuideMode = .face
    @State private var lighting: CameraLightingStatus = .optimal
    
    var body: some View {
        ZStack {
            // Simulated camera viewfinder background
            Color(hex: "#1E1E1E").ignoresSafeArea()
            
            RadialGradient(
                colors: [Color(hex: "#333333"), Color(hex: "#121212")],
                center: .center,
                startRadius: 80,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Camera Overlay View
            CameraOverlayView(
                mode: mode,
                lightingStatus: lighting,
                showsGrid: true,
                instructionText: instructionText,
                onClose: { },
                onFlipCamera: { },
                onCapture: { }
            )
            
            // Mode Switcher Controls for Preview
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Face") {
                        withAnimation { mode = .face }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(mode == .face ? Color.black : Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(mode == .face ? Color.white : Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    
                    Button("Front Body") {
                        withAnimation { mode = .bodyFront }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(mode == .bodyFront ? Color.black : Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(mode == .bodyFront ? Color.white : Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    
                    Button("Side Body") {
                        withAnimation { mode = .bodySide }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(mode == .bodySide ? Color.black : Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(mode == .bodySide ? Color.white : Color.black.opacity(0.5))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 100)
            }
        }
    }
    
    private var instructionText: String {
        switch mode {
        case .face:
            return "Center your face inside the oval"
        case .bodyFront:
            return "Fit your whole body within the frame"
        case .bodySide:
            return "Turn sideways and stand straight"
        case .none:
            return ""
        }
    }
}
