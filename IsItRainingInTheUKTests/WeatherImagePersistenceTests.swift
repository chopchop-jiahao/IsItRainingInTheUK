//
//  WeatherImagePersistenceTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 14/12/2025.
//

import XCTest
import IsItRainingInTheUK

class WeatherImageStore: WeatherImagePersistence {
    func find(imageWithCode: String) async -> Data? {
        return .none
    }
    
    func save(imageData: Data, for code: String) {
        
    }
}

final class WeatherImagePersistenceTests: XCTestCase {
    
    func test_find_deliversNoData_whenNoImageStored() async throws {
        let sut = makeSUT()
        let code = "code"
        
        let data = await sut.find(imageWithCode: code)
        
        XCTAssertNil(data)
    }
    
    private func makeSUT() -> WeatherImagePersistence {
        WeatherImageStore()
    }
}
