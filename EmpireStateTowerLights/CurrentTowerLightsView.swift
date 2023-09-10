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
                        
                    }
                }
                
            case let .didReceiveData(towers):
                state.towers = towers
                return .none
            }
        }
    }
}

struct CurrentTowerLightsView: View {
    let store: StoreOf<CurrentTowerLightsFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack {
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
                            Text("")
                            TowerView(tower: viewStore.towers[1])
                        case .tomorrow:
                            Text("")
                            TowerView(tower: viewStore.towers[2])
                        }
                    }
                    Spacer()
                }
                .navigationTitle("Current Lights")
                .padding()
                .onAppear { viewStore.send(.onAppear) }
                .nightBackground()
                .preferredColorScheme(.dark)
            }
        }
    }
}

struct CurrentTowerLightsView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentTowerLightsView(
            store: .init(initialState: .init(),
                         reducer: {
                             CurrentTowerLightsFeature()
                         }))
    }
}


struct TowerView: View {
    let tower: Tower?
    var isMonthlyView: Bool = false
    
    var body: some View {
        if let tower = tower {
            ZStack {
                AsyncImage(url: URL(string: tower.image!)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if phase.error != nil {
                        EmptyView()
                    } else {
                        ProgressView().progressViewStyle(.circular)
                            .controlSize(.large)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()
                    Text("\(tower.day ?? "") \(tower.date ?? "")")
                        .font(isMonthlyView ? .body : .title)
                    Text(tower.light ?? "")
                        .font( isMonthlyView ? .title3 : .largeTitle)
                    Text(tower.content ?? "")
                        .font(isMonthlyView ? .caption : .headline)
                }.padding()
            }
        }
    }
}
