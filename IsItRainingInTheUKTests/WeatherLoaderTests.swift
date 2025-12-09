//
//  WeatherLoaderTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 06/12/2025.
//

import IsItRainingInTheUK
import XCTest

final class WeatherLoaderTests: XCTestCase {
    func test_load_deliversWeatherData() async throws {
        let (session, sut, _) = makeSUT()
        let location = cheltenham
        let url = try URLFactory.getURL(for: location)
        let testData = openWeatherMapJsonData()
        let expectedData = try openWeatherMapData(from: testData)
        session.stubs[url] = .success((testData, httpResponse(statusCode: 200)))

        await expect(sut, toRetrieve: .success(expectedData), for: location)
    }

    func test_load_deliverError_whenAPIReturnsError() async throws {
        let (session, sut, _) = makeSUT()
        let location = cheltenham
        let url = try URLFactory.getURL(for: location)
        let serverError = URLError(.badServerResponse)
        session.stubs[url] = .failure(serverError)

        await expect(sut, toRetrieve: .failure(serverError), for: location)
    }

    func test_load_deliversError_whenAPIReturnsInvalidData() async throws {
        let (session, sut, _) = makeSUT()
        let location = cheltenham
        let url = try URLFactory.getURL(for: location)
        let testData = "Invalid json data".data(using: .utf8)!
        session.stubs[url] = .success((testData, httpResponse(statusCode: 200)))

        await expect(sut, toRetrieve: .failure(WeatherServiceError.invalidData), for: location)
    }

    func test_load_deliversError_whenAPIReturnsInvalidResponse() async throws {
        let (session, sut, _) = makeSUT()
        let location = cheltenham
        let url = try URLFactory.getURL(for: location)
        let testData = "Invalid json data".data(using: .utf8)!
        session.stubs[url] = .success((testData, httpResponse(statusCode: 201)))

        await expect(sut, toRetrieve: .failure(WeatherServiceError.invalidResponse), for: location)
    }

    func test_load_cachesData_AfterRetrievingDataFromAPI() async throws {
        let (session, sut, store) = makeSUT()
        let location = cheltenham
        let url = try URLFactory.getURL(for: location)
        let testData = openWeatherMapJsonData()
        let expectedData = try openWeatherMapData(from: testData)
        session.stubs[url] = .success((testData, httpResponse(statusCode: 200)))

        await expect(sut, toRetrieve: .success(expectedData), for: location)

        XCTAssertEqual([url], session.calls, "Expected to perform a single request to the API")
        XCTAssertEqual([.get, .set], store.actions, "Expected store to be called twice: once for the original retrieval and once for the cached data, but the actions are \(store.actions)")
    }

    func test_load_retrieveDataFromStore_whenThereIsCachedData() async throws {
        let (session, sut, store) = makeSUT()
        let location = cheltenham
        let url = try URLFactory.getURL(for: location)
        let testData = openWeatherMapJsonData()
        let expectedData = try openWeatherMapData(from: testData)
        store.stub(expectedData, for: url)

        await expect(sut, toRetrieve: .success(expectedData), for: location)

        XCTAssertEqual([], session.calls, "Expected no calls to the API, but found \(session.calls) calls instead")
        XCTAssertEqual([.get], store.actions, "Expected get to be called to retrieve cached data, but the actions are \(store.actions)")
    }

    // Helpers
    private func makeSUT() -> (session: MockSession, WeatherLoader, store: MockStore) {
        let session = MockSession()
        let store = MockStore()
        return (session, WeatherService(session: session, store: store), store)
    }

    private func expect(_ sut: WeatherLoader, toRetrieve expectedResult: Result<OpenWeatherMapData, Error>, for location: Location, file: StaticString = #file, line: UInt = #line) async {
        let retrievedResult = await Result(asyncCatching: {
            try await sut.load(for: location)
        })

        switch (expectedResult, retrievedResult) {
            case let (.success(expectedData), .success(retrievedData)):
                XCTAssertEqual(expectedData, retrievedData, "Expected to retrieve \(expectedData), but got \(retrievedData) instead", file: file, line: line)

            case let (.failure(expectedError as NSError), .failure(retrievedError as NSError)):
                XCTAssertEqual(expectedError.code, retrievedError.code, "Expected to retrieve error with code \(expectedError.code), but got \(retrievedError.code) instead", file: file, line: line)
                XCTAssertEqual(expectedError.domain, retrievedError.domain, "Expected to retrieve error with domain \(expectedError.domain), but got \(retrievedError.domain) instead", file: file, line: line)

            case let (.success, .failure(retrievedError)):
                XCTFail("Expected the load to succeed, but got a failure with \(retrievedError) instead.", file: file, line: line)

            case let (.failure, .success(retrievedWeatherData)):
                XCTFail("Expected the load to fail, but got a succes with \(retrievedWeatherData) instead", file: file, line: line)
        }
    }

    private var cheltenham: Location {
        Location(latitude: 51.90, longitude: -2.07)
    }

    private func httpResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "http://my-url.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

extension Result {
    init(asyncCatching body: () async throws -> Success) async where Failure == Error {
        do {
            let result = try await body()
            self = .success(result)
        } catch {
            self = .failure(error)
        }
    }
}

private class MockSession: HTTPSession {
    var stubs = [URL: Result<(Data, URLResponse), Error>]()
    var calls = [URL]()

    func data(from url: URL) async throws -> (Data, URLResponse) {
        guard let result = stubs[url] else {
            throw URLError(.badServerResponse)
        }

        calls.append(url)

        switch result {
            case let .success((data, response)):
                return (data, response)
            case let .failure(error):
                throw error
        }
    }
}

private class MockStore: WeatherCache {
    var actions = [WeatherCacheAction]()
    private var storage = [URL: OpenWeatherMapData]()

    func get(for url: URL) -> OpenWeatherMapData? {
        actions.append(.get)
        return storage[url]
    }

    func set(_ data: OpenWeatherMapData, for url: URL) {
        actions.append(.set)
        storage[url] = data
    }

    func stub(_ data: OpenWeatherMapData, for url: URL) {
        storage[url] = data
    }
}
