//
//  ContentView.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import SwiftUI
import ComposableArchitecture

struct EmpireStateFeature: Reducer {
    
    
    struct State: Equatable {
        
    }
    
    enum Action: Equatable {
        
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.indigo, .black]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack {
                Text("Date")
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Lights discription")
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
