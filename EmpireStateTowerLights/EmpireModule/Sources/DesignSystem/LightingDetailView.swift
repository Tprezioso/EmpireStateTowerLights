//
//  LightingDetailView.swift
//  EmpireStateTowerLights
//

import Models
import SwiftUI

/// Full details for one lighting, presented as a sheet.
public struct LightingDetailView: View {
    var lighting: TowerLighting
    var today: CalendarDay
    @Environment(\.dismiss) private var dismiss

    public init(lighting: TowerLighting, today: CalendarDay) {
        self.lighting = lighting
        self.today = today
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TowerPhoto(url: lighting.imageURL, colors: lighting.swatchColors)
                        .frame(height: 360)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            if lighting.imageURL != nil {
                                PhotoCredit()
                                    .padding(10)
                            }
                        }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(lighting.day.relativeName(today: today)).eyebrowStyle()
                        Text(lighting.title)
                            .font(.display(.title))
                        Text(lighting.day.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ColorSwatchRow(colors: lighting.colors, size: 18)
                            .padding(.top, 4)
                    }

                    if let subtitle = lighting.subtitle {
                        Text(subtitle)
                            .font(.body)
                            .glassCard()
                    }

                    ShareLightingButton(lighting: lighting, today: today)
                        .frame(maxWidth: .infinity)

                    SourceCredit()
                }
                .padding(20)
            }
            .background(NightSkyBackground(glow: lighting.swatchColors))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gold)
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        LightingDetailView(lighting: .preview, today: TowerLighting.preview.day)
    }
}
