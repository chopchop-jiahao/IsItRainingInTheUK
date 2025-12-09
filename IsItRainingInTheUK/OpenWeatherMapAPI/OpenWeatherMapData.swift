//
//  OpenWeatherMapData.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 02/12/2025.
//

import Foundation

public struct OpenWeatherMapData: Codable, Equatable {
    public let current: WeatherData
    public let hourly: [WeatherData]
}

public struct WeatherData: Codable, Equatable {
    public let dt: Date
    public let temp: Double
    public let weather: [WeatherDescriptionData]
}

public struct WeatherDescriptionData: Codable, Equatable {
    public let id: Int
    public let main: String
    public let description: String
    public let icon: String
}
