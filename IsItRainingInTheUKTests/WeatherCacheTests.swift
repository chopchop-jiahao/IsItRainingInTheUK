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
    private var cache = [URL : OpenWeatherMapData]()
    
    func get(for url: URL) -> OpenWeatherMapData? {
        return cache[url]
    }
    
    func set(_ data: OpenWeatherMapData, for url: URL) {
        cache[url] = data
    }
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
        
        try sut.set(openWeatherMapData(from: data), for: url)
        
        XCTAssertNotNil(sut.get(for: url))
    }
    
    private func makeSUT() -> WeatherCache {
        WeatherStore()
    }
    
    private var anyURL: URL {
        URL(string: "any-url")!
    }
}
