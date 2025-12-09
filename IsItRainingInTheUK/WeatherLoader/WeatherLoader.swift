//
//  WeatherLoader.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 08/12/2025.
//

import Foundation

public protocol WeatherLoader {
    func load(for location: Location) async throws -> OpenWeatherMapData
}
