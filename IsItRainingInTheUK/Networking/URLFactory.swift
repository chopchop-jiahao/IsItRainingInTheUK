//
//  URLFactory.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 08/12/2025.
//

import Foundation

enum URLFactoryError: Error {
    case invalidURL
}

enum URLFactory {
    static func getURL(for location: Location) throws -> URL {
        guard let baseURL = URL(string: OpenWeatherMapAPI.baseURL) else {
            throw URLFactoryError.invalidURL
        }

        return baseURL.appending(queryItems: [
            URLQueryItem(name: "lat", value: "\(location.latitude)"),
            URLQueryItem(name: "lon", value: "\(location.longitude)"),
            URLQueryItem(name: "exclude", value: "minutely,daily,alerts"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: OpenWeatherMapAPI.key)
        ])
    }

    static func getImageRequestUrl(withCode code: String) throws -> URL {
        guard let url = URL(string: String(format: OpenWeatherMapAPI.imageURL, code)) else {
            throw URLFactoryError.invalidURL
        }

        return url
    }
}
