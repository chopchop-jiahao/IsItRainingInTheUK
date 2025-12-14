//
//  WeatherImageLoaderTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 13/12/2025.
//

import XCTest
import IsItRainingInTheUK

final class WeatherImageLoaderTests: XCTestCase {
    
    func test_load_deliversImageData_whenAPIReturnsValidResponseAndImageData() async throws {
        let (sut, session, imageDataValidator, _) = makeSUT()
        let validResponse = httpResponse(statusCode: 200)
        let imageData = anyImageData()
        imageDataValidator.stub(validationResults: [true])
        
        try await expect(sut, toCompleteWith: .success(imageData), when: session, completesWith: .success((imageData, validResponse)))
    }
    
    
    func test_load_deliversError_whenAPIReturnsServerError() async throws {
        let (sut, session, _, _) = makeSUT()
        let serverError = URLError(.badServerResponse) as NSError
        
        try await expect(sut, toCompleteWith: .failure(serverError), when: session, completesWith: .failure(serverError))
    }
    
    func test_load_deliversError_whenAPIReturnsInvalidResponse() async throws {
        let (sut, session, imageDataValidator, _) = makeSUT()
        let imageData = anyImageData()
        let invalidResponse = httpResponse(statusCode: 201) as URLResponse
        let invalidResponseError = WeatherImageServiceError.invalidResponse as NSError
        imageDataValidator.stub(validationResults: [true])
        
        
        try await expect(sut, toCompleteWith: .failure(invalidResponseError), when: session, completesWith: .success((imageData, invalidResponse)))
    }
    
    func test_load_deliversError_whenAPIReturnsInvalidImageData() async throws {
        let (sut, session, imageDataValidator, _) = makeSUT()
        let invalidData = "invalid data".data(using: .utf8)!
        let validResponse = httpResponse(statusCode: 200) as URLResponse
        let invalidImageDataError = WeatherImageServiceError.invalidImageData as NSError
        imageDataValidator.stub(validationResults: [false])
        
        
        try await expect(sut, toCompleteWith: .failure(invalidImageDataError), when: session, completesWith: .success((invalidData, validResponse)))
    }
    
    func test_load_callsAPIAndSavesImage_whenImageNotFoundInStore() async throws {
        let (sut, session, imageDataValidator, store) = makeSUT()
        let imageData = anyImageData()
        let validResponse = httpResponse(statusCode: 200) as URLResponse
        imageDataValidator.stub(validationResults: [true])
        
        
        try await expect(sut, toCompleteWith: .success(imageData), when: session, completesWith: .success((imageData, validResponse)))
        
        XCTAssertEqual([.find, .save], store.actions, "Expected store to find image and store it after a successful API call, but the actions are \(store.actions)")
        
        XCTAssertEqual(1, session.continuations.count, "Expected session to call API once, but it was called \(session.continuations.count) times")
    }
    
    func test_load_callsAPIAndStoresImage_whenImageIsInvalidInStore() async throws {
        let (sut, session, imageDataValidator, store) = makeSUT()
        let code = "01d"
        let imageData = anyImageData()
        let validResponse = httpResponse(statusCode: 200) as URLResponse
        store.stubImage(code: code)
        imageDataValidator.stub(validationResults: [false, true])
        
        
        try await expect(sut, toLoadImageForCode: code, toCompleteWith: .success(imageData), when: session, completesWith: .success((imageData, validResponse)))
        
        XCTAssertEqual([.find, .save], store.actions, "Expected store to find image and store it after a successful API call, but the actions are \(store.actions)")
        
        XCTAssertEqual(1, session.continuations.count, "Expected session to call API once, but it was called \(session.continuations.count) times")
    }

    func test_load_retrievesFromStoreAndDoesNotCallAPI_whenImageFoundInStore() async throws {
        let (sut, session, imageDataValidator, store) = makeSUT()
        let code = "01d"
        store.stubImage(code: code)
        imageDataValidator.stub(validationResults: [true])
        
        let data = try await sut.load(imageWithCode: code)
        
        XCTAssertNotNil(data, "Expected to retrieve image data, but found nil instead")
        
        XCTAssertEqual([.find], store.actions, "Expected store to find image and return it, but the actions are \(store.actions)")
        
        XCTAssertEqual(0, session.continuations.count, "Expected session not to call API, but it was called \(session.continuations.count) times")
    }
    
    // Helpers
    private func makeSUT() -> (WeatherImageLoader, MockSession, MockValidator, MockImageStore) {
        let session = MockSession()
        let validator = MockValidator()
        let imageStore = MockImageStore()
        let sut = WeatherImageService(session: session, imageDataValidator: validator, imageStore: imageStore)
        
        trackForMemoryLeaks(session)
        trackForMemoryLeaks(validator)
        trackForMemoryLeaks(imageStore)
        trackForMemoryLeaks(sut)
        
        return (sut, session, validator, imageStore)
    }
    
    private func expect(_ sut: WeatherImageLoader,
                        toLoadImageForCode code: String = "01d",
                        toCompleteWith expectedResult: Result<Data, Error>,
                        when session: MockSession,
                        completesWith stub: Result<(Data, URLResponse), Error>,
                        at index: Int = 0,
                        file: StaticString = #file,
                        line: UInt = #line) async throws {
        
        let load =  Task {
            try await sut.load(imageWithCode: code)
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
    
    private func anyImageData() -> Data {
        Data()
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
    var results = [Bool]()
    private var deliverIndex: Int  = 0
    
    func isValid(_ data: Data) -> Bool {
        guard deliverIndex <= results.count else {
            XCTFail("MockValidator: not enough stubbed results")
            return false
        }
        
        let result = results[deliverIndex]
        
        deliverIndex += 1
        
        return result
    }
    
    func stub(validationResults: [Bool]) {
        results.append(contentsOf: validationResults)
    }
}

private class MockImageStore: WeatherImagePersistence {
    public private(set) var actions = [Action]()
    var images = [String]()
    
    func find(imageWithCode code: String) async -> Data? {
        actions.append(.find)
        
        let imageExists = images.first { $0 == code } != nil
        
        return imageExists ? Data() : nil
    }
    
    func save(imageData: Data, for code: String) {
        actions.append(.save)
        images.append(code)
    }
    
    func stubImage(code: String) {
        images.append(code)
    }
    
    enum Action: Equatable {
        case find
        case save
    }
}
