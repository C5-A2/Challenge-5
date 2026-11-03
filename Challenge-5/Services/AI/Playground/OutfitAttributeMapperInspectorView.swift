//
//  OutfitAttributeMapperInspectorView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 28/10/26.
//

import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
#if canImport(ImagePlayground)
import ImagePlayground
#endif

/// Interactive visual inspector and test bench to map `mock_result_1` model image
/// with structured outfit attributes, generate new look via Apple Image Playground,
/// and present the Before vs After result (C5-46).
struct OutfitAttributeMapperInspectorView: View {
    
    // MARK: - State
    
    enum MappingSource: String, CaseIterable, Identifiable {
        case domainModel = "Active Look"
        case rawLLM = "LLaMA JSON"
        
        var id: String { rawValue }
    }
    
    @State private var mappingSource: MappingSource = .domainModel
    @State private var playgroundPackage: OutfitPlaygroundPackage? = nil
    
    // Source Image (mock_result_1)
    @State private var sourceImage: UIImage? = nil
    @State private var sourceCGImage: CGImage? = nil
    @State private var cleanSourceImage: Image? = nil
    @State private var isRemovingBackground: Bool = false
    
    // Generated Output State
    @State private var generatedImage: Image? = nil
    @State private var generatedCGImage: CGImage? = nil
    @State private var isProcessingOutput: Bool = false
    @State private var isShowingPlayground: Bool = false
    @State private var statusMessage: String = "Ready to generate"
    
    // Sample raw JSON input from on-device LLaMA
    @State private var sampleLLMJson: String = """
    {
      "title": "Bespoke Evening Casual",
      "top": {
        "category": "Top",
        "name": "Polo Shirt",
        "cutDetail": "Slim-fit tapered waist",
        "fabricMaterial": "French Terry Cotton",
        "colorName": "Black",
        "colorHex": "#1A1A1A"
      },
      "bottom": {
        "category": "Bottom",
        "name": "Tailored Trousers",
        "cutDetail": "Straight-leg balance cut",
        "fabricMaterial": "Tropical Wool Blend",
        "colorName": "Burgundy Plum",
        "colorHex": "#4A2234"
      }
    }
    """
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // 1. Header Status & Mode Picker
                    headerSection
                    
                    // 2. BEFORE vs AFTER Comparison Card
                    beforeAfterComparisonCard
                    
                    // 3. Trigger Image Playground Button
                    generateButtonSection
                    
                    // 4. Source Selector (Domain vs Raw LLaMA JSON)
                    sourcePickerSection
                    
                    // 5. Extracted Outfit Attributes Details
                    if let pkg = playgroundPackage {
                        attributesDetailsSection(pkg)
                    }
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                .padding(.vertical, 16)
            }
            .background(AppColors.canvasBackground.ignoresSafeArea())
            .navigationTitle("Playground Mapper")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                prepareInitialData()
            }
            // Apple Image Playground Native Sheet Integration (iOS 18.2+)
            .outfitPlaygroundSheet(
                isPresented: $isShowingPlayground,
                package: playgroundPackage,
                sourceImage: cleanSourceImage ?? Image("mock_result_1"),
                onGenerated: { resultCG in
                    self.generatedCGImage = resultCG
                    self.generatedImage = Image(decorative: resultCG, scale: 1.0, orientation: .up)
                    self.statusMessage = "Image successfully generated from native Image Playground!"
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("Subtask C5-46: Attribute Mapper & Visual Playground")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.espressoTitle)
            }
            
            Text(statusMessage)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.mutedCaption)
        }
    }
    
    /// Visual Card comparing the source body (`mock_result_1`) and the Playground Generated Result.
    private var beforeAfterComparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Model Look Comparison")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.espressoTitle)
                Spacer()
                if isRemovingBackground {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Cutout Vision...")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.mutedCaption)
                    }
                }
            }
            
            HStack(spacing: 12) {
                // BEFORE: mock_result_1 Model
                VStack(spacing: 6) {
                    Text("BEFORE (mock_result_1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.mutedCaption)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.04))
                        
                        if let img = sourceImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        } else {
                            Image("mock_result_1")
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        }
                    }
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // AFTER: Generated Image from Image Playground
                VStack(spacing: 6) {
                    Text("AFTER (Playground Output)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "#007AFF"))
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.04))
                        
                        if isProcessingOutput {
                            VStack(spacing: 10) {
                                ProgressView()
                                Text("Synthesizing...")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColors.mutedCaption)
                            }
                        } else if let generatedImage {
                            generatedImage
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 26))
                                    .foregroundStyle(Color.gray.opacity(0.6))
                                Text("Click Generate\nto render look")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColors.mutedCaption)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(8)
                        }
                    }
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// Button to trigger Apple Image Playground Sheet or simulator fallback.
    private var generateButtonSection: some View {
        Button {
            triggerPlaygroundGeneration()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                Text("Generate via Image Playground")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.espressoTitle)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
    }
    
    /// Segmented picker allowing user to test mapping from SwiftData Look or raw LLM JSON text.
    private var sourcePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mapping Pipeline Source")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.espressoTitle)
            
            Picker("Mapping Source", selection: $mappingSource) {
                ForEach(MappingSource.allCases) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mappingSource) { _, newSource in
                switch newSource {
                case .domainModel:
                    loadFromDomainModel()
                case .rawLLM:
                    loadFromRawLLM()
                }
            }
        }
    }
    
    /// Displays extracted garment attributes and synthesized visual prompt.
    private func attributesDetailsSection(_ pkg: OutfitPlaygroundPackage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Extracted Garment Badges
            Text("Extracted Garment Attributes (\(pkg.garments.count))")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.espressoTitle)
            
            ForEach(pkg.garments) { g in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: g.colorHex))
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(g.category.rawValue): \(g.name)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppColors.espressoTitle)
                        
                        Text("\(g.fabricMaterial) • \(g.colorName) (\(g.colorHex))")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.mutedCaption)
                        
                        Text("Silhouette: \(g.fitSilhouette)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "#007AFF"))
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Synthesized Visual Prompt
            VStack(alignment: .leading, spacing: 6) {
                Text("Synthesized Visual Prompt (Passed to Playground)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text(pkg.compositeVisualPrompt)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppColors.bodyText)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .textSelection(.enabled)
            }
        }
    }
    
    // MARK: - Actions & Data Loading
    
    private func prepareInitialData() {
        // 1. Load mock_result_1 image as base model
        if let uiImg = UIImage(named: "mock_result_1") {
            self.sourceImage = uiImg
            self.sourceCGImage = uiImg.cgImage
            
            // Auto cutout background with Vision framework
            isRemovingBackground = true
            Task {
                if let png = uiImg.pngData(),
                   let cleanCG = await removeBackground(from: png) {
                    await MainActor.run {
                        self.sourceCGImage = cleanCG
                        self.cleanSourceImage = Image(decorative: cleanCG, scale: 1.0, orientation: .up)
                        self.isRemovingBackground = false
                    }
                } else {
                    await MainActor.run {
                        self.isRemovingBackground = false
                    }
                }
            }
        }
        
        loadFromDomainModel()
    }
    
    private func loadFromDomainModel() {
        let sampleLook = OutfitLook(
            lookIndex: 0,
            fitRationale: "Slim-fit polo softens the broad shoulder line paired with straight-leg trousers."
        )
        sampleLook.garments = [
            GarmentItem(category: .top, name: "Polo Shirt", material: "French Terry Cotton", colorName: "Black", hexColor: "#1A1A1A"),
            GarmentItem(category: .bottom, name: "Tailored Trousers", material: "Fine Wool", colorName: "Burgundy Plum", hexColor: "#4A2234")
        ]
        
        let occasion = OccasionItem(title: "Annual Gala", date: Date(), dresscode: "Smart Casual")
        self.playgroundPackage = OutfitAttributeMapper.mapOutfitLookToPlayground(look: sampleLook, occasion: occasion)
        self.statusMessage = "Mapped from active OutfitLook domain model"
    }
    
    private func loadFromRawLLM() {
        do {
            self.playgroundPackage = try OutfitAttributeMapper.parsePlaygroundPackageFromLLM(
                jsonString: sampleLLMJson,
                lookIndex: 0,
                occasionTitle: "Bespoke Evening Casual",
                dresscode: "Smart Casual"
            )
            self.statusMessage = "Parsed & mapped from raw LLaMA JSON output"
        } catch {
            self.statusMessage = "Error parsing LLM JSON: \(error.localizedDescription)"
        }
    }
    
    private func triggerPlaygroundGeneration() {
        #if canImport(ImagePlayground)
        if #available(iOS 18.2, *) {
            if ImagePlaygroundViewController.isAvailable {
                isShowingPlayground = true
                statusMessage = "Opening native Apple Image Playground sheet..."
                return
            }
        }
        #endif
        
        // Fallback simulation for Simulator / non-Apple Intelligence environment
        simulateFallbackGeneration()
    }
    
    /// Fallback simulation if running on Simulator or devices prior to iOS 18.2 Apple Intelligence
    private func simulateFallbackGeneration() {
        isProcessingOutput = true
        statusMessage = "Simulating generation on Simulator (rendering mock_result_2)..."
        
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run {
                if let uiImg = UIImage(named: "mock_result_2") ?? UIImage(named: "mock_result_1") {
                    self.generatedImage = Image(uiImage: uiImg)
                }
                self.isProcessingOutput = false
                self.statusMessage = "Rendered simulated result (mock_result_2). On Apple Intelligence devices, native Image Playground sheet opens!"
            }
        }
    }
    
    // MARK: - Vision Background Removal
    
    private func removeBackground(from imageData: Data) async -> CGImage? {
        guard let ciImage = CIImage(data: imageData, options: [.applyOrientationProperty: true]) else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return nil }
            
            let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            
            let filter = CIFilter.blendWithMask()
            filter.inputImage = ciImage
            filter.maskImage = maskCIImage
            filter.backgroundImage = CIImage(color: .clear).cropped(to: ciImage.extent)
            
            guard let outputCIImage = filter.outputImage else { return nil }
            let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
            return context.createCGImage(outputCIImage, from: ciImage.extent)
        } catch {
            return nil
        }
    }
}

// MARK: - Image Playground Sheet Extension

extension View {
    @ViewBuilder
    func outfitPlaygroundSheet(
        isPresented: Binding<Bool>,
        package: OutfitPlaygroundPackage?,
        sourceImage: Image? = nil,
        onGenerated: @escaping (CGImage) -> Void
    ) -> some View {
        #if canImport(ImagePlayground)
        if #available(iOS 18.2, macOS 15.2, *) {
            self.imagePlaygroundSheet(
                isPresented: isPresented,
                concepts: package?.playgroundConcepts ?? [],
                sourceImage: sourceImage
            ) { url in
                if let data = try? Data(contentsOf: url),
                   let ciImage = CIImage(data: data),
                   let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) {
                    onGenerated(cgImage)
                }
            }
        } else {
            self
        }
        #else
        self
        #endif
    }
}

// MARK: - Preview

#Preview("Playground Mapper Inspector") {
    OutfitAttributeMapperInspectorView()
}
