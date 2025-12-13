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
        let (sut, _) = makeSUT()
        
        let data = try await sut.load(imageWithCode: "01d")
        
        XCTAssertNotNil(NSImage(data: data))
    }
    
    // Helpers
    private func makeSUT() -> (WeatherImageLoader, MockSession) {
        let session = MockSession()
        let sut = WeatherImageService(session: session)
        return (sut, session)
    }
}

private class MockSession: HTTPSession {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        return (makeMockImageData(), URLResponse())
    }
    
    func makeMockImageData() -> Data {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 1, height: 1))
        image.unlockFocus()
        
        let tiffData = image.tiffRepresentation!
        let bitmap = NSBitmapImageRep(data: tiffData)!
        return bitmap.representation(using: .png, properties: [:])!
    }
}
