//
//  NetworkManager.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/30/23.
//

import Foundation
import SwiftSoup
import ComposableArchitecture

public final class TowerService {
    
    static let shared = TowerService()
    
    public func getTowerData() async throws -> Tower? {
        guard let url = URL(string: "https://www.esbnyc.com/about/tower-lights/calendar") else { throw NetworkError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print(" ❌ Invalid Response")
            throw NetworkError.invalidResponse
        }
        guard let htmlString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
            
        do {
            let html: String = htmlString
            let doc: Document = try SwiftSoup.parse(html)
            let classes: [Element] = try! doc.getElementsByClass("lse__content").array()
            print(classes[0])

            for item in classes {
                let image: String? = try item.select("img[src]").first()?.attr("src")
                print(image)
            }
            
            let images: Element = try doc.select("a").first()!
            let text: String = try doc.body()!.text() // "An example link."
//            let image: String? = try images?.attr("href")
//            let linkHref: String = try link.attr("href") // "http://example.com/"
//            let linkText: String = try link.text() // "example"
//
//            let linkOuterH: String = try link.outerHtml() // "<a href="http://example.com/"><b>example</b></a>"
//            let linkInnerH: String = try link.html() // "<b>example</b>"
            
            return Tower(date: .now, image: "", description: "This Tower is big")
        } catch Exception.Error(let message) {
            print(message)
            
            return nil
        }
    }
    
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
}
