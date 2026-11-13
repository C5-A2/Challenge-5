//
//  CameraTimerSelectorPill.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 13/11/26.
//

import SwiftUI

/// Compact pill selector allowing the user to pick a capture countdown timer (3s, 5s, or 10s).
struct CameraTimerSelectorPill: View {
    @Binding var selectedSeconds: Int
    var options: [Int] = [3, 5, 10]
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.leading, 4)

            ForEach(options, id: \.self) { seconds in
                let isSelected = selectedSeconds == seconds
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedSeconds = seconds
                    }
                } label: {
                    Text("\(seconds)s")
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundStyle(isSelected ? Color(hex: "#F5C249") : .white.opacity(0.85))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.16) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1.0)
    }
}

/// Full-screen countdown overlay shown while waiting for capture timer, with cancel action.
struct CameraCountdownOverlay: View {
    let remainingSeconds: Int
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("\(remainingSeconds)")
                    .font(.system(size: 115, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 12)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: remainingSeconds)

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
