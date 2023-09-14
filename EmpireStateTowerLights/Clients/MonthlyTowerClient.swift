//
//  NetworkManager.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/30/23.
//

import Foundation
import SwiftSoup
import ComposableArchitecture

struct MonthlyTowerClient {
    
    var getTowerData:() async throws -> [Tower]?
}

extension MonthlyTowerClient: DependencyKey {
    static let baseURL = "https://www.esbnyc.com"
    static let calendarEndPoint = "/about/tower-lights/calendar"
    
    static var liveValue = MonthlyTowerClient(
        getTowerData: {
            guard let url = URL(string: baseURL + calendarEndPoint) else { throw NetworkError.invalidURL }
            
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
                    towers.append(Tower(day: day, date: date, image: baseURL + (image ?? ""), light: light, content: content))
                }
                return towers
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
    )
}

extension MonthlyTowerClient: TestDependencyKey {
    static var previewValue = MonthlyTowerClient(getTowerData: {
        return [
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")
        ]
    })
    
    static var testValue = MonthlyTowerClient(getTowerData: {
        return [
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")
        ]
    })
    
}

extension DependencyValues {
    var towerClient: MonthlyTowerClient {
        get { self[MonthlyTowerClient.self] }
        set { self[MonthlyTowerClient.self] = newValue }
    }
}

