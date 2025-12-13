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
    case invalidImageData
}

protocol ImageDataValidator {
    func isValid(_ data: Data) -> Bool
}

class WeatherImageService: WeatherImageLoader {
    let session: HTTPSession
    let imageDataValidator: ImageDataValidator
    
    init(session: HTTPSession, imageDataValidator: ImageDataValidator) {
        self.session = session
        self.imageDataValidator = imageDataValidator
    }
    
    func load(imageWithCode code: String) async throws -> Data {
        let url = makeImageRequestUrl(withCode: code)
        
        let (data, response) = try await session.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw WeatherImageServiceError.invalidResponse
        }
        
        guard imageDataValidator.isValid(data) else {
            throw WeatherImageServiceError.invalidImageData
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
 
 delivers image when data valid
 it saves image to store
 delivers image from store
 calls api if file's not in store
 */

final class WeatherImageLoaderTests: XCTestCase {
    
    func test_load_deliversImageData_whenAPIReturnsValidResponseAndImageData() async throws {
        let (sut, session, imageDataValidator) = makeSUT()
        let validResponse = httpResponse(statusCode: 200)
        let imageData = Data()
        imageDataValidator.result = true
        
        try await expect(sut, toCompleteWith: .success(imageData), when: session, completesWith: .success((imageData, validResponse)))
    }
    
    
    func test_load_deliversError_whenAPIReturnsServerError() async throws {
        let (sut, session, _) = makeSUT()
        let serverError = URLError(.badServerResponse) as NSError
        
        try await expect(sut, toCompleteWith: .failure(serverError), when: session, completesWith: .failure(serverError))
    }
    
    func test_load_deliversError_whenAPIReturnsInvalidResponse() async throws {
        let (sut, session, imageDataValidator) = makeSUT()
        let imageData = Data()
        let invalidResponse = httpResponse(statusCode: 201) as URLResponse
        let invalidResponseError = WeatherImageServiceError.invalidResponse as NSError
        imageDataValidator.result = true
        
        
        try await expect(sut, toCompleteWith: .failure(invalidResponseError), when: session, completesWith: .success((imageData, invalidResponse)))
    }
    
    func test_load_deliversError_whenAPIReturnsInvalidImageData() async throws {
        let (sut, session, imageDataValidator) = makeSUT()
        let invalidData = Data()
        let validResponse = httpResponse(statusCode: 200) as URLResponse
        let invalidImageDataError = WeatherImageServiceError.invalidImageData as NSError
        imageDataValidator.result = false
        
        
        try await expect(sut, toCompleteWith: .failure(invalidImageDataError), when: session, completesWith: .success((invalidData, validResponse)))
    }

    // Helpers
    private func makeSUT() -> (WeatherImageLoader, MockSession, MockValidator) {
        let session = MockSession()
        let validator = MockValidator()
        let sut = WeatherImageService(session: session, imageDataValidator: validator)
        return (sut, session, validator)
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
            
            case let (.failure(expectedError as NSError), .failure(receivedError as NSError)):
                XCTAssertEqual(expectedError, receivedError, "Expected to receive \(expectedError), but got \(receivedError) instead", file: file, line: line)
            
            case (.success, .failure), (.failure, .success):
            XCTFail("Expected result: \(expectedResult), but got: \(receivedResult)", file: file, line: line)
        }
    }
}

private class MockSession: HTTPSession, AsyncStubbed {
    var continuations = [CheckedContinuation<(Data, URLResponse), Error>]()
    
    typealias Stub = (Data, URLResponse)
    
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await wait()
    }
}

private class MockValidator: ImageDataValidator {
    var result: Bool = true
    
    func isValid(_ data: Data) -> Bool {
        return result
    }
}
