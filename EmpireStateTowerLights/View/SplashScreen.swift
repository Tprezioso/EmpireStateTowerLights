//
//  SplashScreen.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/27/23.
//

import SwiftUI
import ComposableArchitecture

struct SplashScreen: View {
    let store: StoreOf<SplashDomain>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                LottieView(name: "Empire", loopMode: .playOnce, isShowing: viewStore.$isShowing)
            }
            .onAppear { viewStore.send(.onAppear) }
            .nightBackground()
        }
    }
}


#Preview {
    SplashScreen(store: .init(initialState: .init()) {
        SplashDomain()
    })
}

struct SplashDomain: Reducer {
    struct State: Equatable {
        @BindingState var isShowing = false
    }
    
    enum Action: Equatable, BindableAction {
        case binding(_ action: BindingAction<State>)
        case onAppear
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
            
            case .onAppear:
                state.isShowing = true
                return .none
            }
        }
    }
}
