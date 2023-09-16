//
//  Modifiers.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/15/23.
//

import SwiftUI

struct NightBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                gradient:
                    Gradient(
                        colors: [
                            .indigo,
                            .black
                        ]
                    ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func nightBackground() -> some View {
        modifier(NightBackground())
    }
}
