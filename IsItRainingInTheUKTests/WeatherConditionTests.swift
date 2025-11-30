//
//  WeatherConditionTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 30/11/2025.
//

import XCTest
import IsItRainingInTheUK

struct Weather {
    let id: Int
    let main: String
    let description: String
    let icon: String
    
    var condition: WeatherCondition {
        WeatherCondition.from(id: id)
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
    
    func test_fromID_whenIDsInGroup5xx_returnsRain() {
        let group5xx: [Int] = [500, 502, 503, 504, 511, 520, 521, 522, 531]
        
        group5xx.forEach {
            XCTAssertEqual(.rain, WeatherCondition.from(id: $0))
        }
    }
    
    func test_fromID_whenIDsInGroup6xx_returnsSnow() {
        let group6xx: [Int] = [600, 601, 602, 611, 611, 613, 615, 616, 620, 621, 622]
        
        group6xx.forEach {
            XCTAssertEqual(.snow, WeatherCondition.from(id: $0))
        }
    }
    
    func test_fromID_whenIDsInGroup7xx_returnsAtmosphere() {
        let group7xx: [Int] = [701, 711, 721, 731, 741, 751, 761, 762, 771, 781]
        
        group7xx.forEach {
            XCTAssertEqual(.atmosphere, WeatherCondition.from(id: $0))
        }
    }
    
    func test_fromID_whenClearSkyId_returnsClear() {
        XCTAssertEqual(.clear, WeatherCondition.from(id: 800))
    }
    
    func test_fromID_whenIDsGroup80x_returnsClouds() {
        let group80x: [Int] = [801, 802, 803, 804]
        
        group80x.forEach {
            XCTAssertEqual(.clouds, WeatherCondition.from(id: $0))
        }
    }
    
    func test_fromID_whenUnknownID_returnsUnknown() {
        XCTAssertEqual(.unknown, WeatherCondition.from(id: 999))
    }
}
