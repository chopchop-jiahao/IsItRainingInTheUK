//
//  WeatherImagePersistenceTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 14/12/2025.
//

import XCTest
import IsItRainingInTheUK

class WeatherImageStore: WeatherImagePersistence {
    private let fileManager: FileManager
    private let storeURL: URL
    
    init(fileManager: FileManager = .default, storeURL: URL) {
        self.fileManager = fileManager
        self.storeURL = storeURL
    }
    
    func find(imageWithCode code: String) async -> Data? {
        let fileURL = storeURL.appendingPathComponent(code)
        
        return try? Data(contentsOf: fileURL)
    }
    
    func save(imageData: Data, for code: String) {
        let fileURL = storeURL.appendingPathComponent(code)
        
        try? fileManager.createDirectory(at: storeURL, withIntermediateDirectories: true)
        
        try? imageData.write(to: fileURL)
    }
}

final class WeatherImagePersistenceTests: XCTestCase {
    
    override func setUp() {
        clearStoreArtefacts()
    }
    
    override func tearDown() {
        clearStoreArtefacts()
    }
    
    func test_find_deliversNoData_whenNoImageStoredForCode() async throws {
        let sut = makeSUT()
        let code = "code"
        
        try await expect(sut, toRetrieve: .none, withCode: code)
    }
    
    func test_find_hasNoSideEeffects_whenImageExists() async throws {
        let sut = makeSUT()
        let code = "code"
        let expectedData = anyData()
        
        sut.save(imageData: expectedData, for: code)
        
        try await expect(sut, toRetrieve: expectedData, withCode: code)
        try await expect(sut, toRetrieve: expectedData, withCode: code)
    }
    
    func test_save_storesDataToStore() async throws {
        let sut = makeSUT()
        let code = "code"
        let expectedData = anyData()
        
        sut.save(imageData: expectedData, for: code)
        
        let retrievedData = await sut.find(imageWithCode: code)
        
        XCTAssertEqual(expectedData, retrievedData, "Expected to retrieve \(expectedData), but got \(String(describing: retrievedData)) instead")
    }
    
    // Helpers
    
    private func makeSUT() -> WeatherImagePersistence {
        WeatherImageStore(storeURL: testURL)
    }
    
    private func expect(_ sut: WeatherImagePersistence, toRetrieve expectedData: Data?, withCode code: String, file: StaticString = #file, line: UInt = #line) async throws {
        let retrievedData = await sut.find(imageWithCode: code)
        
        XCTAssertEqual(expectedData, retrievedData, "Expected to retrieve \(String(describing: expectedData)), but got \(String(describing: retrievedData)) instead", file: file, line: line)
    }
    
    private func anyData() -> Data {
        Data("image".utf8)
    }
    
    private var testURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(WeatherImagePersistenceTests.self)")
    }
    
    private func clearStoreArtefacts() {
        try? FileManager.default.removeItem(at: testURL)
    }
}
