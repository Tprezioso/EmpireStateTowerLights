//
//  MonthlyTowerView.swift
//  EmpireStateTowerLights
//

#if os(iOS)
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct MonthlyTowerView: View {
    @Bindable var store: StoreOf<MonthlyTowerFeature>
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StoreOf<MonthlyTowerFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 12) {
                    content
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .animation(.easeInOut(duration: 0.25), value: store.month)
            }
            .scrollIndicators(.hidden)
            .hidesScrollEdgeEffect()
            .refreshable { await store.send(.refresh).finish() }
        }
        .background(NightSkyBackground())
        .task { store.send(.task) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.sceneBecameActive) }
        }
        .sheet(item: $store.detail) { lighting in
            LightingDetailView(lighting: lighting, today: store.today ?? CalendarDay(Date()))
        }
    }

    @ViewBuilder
    private var content: some View {
        if let lightings = store.lightings {
            if lightings.isEmpty {
                emptyState
            } else {
                ForEach(lightings) { lighting in
                    Button {
                        store.send(.lightingTapped(lighting))
                    } label: {
                        LightingRow(lighting: lighting, isToday: lighting.day == store.today)
                    }
                    .buttonStyle(.plain)
                }
                SourceCredit()
            }
        } else if let message = store.errorMessage, !store.isLoading {
            ErrorCard(message: message) { store.send(.retryButtonTapped) }
        } else {
            ForEach(0..<3, id: \.self) { _ in LoadingCard() }
        }
    }

    private var header: some View {
        HStack {
            monthButton(systemImage: "chevron.left", label: "Previous month") {
                store.send(.previousMonthTapped)
            }
            Spacer()
            VStack(spacing: 4) {
                Text("Lights Calendar").eyebrowStyle()
                Text(store.month?.title ?? " ")
                    .font(.display(.title2))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: store.month)
                if !store.isShowingCurrentMonth, store.today != nil {
                    Button("Back to \(store.today?.yearMonth.monthName ?? "Today")") {
                        store.send(.currentMonthTapped)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                }
            }
            Spacer()
            monthButton(systemImage: "chevron.right", label: "Next month") {
                store.send(.nextMonthTapped)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if store.isLoading && store.lightings != nil {
                ProgressView().controlSize(.mini)
            }
        }
    }

    private func monthButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .sensoryFeedback(.selection, trigger: store.month)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            GlowingTowerView(colors: [LightColor.white.color])
                .frame(height: 180)
            Text("Signature White")
                .font(.display(.title2))
            Text("No special lightings are on the calendar for \(store.month?.monthName ?? "this month") yet. On other nights the tower glows in its signature white.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

#Preview {
    MonthlyTowerView(
        store: Store(initialState: MonthlyTowerFeature.State()) {
            MonthlyTowerFeature()
        } withDependencies: {
            $0.towerClient = .previewValue
        }
    )
    .preferredColorScheme(.dark)
}
#endif
