//
//  WeatherStore.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 09/12/2025.
//

import Foundation

public final class WeatherStore: WeatherCache {
    private var cache = [URL: CachedWeatherData]()
    private let currentTime: () -> Date
    private let queue = DispatchQueue(label: "\(WeatherStore.self)Queue", qos: .userInitiated, attributes: .concurrent)

    public init(currentTime: @escaping () -> Date = Date.init) {
        self.currentTime = currentTime
    }

    public let maxAge: TimeInterval = 600

    /// Returns cached weather data if it exists and hasn't expired.
    public func get(for url: URL) -> OpenWeatherMapData? {
        queue.sync {
            guard let cachedData = cache[url] else {
                return nil
            }

            return isCacheExpired(from: cachedData.timestamp, to: currentTime()) ? nil : cachedData.data
        }
    }

    /// Stores weather data with a timestamp for the given URL.
    public func set(_ data: OpenWeatherMapData, timestamp: Date, for url: URL) {
        queue.async(flags: .barrier) {
            self.cache[url] = .init(data: data, timestamp: timestamp)
        }
    }

    private func isCacheExpired(from pastTimestamp: Date, to timestamp: Date) -> Bool {
        timestamp.timeIntervalSince(pastTimestamp) >= maxAge
    }
}
