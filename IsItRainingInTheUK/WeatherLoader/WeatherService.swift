//
//  WeatherService.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 08/12/2025.
//

import Foundation

public enum WeatherServiceError: Error {
    case invalidData
    case invalidResponse
}

public final class WeatherService: WeatherLoader {
    let session: HTTPSession
    let store: WeatherCache
    
    public init(session: HTTPSession, store: WeatherCache) {
        self.session = session
        self.store = store
    }
    
    public func load(for location: Location) async throws -> OpenWeatherMapData {
        let url = try URLFactory.getURL(for: location)
        
        if let weatherData = store.get(for: url) {
            return weatherData
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw WeatherServiceError.invalidResponse
        }
        
        guard let weatherData = try? JSONDecoder().decode(OpenWeatherMapData.self, from: data) else {
            throw WeatherServiceError.invalidData
        }
        
        store.set(weatherData, for: url)
        
        return weatherData
    }
}
