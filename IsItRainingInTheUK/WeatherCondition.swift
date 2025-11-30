//
//  WeatherCondition.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 30/11/2025.
//

public enum WeatherCondition {
    case thunderstorm
    case drizzle
    case rain
    case snow
    case atmosphere
    case clear
    case clouds
    case unknown
    
    public static func from(id: Int) -> WeatherCondition {
        if group2xx.contains(id) { return .thunderstorm }
        
        if group3xx.contains(id) { return .drizzle }
        
        if group5xx.contains(id) { return .rain }
        
        if group6xx.contains(id) { return .snow }
        
        if group7xx.contains(id) { return .atmosphere }
        
        if id == clearSkyId { return .clear }
        
        if group80x.contains(id) { return .clouds }
        
        return unknown
    }
    
    private static var group2xx: [Int] {
        [200, 201, 202, 210, 211, 212, 221, 230, 231, 232]
    }
    
    private static var group3xx: [Int] {
        [300, 301, 302, 310, 311, 312, 313, 314, 321]
    }
    
    private static var group5xx: [Int] {
        [500, 502, 503, 504, 511, 520, 521, 522, 531]
    }
    
    private static var group6xx: [Int] {
        [600, 601, 602, 611, 611, 613, 615, 616, 620, 621, 622]
    }
    
    private static var group7xx: [Int] {
        [701, 711, 721, 731, 741, 751, 761, 762, 771, 781]
    }
    
    private static var clearSkyId: Int {
        800
    }
    
    private static var group80x: [Int] {
        [801, 802, 803, 804]
    }
}
