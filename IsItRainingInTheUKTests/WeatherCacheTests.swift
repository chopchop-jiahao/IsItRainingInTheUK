//
//  WeatherCacheTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 09/12/2025.
//

import IsItRainingInTheUK
import XCTest

final class WeatherCacheTests: XCTestCase {
    func test_get_returnsNil_whenNoDataStored() {
        let sut = makeSUT()
        let url = anyURL
        
        expect(sut, toGet: .none, for: url)
    }

    func test_get_returnsStoredData_whenDataIsStored() throws {
        let sut = makeSUT()
        let url = anyURL
        let expectedData = try! openWeatherMapData(from: openWeatherMapJsonData())

        sut.set(expectedData, timestamp: Date.now, for: url)

        expect(sut, toGet: expectedData, for: url)
    }

    func test_get_returnsNoData_whenDataOnExpiration() throws {
        let now = Date.now
        let sut = makeSUT(currentTime: { now })
        let url = anyURL
        let data = try! openWeatherMapData(from: openWeatherMapJsonData())
        let timestamp = makeTimestampOnExpiration(from: now, maxAge: sut.maxAge)
        sut.set(data, timestamp: timestamp, for: url)

        expect(sut, toGet: .none, for: url)
    }

    func test_get_returnsData_whenDataNotExpired() throws {
        let now = Date.now
        let sut = makeSUT(currentTime: { now })
        let url = anyURL
        let expectedData = try! openWeatherMapData(from: openWeatherMapJsonData())
        let timestamp = makeTimestampBeforeExpiration(from: now, maxAge: sut.maxAge)
        sut.set(expectedData, timestamp: timestamp, for: url)

        expect(sut, toGet: expectedData, for: url)
    }

    func test_get_returnsNoData_whenDataExpired() throws {
        let now = Date.now
        let sut = makeSUT(currentTime: { now })
        let url = anyURL
        let data = try! openWeatherMapData(from: openWeatherMapJsonData())
        let timestamp = makeTimestampAfterExpiration(from: now, maxAge: sut.maxAge)
        sut.set(data, timestamp: timestamp, for: url)

        expect(sut, toGet: .none, for: url)
    }

    func test_set_executesExclusively_blocksConcurrentOperations() async throws {
        let sut = makeSUT()

        let concurrentCaller1 = Task {
            for _ in 0 ... 3 {
                try sut.set(openWeatherMapData(from: openWeatherMapJsonData()), timestamp: Date(), for: anyURL)
            }
        }

        let concurrentCaller2 = Task {
            for _ in 0 ... 3 {
                try sut.set(openWeatherMapData(from: openWeatherMapJsonData()), timestamp: Date(), for: anyURL)
            }
        }

        _ = try await (concurrentCaller1.value, concurrentCaller2.value)

        let result = sut.get(for: anyURL)
        XCTAssertNotNil(result, "Expected data to be intact after concurrent operations")
    }

    private func makeSUT(currentTime: @escaping () -> Date = Date.init) -> WeatherCache {
        WeatherStore(currentTime: currentTime)
    }
    
    private func expect(_ sut: WeatherCache, toGet expectedData: OpenWeatherMapData?, for url: URL, file: StaticString = #file, line: UInt = #line) {
        
        let retrievedData = sut.get(for: url)
        
        XCTAssertEqual(expectedData, retrievedData, "Expected to retrieve \(String(describing: expectedData)), but got \(String(describing: retrievedData)) instead", file: file, line: line)
    }

    private var anyURL: URL {
        URL(string: "any-url")!
    }

    private func makeTimestampOnExpiration(from timestamp: Date, maxAge: TimeInterval) -> Date {
        timestamp.addingTimeInterval(-maxAge)
    }

    private func makeTimestampBeforeExpiration(from timestamp: Date, maxAge: TimeInterval) -> Date {
        timestamp.addingTimeInterval(-maxAge + 1)
    }

    private func makeTimestampAfterExpiration(from timestamp: Date, maxAge: TimeInterval) -> Date {
        timestamp.addingTimeInterval(-maxAge - 1)
    }
}
