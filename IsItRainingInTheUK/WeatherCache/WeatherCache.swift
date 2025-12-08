//
//  WeatherCache.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 08/12/2025.
//

import Foundation

// test get to return nil if the caches expires
// test set updates the cache
public protocol WeatherCache {
    func get(for url: URL) -> OpenWeatherMapData?
    func set(_ data: OpenWeatherMapData, for url: URL)
}
