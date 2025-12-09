//
//  WeatherCacheTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 09/12/2025.
//

import XCTest
import IsItRainingInTheUK

// test get to return nil if the caches expires
// test set updates the cache
class WeatherStore: WeatherCache {
    private var cache = [URL : CachedWeatherData]()
    let maxAge: TimeInterval = 600
    
    func get(for url: URL) -> OpenWeatherMapData? {
        guard let cachedData = cache[url] else {
            return nil
        }
        
        return isCacheExpired(from: cachedData.timestamp, to: Date.now) ? nil : cachedData.data
    }
    
    func set(_ data: OpenWeatherMapData, timestamp: Date, for url: URL) {
        cache[url] = .init(data: data, timestamp: timestamp)
    }
    
    private func isCacheExpired(from pastTimestamp: Date, to timestamp: Date) -> Bool {
        timestamp.timeIntervalSince(pastTimestamp) > maxAge
    }
}

struct CachedWeatherData {
    let data: OpenWeatherMapData
    let timestamp: Date
}

final class WeatherCacheTests: XCTestCase {
    
    func test_get_returnsNil_whenNoDataStored() {
        let sut =  makeSUT()
        let url = anyURL
        
        let data = sut.get(for: url)
        
        XCTAssertNil(data)
    }
    
    func test_get_returnsStoredData_whenDataIsStored() throws {
        let sut = makeSUT()
        let data = openWeatherMapJsonData()
        let url = anyURL
        
        try sut.set(openWeatherMapData(from: data), timestamp: Date.now, for: url)
        
        XCTAssertNotNil(sut.get(for: url))
    }
    
    func test_get_returnsNil_whenDataExpired() throws {
        let sut = makeSUT()
        let data = openWeatherMapJsonData()
        let url = anyURL
        let timestamp = makeTimestampOnExpiration(expiration: sut.maxAge)
        try sut.set(openWeatherMapData(from: data), timestamp: timestamp, for: url)
        
        let cache = sut.get(for: url)
        
        XCTAssertNil(cache)
    }
    
    private func makeSUT() -> WeatherCache {
        WeatherStore()
    }
    
    private var anyURL: URL {
        URL(string: "any-url")!
    }
    
    private func makeTimestampOnExpiration(expiration: TimeInterval) -> Date {
        Date.now.addingTimeInterval(-expiration)
    }
}
