//
//  WeatherConditionTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 30/11/2025.
//

import XCTest

struct Weather {
    let id: Int
    let main: String
    let description: String
    let icon: String
    
    var condition: WeatherCondition {
        WeatherCondition.from(id: id)
    }
}

enum WeatherCondition {
    case thunderstorm
    case drizzle
    case rain
    case snow
    case atmosphere
    case clear
    case clouds
    
    static func from(id: Int) -> WeatherCondition {
        if group2xx.contains(id) { return .thunderstorm }
        if group3xx.contains(id) { return .drizzle }
        
        return thunderstorm
    }
    
    private static var group2xx: [Int] {
        [200, 201, 202, 210, 211, 212, 221, 230, 231, 232]
    }
    
    private static var group3xx: [Int] {
        [300, 301, 302, 310, 311, 312, 313, 314, 321]
    }
}

final class WeatherConditionTests: XCTestCase {
    
    func test_fromID_whenIDsInGroup2xx_returnsThuderstorm() {
        let group2xx: [Int] = [200, 201, 202, 210, 211, 212, 221, 230, 231, 232]
        
        group2xx.forEach {
            XCTAssertEqual(.thunderstorm, WeatherCondition.from(id: $0))
        }
    }
    
    func test_fromID_whenIDsInGroup3xx_returnsDrizzle() {
        let group3xx: [Int] = [300, 301, 302, 310, 311, 312, 313, 314, 321]
        
        group3xx.forEach {
            XCTAssertEqual(.drizzle, WeatherCondition.from(id: $0))
        }
    }
}
