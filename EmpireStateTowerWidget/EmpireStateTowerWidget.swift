//
//  EmpireStateTowerWidget.swift
//  EmpireStateTowerWidget
//
//  Created by Thomas Prezioso Jr on 9/11/23.
//

import WidgetKit
import SwiftUI
import Intents
import ComposableArchitecture
import CurrentTowerFeature
import Models

struct Provider: TimelineProvider {
    let viewStore: ViewStore<CurrentTowerWidgetFeature.State, CurrentTowerWidgetFeature.Action>
    @Dependency(\.currentTowerClient) var currentTowerClient
    func placeholder(in context: Context) -> SimpleEntry {
        viewStore.send(.onAppear)
        return SimpleEntry(date: Date(), tower: Tower.currentPreview.first!)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
            viewStore.send(.onAppear)
        let entry = SimpleEntry(date: Date(), tower: viewStore.tower!)
            completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            var entries: [SimpleEntry] = []
            let currentDate = Date()
            
            await viewStore.send(.onAppear).finish()
            
            for hourOffset in 0 ..< 5 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let entry = SimpleEntry(date: entryDate, tower: viewStore.tower ?? Tower.currentPreview.first!)
                entries.append(entry)
            }
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tower: Tower
}

struct EmpireStateTowerWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    let store: StoreOf<CurrentTowerWidgetFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                if let uiImage = viewStore.imageData {
                    GeometryReader { geo in
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                } else {
                    Image("defaultBuilding")
                }
                
                VStack {
                    Spacer()
                    Text("\(viewStore.tower?.light ?? "\(Date().formatted(.dateTime.month().day().year()))")")                        
                        .foregroundColor(viewStore.imageData == nil ? .black : .white)
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, viewStore.imageData != nil ? 0 : 10)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .background(Color.black.opacity(0.3))
                        .onAppear { viewStore.send(.onAppear) }
                }
                .padding()
            }
        }
    }
}


struct EmpireStateTowerWidget: Widget {
    let kind: String = "EmpireStateTowerWidget"
    let store = Store(initialState: .init(), reducer: { CurrentTowerWidgetFeature() })
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider(viewStore: ViewStore(self.store, observe: { $0 }))
        ) { _ in
            EmpireStateTowerWidgetEntryView(store: store)
        }
        .configurationDisplayName("Empire State Building Lights")
        .description("I wonder what color the lights are tonight?")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabledIfAvailable()
    }
}

extension WidgetConfiguration
{
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration
    {
        #if compiler(>=5.9) // Xcode 15
            if #available(iOSApplicationExtension 17.0, *) {
                return self.contentMarginsDisabled()
            }
            else {
                return self
            }
        #else
            return self
        #endif
    }
}

struct EmpireStateTowerWidget_Previews: PreviewProvider {
    static var previews: some View {
        EmpireStateTowerWidgetEntryView(store: .init(initialState: .init(), reducer: { CurrentTowerWidgetFeature() }))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

struct CurrentTowerWidgetFeature: Reducer {
    struct State: Equatable {
        var tower: Tower?
        var imageData: UIImage?
    }
    
    enum Action: Equatable {
        case onAppear
        case didReceiveData([Tower], Data)
    }
    
    @Dependency(\.currentTowerClient) var currentTowerClient
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    do {
                        guard let towers = try await currentTowerClient.getCurrentTowerData() else {
                            return
                        }
                        let imageData = try await URLSession.shared.data(from: URL(string: towers[1].image!)!)
                        await send(.didReceiveData(towers, imageData.0))
                    } catch {
                        
                    }
                }
                
            case let .didReceiveData(towers, imageData):
                state.tower = towers[1]
                state.imageData = UIImage(data: imageData)?.resized(toWidth: 1000)
                return .none
            
            }
        }
    }
}

extension UIImage {
    func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}
