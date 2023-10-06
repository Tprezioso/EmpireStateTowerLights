//
//  SplashScreen.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/27/23.
//

import SwiftUI

struct SplashScreen: View {
    @Binding var isShowing: Bool
    var body: some View {
        VStack {
            LottieView(name: "Empire", loopMode: .playOnce, isShowing: $isShowing)
        }
        .nightBackground()
    }
}

#Preview {
    SplashScreen(isShowing: .constant(true))
}
