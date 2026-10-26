//
//  ContentView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 22/10/26.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Navigation & Tab State
    @State private var selectedTab: CapsuleTabItem = .library
    
    // Reference Picker Sheet state
    @State private var isShowingReferencePicker: Bool = false
    @State private var selectedReferences: [SavedLookItem] = []
    
    var body: some View {
        ZStack {
            switch selectedTab {
            case .occasions:
                temporaryOccasionInputPage
            case .library:
                LibraryView(selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $isShowingReferencePicker) {
            SavedReferencePickerSheet(
                savedLooks: SavedLookItem.samples,
                allowsMultipleSelection: true,
                onSelectReferences: { selected in
                    selectedReferences = selected
                },
                onDismiss: {
                    isShowingReferencePicker = false
                }
            )
            .presentationDetents([.fraction(0.85), .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Temporary Occasion Input Page (Testing Page for Reference Picker)
    
    private var temporaryOccasionInputPage: some View {
        ZStack(alignment: .bottom) {
            AppColors.canvasBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Occasion Input")
                                .font(AppTypography.screenHeader)
                                .foregroundStyle(AppColors.espressoTitle)
                            
                            Text("Halaman sementara untuk pengujian input referensi")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.mutedCaption)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 16)
                    
                    // Input Reference Card & Trigger Button
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reference Looks")
                                    .font(AppTypography.cardHeadline)
                                    .foregroundStyle(AppColors.espressoTitle)
                                
                                Text("Pilih inspirasi outfit dari Library kamu")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.mutedCaption)
                            }
                            
                            Spacer()
                            
                            // Menu Trigger (ImageSourceMenu)
                            ImageSourceMenu { option in
                                switch option {
                                case .savedLibrary:
                                    isShowingReferencePicker = true
                                case .camera, .photoLibrary:
                                    isShowingReferencePicker = true
                                }
                            }
                        }
                        
                        // Direct Button to open Reference Picker Sheet
                        PrimaryPillButton(
                            title: "Input Reference",
                            iconSystemName: "plus.square.on.square",
                            style: .dark
                        ) {
                            isShowingReferencePicker = true
                        }
                        
                        // Selected References Preview List
                        if !selectedReferences.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Selected (\(selectedReferences.count))")
                                        .font(AppTypography.chipLabel)
                                        .foregroundStyle(AppColors.espressoTitle)
                                    
                                    Spacer()
                                    
                                    Button("Clear") {
                                        withAnimation {
                                            selectedReferences.removeAll()
                                        }
                                    }
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.destructiveRed)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(selectedReferences) { look in
                                            VStack(alignment: .leading, spacing: 4) {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(AppColors.libraryCardPlaceholder)
                                                    .frame(width: 80, height: 100)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .strokeBorder(Color(hex: "#007AFF"), lineWidth: 2)
                                                    )
                                                
                                                Text(look.occasionTitle)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(AppColors.espressoTitle)
                                                    .lineLimit(1)
                                                    .frame(width: 80, alignment: .leading)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(AppDimensions.cardInternalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                            .fill(AppColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                                    .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
                    )
                }
                .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                .padding(.bottom, AppDimensions.tabBarHeight + 48)
            }
            .scrollIndicators(.hidden)
            
            // Bottom Capsule Tab Bar
            CapsuleTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 16)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ContentView()
}
