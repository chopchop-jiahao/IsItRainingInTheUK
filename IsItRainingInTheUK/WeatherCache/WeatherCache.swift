//
//  WeatherCache.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 08/12/2025.
//

import Foundation

public protocol WeatherCache {
    var maxAge: TimeInterval { get }
    func get(for url: URL) -> OpenWeatherMapData?
    func set(_ data: OpenWeatherMapData, timestamp: Date, for url: URL)
}
