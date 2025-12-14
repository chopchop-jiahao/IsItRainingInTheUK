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
    private let queue = DispatchQueue(label: "\(WeatherImageStore.self) Queue", qos: .utility, attributes: .concurrent)
    
    init(fileManager: FileManager = .default, storeURL: URL) {
        self.fileManager = fileManager
        self.storeURL = storeURL
    }
    
    func find(imageWithCode code: String) async -> Data? {
        let fileURL = storeURL.appendingPathComponent(code)
        
        return queue.sync {
            try? Data(contentsOf: fileURL)
        }
    }
    
    func save(imageData: Data, for code: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let fileURL = storeURL.appendingPathComponent(code)
            
            try? fileManager.createDirectory(at: storeURL, withIntermediateDirectories: true)
            try? imageData.write(to: fileURL)
        }
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
        
        try await expect(sut, toRetrieve: expectedData, withCode: code)
    }
    
    func test_save_overridesPreviouslyStoredData() async throws {
        let sut = makeSUT()
        let code = "code"
        let firstData = anyData()
        let latestData = anyData()
        
        sut.save(imageData: firstData, for: code)
        sut.save(imageData: latestData, for: code)
        
        try await expect(sut, toRetrieve: latestData, withCode: code)
    }
    
    func test_save_storesDataSeparatelyWithDifferentCodes() async throws {
        let sut = makeSUT()
        let code1 = "code 1"
        let code2 = "code 2"
        let data1 = anyData()
        let data2 = anyData()
        
        sut.save(imageData: data1, for: code1)
        sut.save(imageData: data2, for: code2)
        
        try await expect(sut, toRetrieve: data1, withCode: code1)
        try await expect(sut, toRetrieve: data2, withCode: code2)
    }
    
    func test_save_retrievesSameDataByDifferentInstances() async throws {
        let sut1 = makeSUT()
        let sut2 = makeSUT()
        let code = "code"
        let expectedData = anyData()

        sut1.save(imageData: expectedData, for: code)
        
        try await expect(sut1, toRetrieve: expectedData, withCode: code)
        try await expect(sut2, toRetrieve: expectedData, withCode: code)
    }
    
    func test_saveAndFind_withConcurrentAccess_shouldPreventRaceCondition() async throws {
        let sut = makeSUT()
        let code = "code"
        let data = Data(repeating: 0, count: 10_000)
        
        let write = Task {
            sut.save(imageData: data, for: code)
        }
        
        let read = Task {
            try await expect(sut, toRetrieve: data, withCode: code)
        }
        
        _ = try await (write.value, read.value)
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
        Data(UUID().uuidString.utf8)
    }
    
    private var testURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(WeatherImagePersistenceTests.self)")
    }
    
    private func clearStoreArtefacts() {
        try? FileManager.default.removeItem(at: testURL)
    }
}
