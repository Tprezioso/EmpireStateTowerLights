//
//  TowerView.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/15/23.
//

import SwiftUI
import Models

public struct TowerView: View {
    public init(tower: Models.Tower? = nil, isMonthlyView: Bool = false) {
        self.tower = tower
        self.isMonthlyView = isMonthlyView
    }
    public var tower: Models.Tower?
    public var isMonthlyView: Bool = false
    
    public var body: some View {
        if let tower = tower {
            ZStack {
                AsyncImage(url: URL(string: tower.image!)) { phase in
                    if let image = phase.image {
                        GeometryReader { geo in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    } else if phase.error != nil {
                        Image(systemName: "building")
                    } else {
                        ProgressView().progressViewStyle(.circular)
                            .controlSize(.large)
                    }
                }
                
                VStack(alignment: .leading) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tower.light ?? "")
                            .font( isMonthlyView ? .title3 : .largeTitle)
                        
                        Text("\(tower.day ?? "") \(tower.date ?? "")")
                            .font(isMonthlyView ? .caption : .title)
                        Text(tower.content ?? "")
                            .font(isMonthlyView ? .caption : .headline)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

struct TowerView_Previews: PreviewProvider {
    static var previews: some View {
        TowerView(tower: Tower.currentPreview.first)
    }
}
