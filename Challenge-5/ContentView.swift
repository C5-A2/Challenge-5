import SwiftUI

struct ContentView: View {
    @State private var viewModel = SkinScanViewModel()

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .guide:
                SkinScanGuideView(viewModel: viewModel)
            case .camera:
                FaceCameraView(viewModel: viewModel)
            case .review:
                FaceReviewView(viewModel: viewModel)
            case .result:
                VStack(spacing: 24) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(Color(hex: "#C68B59"))

                    Text("Skin Scan Complete")
                        .font(AppTypography.screenHeader)
                        .foregroundStyle(AppColors.espressoTitle)

                    VStack(spacing: 8) {
                        Text("Predicted Season: \(viewModel.predictedColorSeason?.rawValue ?? "True Spring")")
                            .font(AppTypography.cardHeadline)
                            .foregroundStyle(AppColors.espressoTitle)

                        Text("Undertone: \(viewModel.detectedUndertone)")
                            .font(AppTypography.bodyRegular)
                            .foregroundStyle(AppColors.bodyText)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)

                    PrimaryPillButton(title: "Scan Again") {
                        viewModel.retakePhoto()
                        viewModel.currentStep = .guide
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.canvasBackground.ignoresSafeArea())
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
    }
}

#Preview {
    ContentView()
}
