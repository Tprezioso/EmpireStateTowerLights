//
//  GlowingTowerView.swift
//  EmpireStateTowerLights
//

import SwiftUI

/// A stylized Empire State Building silhouette, drawn in a unit square and scaled to fit.
public struct TowerSilhouette: Shape {
    /// Stacked tiers from the street up: (half width, bottom y, top y), in unit coordinates.
    static let tiers: [(halfWidth: CGFloat, bottom: CGFloat, top: CGFloat)] = [
        (0.50, 1.000, 0.880), // base
        (0.42, 0.880, 0.800), // fifth-floor setback
        (0.30, 0.800, 0.300), // main shaft
        (0.24, 0.300, 0.240), // 72nd-floor setback
        (0.18, 0.240, 0.190), // 81st-floor setback
        (0.13, 0.190, 0.150), // crown
        (0.09, 0.150, 0.115),
        (0.06, 0.115, 0.090),
        (0.03, 0.090, 0.050), // mast
    ]

    /// The y coordinate (unit) where the lit crown begins.
    public static let crownStart: CGFloat = 0.30

    public init() {}

    public func path(in rect: CGRect) -> Path {
        func x(_ unit: CGFloat) -> CGFloat { rect.minX + unit * rect.width }
        func y(_ unit: CGFloat) -> CGFloat { rect.minY + unit * rect.height }

        var path = Path()
        for tier in Self.tiers {
            path.addRect(CGRect(
                x: x(0.5 - tier.halfWidth),
                y: y(tier.top),
                width: tier.halfWidth * 2 * rect.width,
                height: (tier.bottom - tier.top) * rect.height
            ))
        }
        // Antenna spire.
        path.move(to: CGPoint(x: x(0.488), y: y(0.050)))
        path.addLine(to: CGPoint(x: x(0.5), y: y(0.0)))
        path.addLine(to: CGPoint(x: x(0.512), y: y(0.050)))
        path.closeSubpath()
        return path
    }
}

/// The tower with its crown lit in the given colors, a soft bloom, and lit office windows.
public struct GlowingTowerView: View {
    var colors: [Color]
    /// How much of the crown is lit, from the bottom up (0...1). Used by the launch animation.
    var litFraction: CGFloat
    var animatesGlow: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    public init(colors: [Color], litFraction: CGFloat = 1, animatesGlow: Bool = true) {
        self.colors = colors.isEmpty ? [.white] : colors
        self.litFraction = litFraction
        self.animatesGlow = animatesGlow
    }

    /// Two or more stops so a single color still reads as a gradient.
    private var gradientColors: [Color] {
        colors.count == 1 ? [colors[0].opacity(0.85), colors[0]] : colors
    }

    private var crownGradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
    }

    /// Spans only the crown, so every color is visible on the lit part of the building.
    private var silhouetteCrownGradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: UnitPoint(x: 0.5, y: 0.03),
            endPoint: UnitPoint(x: 0.5, y: TowerSilhouette.crownStart)
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let crownHeight = size.height * TowerSilhouette.crownStart
            let litHeight = crownHeight * litFraction

            ZStack {
                // Bloom behind the crown.
                Ellipse()
                    .fill(crownGradient)
                    .frame(width: size.width * 1.1, height: crownHeight * 1.4)
                    .position(x: size.width / 2, y: crownHeight * 0.55)
                    .blur(radius: size.width * 0.22)
                    .opacity((isPulsing ? 0.75 : 0.5) * litFraction)

                // Building body.
                TowerSilhouette()
                    .fill(LinearGradient(
                        colors: [Theme.towerEdge, Theme.towerBody, Theme.skyBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    ))

                // Office windows on the shaft.
                Canvas { context, canvasSize in
                    var generator = SeededGenerator(seed: 1931)
                    let columns = 9
                    let rows = 26
                    let shaftLeft = canvasSize.width * 0.22
                    let shaftWidth = canvasSize.width * 0.56
                    let top = canvasSize.height * 0.33
                    let bottom = canvasSize.height * 0.78
                    for row in 0..<rows {
                        for column in 0..<columns {
                            guard Double.random(in: 0...1, using: &generator) < 0.35 else { continue }
                            let rect = CGRect(
                                x: shaftLeft + shaftWidth * (CGFloat(column) + 0.3) / CGFloat(columns),
                                y: top + (bottom - top) * CGFloat(row) / CGFloat(rows),
                                width: max(1, shaftWidth / CGFloat(columns) * 0.35),
                                height: max(1, (bottom - top) / CGFloat(rows) * 0.45)
                            )
                            context.fill(Path(rect), with: .color(Theme.window.opacity(.random(in: 0.15...0.55, using: &generator))))
                        }
                    }
                }

                // The lit crown, revealed from the bottom up.
                TowerSilhouette()
                    .fill(silhouetteCrownGradient)
                    .mask(alignment: .top) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: crownHeight - litHeight)
                            Rectangle().frame(height: litHeight)
                            Spacer(minLength: 0)
                        }
                    }
                    .shadow(color: colors[0].opacity(0.8 * litFraction), radius: size.width * 0.04)
            }
        }
        .aspectRatio(0.42, contentMode: .fit)
        .animation(.easeInOut(duration: 0.8), value: colors)
        .onAppear {
            guard animatesGlow, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 30) {
        GlowingTowerView(colors: [.blue, .orange])
        GlowingTowerView(colors: [.red, .white, .blue])
        GlowingTowerView(colors: [.pink], litFraction: 0.5)
    }
    .padding()
    .frame(height: 400)
    .background(NightSkyBackground())
}
