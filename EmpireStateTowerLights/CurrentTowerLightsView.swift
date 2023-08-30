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
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {                
            case .binding:
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
                
                
                VStack(spacing: 12) {
                    Image(systemName: "building")
                        .resizable()
                        .frame(width: 100,height: 150)
                        .foregroundColor(.white)
                    Text("Date")
                    Text("Lights description")
                }.padding()
                Spacer()
            }
            .task {
                do {
                    try await TowerService().getTowerData()
                } catch {
                    print("errrror")
                }
                
            }
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
