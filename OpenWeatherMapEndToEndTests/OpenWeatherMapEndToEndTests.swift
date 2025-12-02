//
//  OpenWeatherMapEndToEndTests.swift
//  OpenWeatherMapEndToEndTests
//
//  Created by Jiahao on 01/12/2025.
//

import XCTest
import IsItRainingInTheUK

struct Location {
    let latitude: Double
    let longtitude: Double
}

struct OpenWeatherMapData: Decodable {
    let current: WeatherData
    let hourly: [WeatherData]
}

struct WeatherData: Decodable {
    let dt: Date
    let temp: Double
    let weather: [WeatherDescriptionData]
}

struct WeatherDescriptionData: Decodable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

final class OpenWeatherMapEndToEndTests: XCTestCase {
    
    let baseURL = "https://api.openweathermap.org/data/3.0/onecall"
    let cheltenham = Location(latitude: 50.90, longtitude: -2.06)
    
    func test_openWeatherMapAPI_returnsWeatherMapData() async {
        let session = URLSession.shared
        let url = URL(string: baseURL)!.appending(queryItems: [
            URLQueryItem(name: "lat", value: "\(cheltenham.latitude)"),
            URLQueryItem(name: "lon", value: "\(cheltenham.longtitude)"),
            URLQueryItem(name: "exclude", value: "minutely,daily,alerts"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: OpenWeatherMapAPI.key)
        ])
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            let weatherMapData = try decoder.decode(OpenWeatherMapData.self, from: data)
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200, "expected a 200 response, got \(httpResponse.statusCode) instead")
            XCTAssertEqual(weatherMapData.hourly.count, 48, "Expected 48 hourly forecast data, but got \(weatherMapData.hourly.count) instead")
            
            let currentWeatherData = weatherMapData.current
            XCTAssertNotNil(currentWeatherData, "Expected current weather data, got nil instead")
            XCTAssertNotNil(currentWeatherData.dt, "Expected current weather data to contain a valid timestamp, got nil instead")
            XCTAssertNotNil(currentWeatherData.temp, "Expected current weather data to contain temperature, got nil instead")
            XCTAssertNotNil(currentWeatherData.weather.first, "Expected current weather data to contain weather information, got nil instead")
        } catch {
            XCTFail("Expected the request to succeed, but it failed with error: \(error)")
        }
    }
}
