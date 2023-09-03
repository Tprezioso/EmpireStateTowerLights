//
//  ContentView.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
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

struct CurrentTowerLightsView: View {
    let store: StoreOf<CurrentTowerLightsFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Picker("Pick your day", selection: viewStore.$dateSelection) {
                    ForEach(CurrentTowerLightsFeature.State.Days.allCases, id: \.self) {
                        Text($0.description).tag($0)
                    }
                }.pickerStyle(.segmented)
                
                
                ScrollView {
                    ForEach(viewStore.towers, id: \.self) { tower in
                            VStack(spacing: 12) {
                                
                                AsyncImage(url: URL(string: tower.image!) ) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        
                                } placeholder: {
                                    Image(systemName: "building")
                                        .resizable()
                                        .frame(width: 100,height: 150)
                                        .foregroundColor(.white)
                                }

                               
                                Text("\(tower.day ?? "") \(tower.date ?? "")")
                                Text(tower.light ?? "")
                                Text(tower.content ?? "")
                            }.padding()
                    }
                }
                Spacer()
            }
            .onAppear { viewStore.send(.onAppear) }
            .foregroundColor(.white)
            .padding()
        }.nightBackground()
            .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentTowerLightsView(store: .init(initialState: CurrentTowerLightsFeature.State()) {
            CurrentTowerLightsFeature()
        })
    }
}


struct NightBackground: ViewModifier {

    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                gradient:
                    Gradient(
                        colors: [
                            .indigo,
                            .black
                        ]
                    ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func nightBackground() -> some View {
        modifier(NightBackground())
            
    }
}
