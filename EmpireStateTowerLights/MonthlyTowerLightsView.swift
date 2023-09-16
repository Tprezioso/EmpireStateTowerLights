//
//  ContentView.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import SwiftUI
import ComposableArchitecture

struct MonthlyTowerLightsFeature: Reducer {
    struct State: Equatable {
        var towers = [Tower]()
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case didReceiveData([Tower])
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
                        
                    }
                }
                
            case let .didReceiveData(towers):
                state.towers = towers
                return .none
            }
        }
    }
}

struct MonthlyTowerLightsView: View {
    let store: StoreOf<MonthlyTowerLightsFeature>
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
                .navigationTitle("Lights This Month")
                .onAppear { viewStore.send(.onAppear) }
                .foregroundColor(.white)
                .padding()
                .nightBackground()
                .preferredColorScheme(.dark)
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
