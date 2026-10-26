//
//  ContentView.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 24/10/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isPresentingOccasionSheet = true
    @State private var savedOccasion: OccasionDetail?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let saved = savedOccasion {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Created Occasion")
                                .font(AppTypography.cardHeadline)
                                .foregroundStyle(AppColors.espressoTitle)
                            
                            Divider()
                            
                            HStack {
                                Text("Title:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(saved.title)
                            }
                            
                            HStack {
                                Text("Date:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(saved.formattedDate)
                            }
                            
                            HStack {
                                Text("Dresscode:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(saved.dresscode)
                            }
                        }
                        .font(AppTypography.bodyRegular)
                        .foregroundStyle(AppColors.bodyText)
                        .padding(AppDimensions.cardInternalPadding)
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    } else {
                        Text("Tap button to open the Occasion Input sheet")
                            .font(AppTypography.bodyRegular)
                            .foregroundStyle(AppColors.mutedCaption)
                    }
                    
                    Button {
                        isPresentingOccasionSheet = true
                    } label: {
                        Text("Create Occasion")
                            .font(AppTypography.buttonLabel)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.espressoTitle)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                }
            }
            .navigationTitle("Occasion Feature")
            .sheet(isPresented: $isPresentingOccasionSheet) {
                OccasionFormSheet { occasion in
                    self.savedOccasion = occasion
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
