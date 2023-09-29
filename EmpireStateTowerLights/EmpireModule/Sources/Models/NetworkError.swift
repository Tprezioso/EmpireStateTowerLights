//
//  NetworkError.swift
//  EmpireStateTowerLights
//
//  Created by Thomas Prezioso Jr on 9/12/23.
//

import Foundation

public enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case invalidData
}
