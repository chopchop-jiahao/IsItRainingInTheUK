//
//  WeatherImagePersistence.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 14/12/2025.
//

import Foundation

public protocol WeatherImagePersistence {
    func find(imageWithCode: String) async -> Data?
    func save(imageData: Data, for code: String)
}
