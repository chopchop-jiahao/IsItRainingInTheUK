//
//  WeatherImageStore.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 14/12/2025.
//

import Foundation

public final class WeatherImageStore: WeatherImagePersistence {
    private let fileManager: FileManager
    private let storeURL: URL
    private let queue = DispatchQueue(label: "\(WeatherImageStore.self) Queue", qos: .utility, attributes: .concurrent)

    public init(fileManager: FileManager = .default, storeURL: URL) {
        self.fileManager = fileManager
        self.storeURL = storeURL
    }

    public func find(imageWithCode code: String) async -> Data? {
        let fileURL = storeURL.appendingPathComponent(code)

        return queue.sync {
            try? Data(contentsOf: fileURL)
        }
    }

    public func save(imageData: Data, for code: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let fileURL = storeURL.appendingPathComponent(code)

            try? fileManager.createDirectory(at: storeURL, withIntermediateDirectories: true)
            try? imageData.write(to: fileURL)
        }
    }
}
