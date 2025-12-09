//
//  WeatherStore.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 09/12/2025.
//

import Foundation

public class WeatherStore: WeatherCache {
    private var cache = [URL: CachedWeatherData]()
    private let currentTime: () -> Date

    public init(currentTime: @escaping () -> Date = Date.init) {
        self.currentTime = currentTime
    }

    public let maxAge: TimeInterval = 600

    /// Returns cached weather data if it exists and hasn't expired.
    public func get(for url: URL) -> OpenWeatherMapData? {
        guard let cachedData = cache[url] else {
            return nil
        }

        return isCacheExpired(from: cachedData.timestamp, to: currentTime()) ? nil : cachedData.data
    }

    /// Stores weather data with a timestamp for the given URL.
    public func set(_ data: OpenWeatherMapData, timestamp: Date, for url: URL) {
        cache[url] = .init(data: data, timestamp: timestamp)
    }

    private func isCacheExpired(from pastTimestamp: Date, to timestamp: Date) -> Bool {
        timestamp.timeIntervalSince(pastTimestamp) >= maxAge
    }
}
