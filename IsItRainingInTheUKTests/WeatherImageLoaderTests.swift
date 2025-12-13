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

class WeatherImageService: WeatherImageLoader {
    let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func load(imageWithCode code: String) async throws -> Data {
        let url = makeImageRequestUrl(withCode: code)
        
        let (data, _) = try await session.data(from: url)
        
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
 
 delivers error when there's a server error
 delivers error when not 200
 delivers error when not valid image data
 delivers image when data valid
 it saves image to store
 delivers image from store
 calls api if file's not in store
 */

final class WeatherImageLoaderTests: XCTestCase {
    
    func test_load_returnsImageDataFromAPI() async throws {
        let (sut, session) = makeSUT()
        let imageData = makeMockImageData()
        
        let load =  Task {
            try await sut.load(imageWithCode: "01d")
        }
        
        try await session.complete(with: .success((imageData, URLResponse())), at: 0)
        
        let data = try await load.value
        
        XCTAssertNotNil(NSImage(data: data))
    }
    
    
    func test_load_deliversErrorOnServerError() async throws {
        let (sut, session) = makeSUT()
        let serverError = URLError(.badServerResponse) as NSError
        
        
        let load =  Task {
            try await sut.load(imageWithCode: "01d")
        }
        
        try await session.complete(with: .failure(serverError), at: 0)
        
        do {
            _ = try await load.value
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(serverError, nsError)
        }
    }

    // Helpers
    private func makeSUT() -> (WeatherImageLoader, MockSession) {
        let session = MockSession()
        let sut = WeatherImageService(session: session)
        return (sut, session)
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
