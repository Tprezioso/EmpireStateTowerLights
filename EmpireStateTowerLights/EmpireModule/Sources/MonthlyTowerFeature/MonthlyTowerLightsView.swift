//
//  ContentView.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import SwiftUI
import ComposableArchitecture
import Models
import TowerViews

struct MonthlyTowerLightsFeature: Reducer {
    struct State: Equatable {
        @PresentationState var alert: AlertState<Action.Alert>?
        var towers = [Tower]()
        var monthName = Date().formatted(.dateTime.month(.wide))
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case didReceiveData([Tower])
        case loadingError
        case alert(PresentationAction<Alert>)
        enum Alert {
            case reloadData
        }
    }
    
    @Dependency(\.towerClient) var towerClient
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                return .run { send in
                    do {
                        guard let towers = try await towerClient.getTowerData() else {
                            return
                        }
                        await send(.didReceiveData(towers))
                    } catch {
                        await send(.loadingError)
                    }
                }
                
            case let .didReceiveData(towers):
                state.towers = towers
                return .none
            
            case .alert(.presented(.reloadData)):
                return .run { send in
                    await send(.onAppear)
                }
            
            case .alert(.dismiss):
                return .none
            
            case .loadingError:
                state.alert = AlertState {
                    TextState("There seems to be a networking issue. Try again later")
                } actions: {
                    ButtonState(role: .none, action: .reloadData) {
                        TextState("Reload")
                    }
                    
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                }
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}

struct MonthlyTowerLightsView: View {
    let store: StoreOf<MonthlyTowerLightsFeature>
    @Environment(\.scenePhase) private var scenePhase
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewStore.towers, id: \.self) { tower in
                                TowerView(tower: tower, isMonthlyView: true)
                                    .frame(height: 300)
                            }
                        }
                    }
                    Spacer()
                }
                .navigationTitle("Lights for \(viewStore.monthName)")
                .onAppear { viewStore.send(.onAppear) }
                .foregroundColor(.white)
                .padding()
                .nightBackground()
                .preferredColorScheme(.dark)
            }.alert(store: self.store.scope(state: \.$alert, action: {.alert($0)}))
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .background:
                    break
                case .inactive:
                    break
                case .active:
                    viewStore.send(.onAppear)
                @unknown default:
                    break
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyTowerLightsView(store: .init(initialState: MonthlyTowerLightsFeature.State()) {
            MonthlyTowerLightsFeature()
        })
    }
}
