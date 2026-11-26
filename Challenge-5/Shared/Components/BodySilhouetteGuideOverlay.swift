//
//  BodySilhouetteGuideOverlay.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/11/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Full-body human silhouette guide overlay for Front & Side Body Scan camera screens.
///
/// Provides distance-readable visual feedback (white -> orange -> bright green + screen edge glow)
/// so users standing 2-3 meters away can immediately tell when the phone is upright and their full body is aligned.
struct BodySilhouetteGuideOverlay: View {
    let expectedType: BodyFacingOrientation
    let alignmentState: BodyAlignmentState

    private var isAligned: Bool {
        alignmentState == .aligned
    }

    private var guideColor: Color {
        switch alignmentState {
        case .searching:
            return .white
        case .aligned:
            return AppColors.lightingOptimal
        default:
            return AppColors.lightingWarning
        }
    }

    private var silhouetteAssetName: String {
        expectedType == .side ? "bodyside" : "bodyfront"
    }

    var body: some View {
        GeometryReader { geo in
            let topReserved: CGFloat = 118
            let bottomReserved: CGFloat = 132
            let availableHeight = max(240, geo.size.height - topReserved - bottomReserved)
            let guideHeight = min(geo.size.height * 0.67, availableHeight)
            let widthRatio: CGFloat = expectedType == .side ? 0.42 : 0.56
            let guideWidth = min(geo.size.width * 0.78, max(150, guideHeight * widthRatio))
            let centerPoint = CGPoint(
                x: geo.size.width / 2,
                y: topReserved + availableHeight / 2
            )

            ZStack {
                // Full-screen green rim glow when upright & aligned (easily visible from 2-3m away)
                if isAligned {
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .stroke(AppColors.lightingOptimal.opacity(0.85), lineWidth: 6)
                        .ignoresSafeArea()
                        .shadow(color: AppColors.lightingOptimal.opacity(0.65), radius: 12)
                        .transition(.opacity)
                }

                // Centered Full-Body Framing Box + Human Silhouette
                ZStack {
                    // Subtle dashed frame outline
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            guideColor.opacity(isAligned ? 0.65 : 0.28),
                            style: StrokeStyle(
                                lineWidth: isAligned ? 2.2 : 1.4,
                                dash: isAligned ? [] : [6, 6]
                            )
                        )

                    // Vertical center posture alignment line
                    Path { path in
                        path.move(to: CGPoint(x: guideWidth / 2, y: 14))
                        path.addLine(to: CGPoint(x: guideWidth / 2, y: guideHeight - 14))
                    }
                    .stroke(
                        guideColor.opacity(isAligned ? 0.30 : 0.18),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 5])
                    )

                    // Head & Feet horizontal boundary guides
                    VStack(spacing: 0) {
                        boundaryGuideLine(label: "HEAD")
                            .padding(.top, 10)

                        Spacer()

                        boundaryGuideLine(label: "FEET")
                            .padding(.bottom, 10)
                    }

                    // Human Silhouette Vector (bodyfront / bodyside SVG asset)
                    Image(silhouetteAssetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(guideColor.opacity(isAligned ? 0.34 : 0.24))
                        .shadow(color: guideColor.opacity(isAligned ? 0.75 : 0.45), radius: isAligned ? 8 : 3)
                        .padding(.vertical, 22)
                        .padding(.horizontal, 14)

                    // Crisp 4 Corner Brackets (distance-readable framing cues)
                    BodyGuideCornerBracketsShape(bracketLength: 28)
                        .stroke(
                            guideColor.opacity(isAligned ? 0.98 : 0.85),
                            style: StrokeStyle(lineWidth: isAligned ? 4.0 : 3.2, lineCap: .round, lineJoin: .round)
                        )

                    // Large Green Checkmark Badge when position is verified
                    if isAligned {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(AppColors.lightingOptimal)
                                    .background(Circle().fill(Color.black.opacity(0.55)).padding(2))
                                    .shadow(color: .black.opacity(0.4), radius: 6)
                                    .padding(10)
                            }
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: guideWidth, height: guideHeight)
                .position(centerPoint)
            }
            .animation(.easeInOut(duration: 0.22), value: alignmentState)
        }
        .allowsHitTesting(false)
    }

    private func boundaryGuideLine(label: String) -> some View {
        HStack(spacing: 6) {
            dashedSegment
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(guideColor.opacity(isAligned ? 0.9 : 0.65))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
            dashedSegment
        }
        .padding(.horizontal, 14)
    }

    private var dashedSegment: some View {
        Rectangle()
            .fill(guideColor.opacity(isAligned ? 0.55 : 0.30))
            .frame(height: 1)
    }
}

/// Four L-shaped corner brackets around the full-body guide box.
private struct BodyGuideCornerBracketsShape: Shape {
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

        // Bottom-Left
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - bracketLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bracketLength, y: rect.maxY))

        // Bottom-Right
        path.move(to: CGPoint(x: rect.maxX - bracketLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bracketLength))

        return path
    }
}

#if canImport(UIKit)
/// Validation failure details shown in the post-capture modal when a body scan photo does not meet requirements.
struct BodyCaptureValidationFailure: Identifiable {
    let id = UUID()
    let photo: UIImage
    let title: String
    let message: String
}

/// Shared post-capture validator for Front & Side Body Scan photos.
enum BodyCaptureValidator {
    static func validate(
        photo: UIImage,
        expectedType: BodyFacingOrientation,
        wasDeviceLevel: Bool
    ) async -> BodyCaptureValidationFailure? {
        #if targetEnvironment(simulator)
        return nil
        #else
        if !wasDeviceLevel {
            return BodyCaptureValidationFailure(
                photo: photo,
                title: "Phone Too Tilted",
                message: "Your phone was tilted too much during capture. Please keep the phone upright and retake the photo."
            )
        }

        let result = await HumanDetector.detectHuman(image: photo, expectedType: expectedType)

        if !result.isHumanPresent || !result.isFullBody || !result.isOrientationMatch {
            return BodyCaptureValidationFailure(
                photo: photo,
                title: "Photo Does Not Match",
                message: result.message
            )
        }

        switch result.framingStatus {
        case .tooClose:
            return BodyCaptureValidationFailure(
                photo: photo,
                title: "Too Close to Camera",
                message: "Your full body is too close or your feet are cropped out. Please step back so your whole body from head to feet fits inside the silhouette."
            )
        case .tooFar:
            return BodyCaptureValidationFailure(
                photo: photo,
                title: "Too Far from Camera",
                message: "You appear too far from the camera for accurate measurement. Please move closer so your body fills the silhouette."
            )
        case .aligned, .offCenter:
            return nil
        }
        #endif
    }
}

/// Modal sheet displayed immediately after capture if the photo fails validation,
/// showing the captured photo preview, failure reason, and a Retake Photo button.
struct BodyCaptureInvalidModal: View {
    let failure: BodyCaptureValidationFailure
    let onRetake: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()
                .padding(.bottom, 10)

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.lightingWarning)

                    Text(failure.title)
                        .font(AppTypography.title3SemiBold)
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Image(uiImage: failure.photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppColors.lightingWarning.opacity(0.45), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)

                Text(failure.message)
                    .font(AppTypography.subheadlineRegular)
                    .foregroundStyle(AppColors.bodyText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.top, 6)

            Spacer(minLength: 16)

            Button {
                onRetake()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Retake Photo")
                        .font(AppTypography.buttonLabel)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColors.primaryBlack)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.bottom, 24)
        }
        .background(AppColors.cardBackground.ignoresSafeArea())
        .environment(\.colorScheme, .light)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
    }
}
#endif
