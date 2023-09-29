//
//  Tower.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 8/29/23.
//

import Foundation

public struct Tower: Equatable, Hashable {
   public var day: String?
   public var date: String?
   public var image: String?
   public var light: String?
   public var content: String?
    
    public init(day: String? = nil, date: String? = nil, image: String? = nil, light: String? = nil, content: String? = nil) {
        self.day = day
        self.date = date
        self.image = image
        self.light = light
        self.content = content
    }
}

extension Tower {
    public static let imageURL = "https://www.esbnyc.com/sites/default/files/styles/260x370/public/2020-01/thumbnail5M2VW4ZF.jpg?itok=3kRhMPZA"
    public static let currentPreview = [
        Tower(day: "4", date: "July", image: imageURL, light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July") ,
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")
    ]
    
    public static let monthlyPreview = [
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July"),
        Tower(day: "4", date: "July", image: "", light: "Red, White, and Blue", content: "Forth Of July")
    ]
}
