//
//  NetworkManager.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/30/23.
//

import Foundation
import SwiftSoup
import ComposableArchitecture

struct TowerClient {
    let baseURL = "https://www.esbnyc.com"
        let calendarEndPoint = "/about/tower-lights/calendar"
    var getTowerData:() async throws -> [Tower]?
}

extension TowerClient: DependencyKey {
    static var liveValue = TowerClient(
        getTowerData: {
            guard let url = URL(string: "https://www.esbnyc.com/about/tower-lights/calendar") else { throw NetworkError.invalidURL }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print(" ❌ Invalid Response")
                throw NetworkError.invalidResponse
            }
            guard let htmlString = String(data: data, encoding: .utf8) else { return nil }
            
            var towers = [Tower]()
            
            do {
                let html: String = htmlString
                let doc: Document = try SwiftSoup.parse(html)
                let classes: [Element] = try! doc.getElementsByClass("lse__content").array()
                
                for item in classes {
                    let image: String? = try item.select("img[src]").first()?.attr("src")
                    let day: String? = try item.getElementsByClass("day--day").text()
                    let date: String? = try item.getElementsByClass("day--info").text()
                    let light: String? = try item.getElementsByClass("name").text()
                    let content: String? = try item.getElementsByClass("content").text()
                    //                print(image) // (baseURL + "/sites/default/files/styles/tower_lights_calendar/public/a1r4P00000FhvC0QAJ.jpg?itok=aCd0uGTO")
                    towers.append(Tower(day: day, date: date, image: image, light: light, content: content))
                }
                return towers
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
    )
}

extension DependencyValues {
    var towerClient: TowerClient {
        get { self[TowerClient.self] }
        set { self[TowerClient.self] = newValue }
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}
