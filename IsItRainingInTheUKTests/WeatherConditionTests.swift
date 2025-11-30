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
        return thunderstorm
    }
}

final class WeatherConditionTests: XCTestCase {
    
    func test_fromID_whenIDsInGroup2xx_returnsThuderstorm() {
        let group2xx: [Int] = [200, 201, 202, 210, 211, 212, 221, 230, 231, 232]
        
        group2xx.forEach {
            XCTAssertEqual(.thunderstorm, WeatherCondition.from(id: $0))
        }
    }
}
