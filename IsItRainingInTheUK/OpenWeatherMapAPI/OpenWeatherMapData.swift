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
    
    public init(current: WeatherData, hourly: [WeatherData]) {
        self.current = current
        self.hourly = hourly
    }
}

public struct WeatherData: Codable, Equatable {
    public let dt: Date
    public let temp: Double
    public let weather: [WeatherDescriptionData]
    
    public init(dt: Date, temp: Double, weather: [WeatherDescriptionData]) {
        self.dt = dt
        self.temp = temp
        self.weather = weather
    }
}

public struct WeatherDescriptionData: Codable, Equatable {
    public let id: Int
    public let main: String
    public let description: String
    public let icon: String
    
    public init(id: Int, main: String, description: String, icon: String) {
        self.id = id
        self.main = main
        self.description = description
        self.icon = icon
    }
}
