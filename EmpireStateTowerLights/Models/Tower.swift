//
//  Tower.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import Foundation

public struct Tower: Equatable, Hashable {
    var day: String?
    var date: String?
    var image: String?
    var light: String?
    var content: String?
}

extension Tower {
    static let imageURL = "https://www.esbnyc.com/sites/default/files/styles/260x370/public/2020-01/thumbnail5M2VW4ZF.jpg?itok=3kRhMPZA"
    static let currentPreview = [
        Tower(day: "4", date: "July", image: imageURL, light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July") ,
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")
    ]
    
    static let monthlyPreview = [
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")
    ]
}
