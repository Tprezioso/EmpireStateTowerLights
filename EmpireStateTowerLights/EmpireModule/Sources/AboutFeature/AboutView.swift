//
//  AboutView.swift
//  EmpireStateTowerLights
//

#if os(iOS)
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct AboutView: View {
    let store: StoreOf<AboutFeature>
    @State private var celebrationGlow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(store: StoreOf<AboutFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    iconSection
                    tipJarSection
                    creditsSection
                    contactSection
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(NightSkyBackground(glow: celebrationGlow ? [Theme.gold] : []))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { store.send(.doneButtonTapped) }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gold)
        .task { await store.send(.task).finish() }
        .sensoryFeedback(.success, trigger: store.thankYouCount)
        .onChange(of: store.thankYouCount) { celebrate() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            GlowingTowerView(
                colors: celebrationGlow ? [Theme.gold, LightColor.white.color] : [Theme.gold],
                animatesGlow: !reduceMotion
            )
            .frame(height: 150)
            .scaleEffect(celebrationGlow ? 1.08 : 1)
            Text("Tower Lights")
                .font(.display(.title))
            Text("Version \(Bundle.main.appVersion)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("App Icon").eyebrowStyle()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 14)], spacing: 16) {
                ForEach(AppIcon.allCases) { icon in
                    let isSelected = icon == store.selectedIcon
                    Button {
                        store.send(.iconTapped(icon))
                    } label: {
                        VStack(spacing: 6) {
                            Image(icon.previewImageName, bundle: .module)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(isSelected ? Theme.gold : .white.opacity(0.15), lineWidth: isSelected ? 3 : 1)
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(Theme.skyBottom, Theme.gold)
                                            .offset(x: 6, y: 6)
                                    }
                                }
                            Text(icon.title)
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .primary : .secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(icon.title) icon")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .sensoryFeedback(.selection, trigger: store.selectedIcon)
        }
        .glassCard()
    }

    private var tipJarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tip Jar").eyebrowStyle()
            Text("Tower Lights is free with no ads. If it brightens your night, a tip helps keep the lights on.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let tips = store.tips, !tips.isEmpty {
                ForEach(tips) { tip in
                    HStack(spacing: 12) {
                        Text(tip.emoji).font(.title2)
                        Text(tip.displayName).font(.headline)
                        Spacer()
                        Button {
                            store.send(.tipTapped(tip))
                        } label: {
                            Group {
                                if store.purchasingTipID == tip.id {
                                    ProgressView().tint(Theme.skyBottom)
                                } else {
                                    Text(tip.displayPrice)
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(minWidth: 64)
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Theme.skyBottom)
                        .disabled(store.purchasingTipID != nil)
                        .accessibilityLabel("Tip \(tip.displayPrice) for a \(tip.displayName)")
                    }
                    .padding(.vertical, 2)
                }
            } else if let error = store.tipsError {
                HStack {
                    Text(error).font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Button("Retry") { store.send(.retryTipsButtonTapped) }
                        .font(.footnote.weight(.semibold))
                }
            } else {
                ProgressView().frame(maxWidth: .infinity)
            }

            if let message = store.purchaseMessage {
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.gold)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut, value: store.purchaseMessage)
        .glassCard()
    }

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Credits").eyebrowStyle()
            Text("The tower lighting schedule and photos are courtesy of the Empire State Building.")
                .font(.subheadline)
            Link(destination: URL(string: "https://www.esbnyc.com/about/tower-lights")!) {
                Label("esbnyc.com/about/tower-lights", systemImage: "arrow.up.right.square")
                    .font(.subheadline.weight(.semibold))
            }
            Text("Tower Lights is an independent app and is not affiliated with or endorsed by the Empire State Building or Empire State Realty Trust.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contact").eyebrowStyle()
            Link(destination: URL(string: "mailto:tommyprezioso@gmail.com?subject=Tower%20Lights")!) {
                Label("Send Feedback", systemImage: "envelope")
            }
            Link(destination: URL(string: "https://www.twitter.com/tommyprezioso")!) {
                Label("@tommyprezioso", systemImage: "at")
            }
        }
        .font(.subheadline.weight(.semibold))
        .glassCard()
    }

    private func celebrate() {
        guard !reduceMotion else { return }
        withAnimation(.spring(duration: 0.5, bounce: 0.4)) { celebrationGlow = true }
        withAnimation(.easeOut(duration: 1.2).delay(1.2)) { celebrationGlow = false }
    }
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        AboutView(store: Store(initialState: AboutFeature.State()) {
            AboutFeature()
        } withDependencies: {
            $0.tipJar = .previewValue
            $0.appIcon = .previewValue
        })
    }
}
#endif
