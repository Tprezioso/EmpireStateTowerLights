//
//  CurrentTowerLightsView.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/3/23.
//

import SwiftUI
import ComposableArchitecture

struct CurrentTowerLightsFeature: Reducer {
    struct State: Equatable {
        @PresentationState var alert: AlertState<Action.Alert>?
        @BindingState var dateSelection: Days = .today
        var towers = [Tower]()
        
        enum Days: CustomStringConvertible, Hashable, CaseIterable {
            case yesterday, today, tomorrow
            
            var description: String {
                switch self {
                case .yesterday:
                    return "Yesterday"
                case .today:
                    return "Today"
                case .tomorrow:
                    return "Tomorrow"
                }
            }
        }
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case didReceiveData([Tower])
        case swipedScreenLeft
        case swipedScreenRight
        case loadingError
        case alert(PresentationAction<Alert>)
        enum Alert {
            case reloadData
        }
    }
    
    @Dependency(\.currentTowerClient) var currentTowerClient
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .onAppear:
                return .run { send in
                    do {
                        guard let towers = try await currentTowerClient.getCurrentTowerData() else {
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
                
            case .swipedScreenLeft:
                switch state.dateSelection {
                    
                case .yesterday:
                    state.dateSelection = .today
                case .today:
                    state.dateSelection = .tomorrow
                case .tomorrow:
                    state.dateSelection = .tomorrow
                }
                return .none
                
            case .swipedScreenRight:
                switch state.dateSelection {
                    
                case .yesterday:
                    state.dateSelection = .yesterday
                case .today:
                    state.dateSelection = .yesterday
                case .tomorrow:
                    state.dateSelection = .today
                }
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

struct CurrentTowerLightsView: View {
    let store: StoreOf<CurrentTowerLightsFeature>
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack(spacing: 20) {
                    Picker("Pick your day", selection: viewStore.$dateSelection) {
                        ForEach(CurrentTowerLightsFeature.State.Days.allCases, id: \.self) {
                            Text($0.description).tag($0)
                        }
                    }.pickerStyle(.segmented)
                    
                    if !viewStore.towers.isEmpty {
                        switch viewStore.dateSelection {
                        case .yesterday:
                            TowerView(tower: viewStore.towers[0])
                        case .today:
                            TowerView(tower: viewStore.towers[1])
                        case .tomorrow:
                            TowerView(tower: viewStore.towers[2])
                        }
                    }
                    Spacer()
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.startLocation.x > value.location.x {
                                viewStore.send(.swipedScreenLeft)
                            } else {
                                viewStore.send(.swipedScreenRight)
                            }
                        }
                )
                .navigationTitle("Current Lights")
                .padding()
                .onAppear {
                    viewStore.send(.onAppear)
                    
                }
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

struct CurrentTowerLightsView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentTowerLightsView(
            store: .init(
                initialState: .init(),
                reducer: {
                    CurrentTowerLightsFeature()
                }
            )
        )
    }
}
