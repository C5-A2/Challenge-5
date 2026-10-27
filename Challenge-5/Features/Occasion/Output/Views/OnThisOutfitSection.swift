//
//  OnThisOutfitSection.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI

struct OnThisOutfitSection: View {
    
    
    var garments: [GarmentItem]
    var onSelectGarment: ((GarmentItem) -> Void)? = nil
    
    
    init(
        garments: [GarmentItem] = [],
        onSelectGarment: ((GarmentItem) -> Void)? = nil
    ) {
        self.garments = garments
        self.onSelectGarment = onSelectGarment
    }
    
    
    private var displayGarments: [GarmentItem] {
        if !garments.isEmpty {
            return garments
        }
        return [
            GarmentItem(
                category: .top,
                name: "Polo",
                material: "french terry Cotton",
                colorName: "Black",
                hexColor: "#1A1A1A"
            ),
            GarmentItem(
                category: .bottom,
                name: "Polo",
                material: "french terry Cotton",
                colorName: "Black",
                hexColor: "#1A1A1A"
            ),
            GarmentItem(
                category: .outer,
                name: "Polo",
                material: "french terry Cotton",
                colorName: "Black",
                hexColor: "#1A1A1A"
            )
        ]
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("On this outfit")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppColors.espressoTitle)
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(displayGarments) { garment in
                        garmentCard(for: garment)
                            .onTapGesture {
                                onSelectGarment?(garment)
                            }
                    }
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            }
        }
    }
    
    
    private func garmentCard(for garment: GarmentItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                garmentImage(for: garment)
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                framingCornerBrackets
                    .frame(width: 106, height: 106)
            }
            .frame(width: 128, height: 128)
            .background(Color(hex: "#7F8183"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            HStack(alignment: .top, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(garment.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.espressoTitle)
                        .lineLimit(1)
                    
                    Text(garment.material)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppColors.mutedCaption)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: garment.hexColor.isEmpty ? "#1A1A1A" : garment.hexColor))
                            .frame(width: 5, height: 5)
                        
                        Text(garment.colorName.isEmpty ? "Black" : garment.colorName)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(AppColors.mutedCaption)
                            .lineLimit(1)
                    }
                }
                .frame(width: 104, alignment: .leading)
                
                Spacer(minLength: 0)
                
                Button {
                    onSelectGarment?(garment)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.mutedCaption)
                        .padding(2)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 128)
        }
    }
    
    private func garmentImage(for garment: GarmentItem) -> some View {
        Group {
            if garment.category == .top, let img = UIImage(named: "mock_garment_polo") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if garment.category == .bottom, let img = UIImage(named: "mock_garment_pants") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if let img = UIImage(named: "mock_garment_shoes") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackIcon(for: garment.category)
            }
        }
    }
    
    private func fallbackIcon(for category: GarmentCategory) -> some View {
        ZStack {
            Color(hex: "#7F8183")
            Image(systemName: category == .top ? "tshirt.fill" : "figure.walk")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
    
    private var framingCornerBrackets: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let length: CGFloat = 11
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
                
                path.move(to: CGPoint(x: w - length, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: length))
                
                path.move(to: CGPoint(x: 0, y: h - length))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: length, y: h))
                
                path.move(to: CGPoint(x: w - length, y: h))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w, y: h - length))
            }
            .stroke(Color.white.opacity(0.95), lineWidth: 2.2)
        }
    }
}

#Preview {
    OnThisOutfitSection()
        .padding(.vertical)
        .background(AppColors.canvasBackground)
}
