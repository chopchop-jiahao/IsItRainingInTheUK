//
//  WeatherImageService.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 14/12/2025.
//

import Foundation

public enum WeatherImageServiceError: Error {
    case invalidResponse
    case invalidImageData
}

public class WeatherImageService: WeatherImageLoader {
    private let session: HTTPSession
    private let imageDataValidator: ImageDataValidator
    private let imageStore: WeatherImagePersistence
    
    public init(session: HTTPSession, imageDataValidator: ImageDataValidator, imageStore: WeatherImagePersistence) {
        self.session = session
        self.imageDataValidator = imageDataValidator
        self.imageStore = imageStore
    }
    
    public func load(imageWithCode code: String) async throws -> Data {
        if let storedData = await imageStore.find(imageWithCode: code), imageDataValidator.isValid(storedData) {
            return storedData
        }
        
        let url = try URLFactory.getImageRequestUrl(withCode: code)
        
        let (data, response) = try await session.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw WeatherImageServiceError.invalidResponse
        }
        
        guard imageDataValidator.isValid(data) else {
            throw WeatherImageServiceError.invalidImageData
        }
        
        imageStore.save(imageData: data, for: code)
        
        return data
    }
}
