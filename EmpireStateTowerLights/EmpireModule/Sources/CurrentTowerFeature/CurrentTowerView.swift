//
//  CurrentTowerView.swift
//  EmpireStateTowerLights
//

#if os(iOS)
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct CurrentTowerView: View {
    @Bindable var store: StoreOf<CurrentTowerFeature>
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StoreOf<CurrentTowerFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                if let lights = store.lights {
                    // The header floats over the pages so the tower's glow is never
                    // clipped by the top edge of the pager.
                    TabView(selection: $store.selectedDay) {
                        ForEach(store.availableDays, id: \.self) { day in
                            if let lighting = lights.lighting(for: day) {
                                page(for: lighting, towerHeight: proxy.size.height * 0.44)
                                    .tag(day)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .hidesScrollEdgeEffect()
                    .overlay(alignment: .top) { header }

                    DayPicker(days: store.availableDays, selection: $store.selectedDay)
                        .padding(.bottom, 12)
                } else if let message = store.errorMessage, !store.isLoading {
                    header
                    Spacer()
                    ErrorCard(message: message) { store.send(.retryButtonTapped) }
                        .padding(20)
                    Spacer()
                } else {
                    header
                    loadingPage(towerHeight: proxy.size.height * 0.44)
                }
            }
        }
        .background(NightSkyBackground(glow: store.selectedLighting?.swatchColors ?? []))
        .task { store.send(.task) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.sceneBecameActive) }
        }
        .sheet(item: $store.detail) { lighting in
            LightingDetailView(lighting: lighting, today: store.lights?.today.day ?? CalendarDay(Date()))
        }
    }

    /// Height reserved above each page for the floating header.
    private let headerHeight: CGFloat = 64

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Empire State Building").eyebrowStyle()
                Text((store.lights?.today.day ?? CalendarDay(Date())).formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.isLoading && store.lights != nil {
                ProgressView().controlSize(.small)
            }
            Button {
                store.send(.aboutButtonTapped)
            } label: {
                Image(systemName: "sparkles")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About, app icons, and tip jar")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: headerHeight, alignment: .top)
    }

    private func page(for lighting: TowerLighting, towerHeight: CGFloat) -> some View {
        let today = store.lights?.today.day ?? lighting.day
        return ScrollView {
            VStack(spacing: 24) {
                GlowingTowerView(colors: lighting.swatchColors)
                    .frame(height: max(220, towerHeight))
                    .padding(.top, headerHeight + 12)

                Button {
                    store.send(.lightingTapped(lighting))
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lighting.day.relativeName(today: today)).eyebrowStyle()
                        Text(lighting.title)
                            .font(.display())
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        ColorSwatchRow(colors: lighting.colors)
                        if let subtitle = lighting.subtitle {
                            Text(subtitle)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack {
                            Text("Details")
                            Image(systemName: "chevron.right")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                        .padding(.top, 4)
                    }
                    .glassCard()
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(lighting.day.relativeName(today: today)): \(lighting.spokenDescription)")
                .accessibilityHint("Shows details and sharing options")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .hidesScrollEdgeEffect()
        .refreshable { await store.send(.refresh).finish() }
    }

    private func loadingPage(towerHeight: CGFloat) -> some View {
        VStack(spacing: 24) {
            GlowingTowerView(colors: [.white.opacity(0.4)])
                .frame(height: max(220, towerHeight))
                .padding(.top, 12)
            LoadingCard()
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

/// Capsule segmented control for Last Night / Tonight / Tomorrow.
struct DayPicker: View {
    var days: [CurrentTowerFeature.Day]
    @Binding var selection: CurrentTowerFeature.Day
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days, id: \.self) { day in
                Button {
                    withAnimation(.spring(duration: 0.35)) { selection = day }
                } label: {
                    Text(day.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == day ? Theme.skyBottom : .white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            if selection == day {
                                Capsule()
                                    .fill(Theme.gold)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == day ? .isSelected : [])
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.12)))
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    CurrentTowerView(
        store: Store(initialState: CurrentTowerFeature.State()) {
            CurrentTowerFeature()
        } withDependencies: {
            $0.towerClient = .previewValue
        }
    )
    .preferredColorScheme(.dark)
}
#endif
