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

    func test_setAndGet_withConcurrentAccess_shouldPreventRaceCondition() async throws {
        let sut = makeSUT()
        let url = anyURL
        let expectedData = try! openWeatherMapData(from: openWeatherMapJsonData())
        // Set the cache first so if read task starts before write, it won't get nil
        sut.set(expectedData, timestamp: Date.now, for: url)

        let write = Task {
            for _ in 0 ... 5 {
                sut.set(expectedData, timestamp: Date.now, for: url)
            }
        }

        let read = Task {
            for _ in 0 ... 5 {
                expect(sut, toGet: expectedData, for: url)
            }
        }

        _ = await (write.value, read.value)
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
