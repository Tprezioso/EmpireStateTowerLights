//
//  SplashScreen.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/27/23.
//

import DesignSystem
import Models
import SwiftUI

/// The tower's crown lights up from the bottom, then fades into the app,
/// which has already started loading underneath.
struct SplashScreen: View {
    var onFinished: () -> Void

    @State private var litFraction: CGFloat = 0
    @State private var isTitleVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            NightSkyBackground()
            VStack(spacing: 28) {
                GlowingTowerView(
                    colors: [Theme.gold, LightColor.white.color],
                    litFraction: litFraction,
                    animatesGlow: false
                )
                .frame(height: 320)

                Text("Tower Lights")
                    .font(.display())
                    .foregroundStyle(.white)
                    .opacity(isTitleVisible ? 1 : 0)
                    .offset(y: isTitleVisible ? 0 : 8)
            }
        }
        .task {
            guard !reduceMotion else {
                onFinished()
                return
            }
            withAnimation(.easeInOut(duration: 1.0)) { litFraction = 1 }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) { isTitleVisible = true }
            try? await Task.sleep(for: .seconds(1.6))
            onFinished()
        }
    }
}

#Preview {
    SplashScreen {}
}
