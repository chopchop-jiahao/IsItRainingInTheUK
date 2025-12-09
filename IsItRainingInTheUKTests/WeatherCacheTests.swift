//
//  WeatherCacheTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 09/12/2025.
//

import XCTest
import IsItRainingInTheUK

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
    
    func test_get_returnsNil_whenDataOnExpiration() throws {
        let sut = makeSUT()
        let url = anyURL
        let timestamp = makeTimestampOnExpiration(maxAge: sut.maxAge)
        try sut.set(openWeatherMapData(from: openWeatherMapJsonData()), timestamp: timestamp, for: url)
        
        let cache = sut.get(for: url)
        
        XCTAssertNil(cache)
    }
    
    func test_get_returnsData_whenDataNotExpired() throws {
        let sut = makeSUT()
        let url = anyURL
        let timestamp = makeTimestampBeforeExpiration(maxAge: sut.maxAge)
        try sut.set(openWeatherMapData(from: openWeatherMapJsonData()), timestamp: timestamp, for: url)
        
        let cache = sut.get(for: url)
        
        XCTAssertNotNil(cache)
    }
    
    func test_get_returnsNil_whenDataExpired() throws {
        let sut = makeSUT()
        let url = anyURL
        let timestamp = makeTimestampAfterExpiration(maxAge: sut.maxAge)
        try sut.set(openWeatherMapData(from: openWeatherMapJsonData()), timestamp: timestamp, for: url)
        
        let cache = sut.get(for: url)
        
        XCTAssertNil(cache)
    }
    
    private func makeSUT() -> WeatherCache {
        WeatherStore()
    }
    
    private var anyURL: URL {
        URL(string: "any-url")!
    }
    
    private func makeTimestampOnExpiration(maxAge: TimeInterval) -> Date {
        Date.now.addingTimeInterval(-maxAge)
    }
    
    private func makeTimestampBeforeExpiration(maxAge: TimeInterval) -> Date {
        Date.now.addingTimeInterval(-maxAge + 1)
    }
    
    private func makeTimestampAfterExpiration(maxAge: TimeInterval) -> Date {
        Date.now.addingTimeInterval(-maxAge - 1)
    }
}
