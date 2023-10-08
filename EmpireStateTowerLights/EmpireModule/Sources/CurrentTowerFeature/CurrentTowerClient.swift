//
//  CurrentTowerClient.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/3/23.
//

import Foundation
import SwiftSoup
import ComposableArchitecture
import Models

public struct CurrentTowerClient {
    public var getCurrentTowerData:() async throws -> [Tower]?
}

extension CurrentTowerClient: DependencyKey {
    public static let baseURL = "https://www.esbnyc.com"
    public static let calendarEndPoint = "/about/tower-lights"
    
    public static var liveValue = CurrentTowerClient(
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
                let today: [Element]? = try doc.getElementsByClass("is-today").array()
                var dayLight: String? = try today?.first?.select("h3").text()
                let dayDate: String? = try today?.first?.select("h2").text()
                let dayDescription: String? = try today?.first?.select("p").text()
                
                for today in notToday {
                    let img: String? = try today.select("img").attr("src")
                    var light: String = try today.select("h3").text()
                    let day: String = try today.select("h2").text()
                    let content: String = try today.select("p").text()
                    
                    towers.append(Tower(day: day, image: img ?? "", light: light, content: content))
                }
                
                if dayLight?.byWords.last?.lowercased() == "color" {
                    dayLight = dayLight?.components(separatedBy: " ").dropLast().joined(separator: " ")
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
    public static var previewValue = CurrentTowerClient(getCurrentTowerData: {
        return [
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July") ,
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")
        ]
    })
    
    public static var testValue = CurrentTowerClient(getCurrentTowerData: {
        return [
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July") ,
            Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")
        ]
    })
    
}

extension DependencyValues {
    public var currentTowerClient: CurrentTowerClient {
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

extension StringProtocol { // for Swift 4 you need to add the constrain `where Index == String.Index`
    var byWords: [SubSequence] {
        var byWords: [SubSequence] = []
        enumerateSubstrings(in: startIndex..., options: .byWords) { _, range, _, _ in
            byWords.append(self[range])
        }
        return byWords
    }
}
