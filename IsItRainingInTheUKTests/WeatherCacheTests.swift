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
    func get(for url: URL) -> OpenWeatherMapData? {
        return nil
    }
    
    func set(_ data: OpenWeatherMapData, for url: URL) {
        
    }
}

final class WeatherCacheTests: XCTestCase {
    
    func test_get_returnsNil_whenNoDataStored() {
        let sut = WeatherStore()
        
        let data = sut.get(for: anyURL)
        
        XCTAssertNil(data)
    }
    
    
    private var anyURL: URL {
        URL(string: "any-url")!
    }
}
