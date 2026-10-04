//
//  NightSkyBackground.swift
//  EmpireStateTowerLights
//

import SwiftUI

/// A deep night-sky gradient with twinkling stars and an optional colored glow on the horizon.
public struct NightSkyBackground: View {
    var glow: [Color]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(glow: [Color] = []) {
        self.glow = glow
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.skyTop, Theme.skyMiddle, Theme.skyBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            if !glow.isEmpty {
                RadialGradient(
                    colors: [(glow.first ?? .clear).opacity(0.35), .clear],
                    center: UnitPoint(x: 0.5, y: 0.35),
                    startRadius: 10,
                    endRadius: 420
                )
                .blendMode(.screen)
                .animation(.easeInOut(duration: 0.8), value: glow)
            }

            if reduceMotion {
                Starfield(time: 0)
            } else {
                TimelineView(.periodic(from: .now, by: 1.0 / 12)) { context in
                    Starfield(time: context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct Starfield: View {
    var time: TimeInterval

    private static let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, phase: Double)] = {
        var generator = SeededGenerator(seed: 1931)
        return (0..<90).map { _ in
            (
                x: .random(in: 0...1, using: &generator),
                y: .random(in: 0...0.75, using: &generator),
                size: .random(in: 0.6...2.0, using: &generator),
                phase: .random(in: 0...(2 * .pi), using: &generator)
            )
        }
    }()

    var body: some View {
        Canvas { context, size in
            for star in Self.stars {
                let twinkle = 0.55 + 0.45 * sin(time * 1.3 + star.phase)
                // Stars fade toward the city glow at the bottom.
                let opacity = twinkle * (1 - Double(star.y) * 0.9)
                let rect = CGRect(
                    x: star.x * size.width,
                    y: star.y * size.height,
                    width: star.size,
                    height: star.size
                )
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
            }
        }
    }
}

/// Deterministic random numbers so the stars don't jump around between launches.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

#Preview {
    NightSkyBackground(glow: [.blue, .orange])
}
