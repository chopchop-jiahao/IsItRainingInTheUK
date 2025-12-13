//
//  WeatherImageLoaderTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 13/12/2025.
//

import XCTest
import IsItRainingInTheUK

protocol WeatherImageLoader {
    func load(imageWithCode: String) async throws -> Data
}

enum WeatherImageServiceError: Error {
    case invalidResponse
}

class WeatherImageService: WeatherImageLoader {
    let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func load(imageWithCode code: String) async throws -> Data {
        let url = makeImageRequestUrl(withCode: code)
        
        let (data, response) = try await session.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw WeatherImageServiceError.invalidResponse
        }
        
        return data
    }
    
    private func makeImageRequestUrl(withCode code: String) -> URL {
        return URL(string: String(format: OpenWeatherMapAPI.imageURL, code))!
    }
}

/*
 load weather image  with icon name
 if the image can be found in store, returns from store
 if not, calling api and store the image, and return the image data
 
 delivers error when not valid image data
 delivers image when data valid
 it saves image to store
 delivers image from store
 calls api if file's not in store
 */

final class WeatherImageLoaderTests: XCTestCase {
    
    func test_load_deliversImageData_whenAPIReturnsValidResponseAndImageData() async throws {
        let (sut, session) = makeSUT()
        let validResponse = httpResponse(statusCode: 200)
        let imageData = makeMockImageData()
        
        try await expect(sut, toCompleteWith: .success(imageData), when: session, completesWith: .success((imageData, validResponse)))
    }
    
    
    func test_load_deliversError_whenAPIReturnsServerError() async throws {
        let (sut, session) = makeSUT()
        let serverError = URLError(.badServerResponse) as NSError
        
        try await expect(sut, toCompleteWith: .failure(serverError), when: session, completesWith: .failure(serverError))
    }
    
    func test_load_deliversError_whenAPIReturnsInvalidResponse() async throws {
        let (sut, session) = makeSUT()
        let imageData = makeMockImageData()
        let invalidResponse = httpResponse(statusCode: 201) as URLResponse
        let invalidResponseError = WeatherImageServiceError.invalidResponse as NSError
        
        
        try await expect(sut, toCompleteWith: .failure(invalidResponseError), when: session, completesWith: .success((imageData, invalidResponse)))
    }

    // Helpers
    private func makeSUT() -> (WeatherImageLoader, MockSession) {
        let session = MockSession()
        let sut = WeatherImageService(session: session)
        return (sut, session)
    }
    
    private func expect(_ sut: WeatherImageLoader,
                        toCompleteWith expectedResult: Result<Data, Error>,
                        when session: MockSession,
                        completesWith stub: Result<(Data, URLResponse), Error>,
                        at index: Int = 0,
                        file: StaticString = #file,
                        line: UInt = #line) async throws {
        
        let load =  Task {
            try await sut.load(imageWithCode: "01d")
        }
        
        try await session.complete(with: stub, at: index)
        
        let receivedResult = await Result(asyncCatching: {
            try await load.value
        })
        
        switch (expectedResult, receivedResult) {
            case let (.success(expectedData), .success(receivedData)):
                XCTAssertEqual(expectedData, receivedData, "Expected to get \(expectedData), but got \(receivedData) instead", file: file, line: line)
            
                XCTAssertNotNil(NSImage(data: receivedData), "Expected to get valid image data, but found invalid image data instead", file: file, line: line)
            
            case let (.failure(expectedError as NSError), .failure(receivedError as NSError)):
                XCTAssertEqual(expectedError, receivedError, "Expected to receive \(expectedError), but got \(receivedError) instead", file: file, line: line)
            
            case (.success, .failure), (.failure, .success):
            XCTFail("Expected result: \(expectedResult), but got: \(receivedResult)", file: file, line: line)
        }
    }
    
    private func makeMockImageData() -> Data {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 1, height: 1))
        image.unlockFocus()
        
        let tiffData = image.tiffRepresentation!
        let bitmap = NSBitmapImageRep(data: tiffData)!
        return bitmap.representation(using: .png, properties: [:])!
    }
}

private class MockSession: HTTPSession, AsyncStubbed {
    var continuations = [CheckedContinuation<(Data, URLResponse), Error>]()
    
    typealias Stub = (Data, URLResponse)
    
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await wait()
    }
}
