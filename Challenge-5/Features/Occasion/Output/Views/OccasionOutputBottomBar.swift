//
//  OccasionOutputBottomBar.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI

struct OccasionOutputBottomBar: View {
    
    
    var onInfoTap: (() -> Void)? = nil
    
    
    init(onInfoTap: (() -> Void)? = nil) {
        self.onInfoTap = onInfoTap
    }
    
    
    var body: some View {
        HStack(spacing: 12) {
            CircularIconButton(systemName: "info.bubble") {
                onInfoTap?()
            }
            
            Spacer()
            
            CircularIconButton(systemName: "plus") {
            }
            
            CircularIconButton(systemName: "bookmark") {
            }
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.bottom, 6)
    }
}

#Preview {
    OccasionOutputBottomBar(onInfoTap: { })
        .padding()
        .background(AppColors.canvasBackground)
}
