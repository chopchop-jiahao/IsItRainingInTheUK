//
//  WeatherImageLoader.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 14/12/2025.
//

import Foundation

public protocol WeatherImageLoader {
    func load(imageWithCode: String) async throws -> Data
}
