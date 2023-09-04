//
//  CurrentTowerClient.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/3/23.
//

import Foundation
import SwiftSoup
import ComposableArchitecture

struct CurrentTowerClient {
    var getCurrentTowerData:() async throws -> [Tower]?
}

extension CurrentTowerClient: DependencyKey {
    static let baseURL = "https://www.esbnyc.com"
    static let calendarEndPoint = "/about/tower-lights"
    
    static var liveValue = CurrentTowerClient(
        getCurrentTowerData: {
            guard let url = URL(string: baseURL + calendarEndPoint) else { throw NetworkError.invalidURL }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print(" ❌ Invalid Response")
                throw NetworkError.invalidResponse
            }
            guard let htmlString = String(data: data, encoding: .utf8) else { return [] }
            
            var towers = [Tower]()
            
            do {
                let html: String = htmlString
                let doc: Document = try SwiftSoup.parse(html)
                let notToday: [Element] = try doc.getElementsByClass("not-today").array()
                var todayImage: String = try doc.getElementsByClass("background-image-wrapper").attr("style")
                todayImage = todayImage.slice(from: "(", to: ")") ?? ""
                print(todayImage)
                let today: [Element]? = try doc.getElementsByClass("is-today").array()
                let dayLight: String? = try today?.first?.select("h3").text()
                let dayDate: String? = try today?.first?.select("h2").text()
                let dayDescription: String? = try today?.first?.select("p").text()

                for today in notToday {
                    let img: String? = try today.select("img").attr("src")
                    let light: String = try today.select("h3").text()
                    let day: String = try today.select("h2").text()
                    let content: String = try today.select("p").text()
                    towers.append(Tower(day: day, image: img ?? "", light: light, content: content))
                }
                
                towers.insert(Tower(day: dayDate,image: baseURL + todayImage, light: dayLight, content: dayDescription), at: 1)

                return towers
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
    )
}

extension CurrentTowerClient: TestDependencyKey {
    static var previewValue = CurrentTowerClient(getCurrentTowerData: {
        return [Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")]
    })
    
    static var testValue = CurrentTowerClient(getCurrentTowerData: {
        return [Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")]
    })
    
}

extension DependencyValues {
    var currentTowerClient: CurrentTowerClient {
        get { self[CurrentTowerClient.self] }
        set { self[CurrentTowerClient.self] = newValue }
    }
}

extension String {
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}
// TODO: widget idea with = square.3.layers.3d and vertical line for widget
