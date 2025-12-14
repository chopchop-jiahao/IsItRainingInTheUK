//
//  ImageDataValidator.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 14/12/2025.
//

import Foundation

public protocol ImageDataValidator {
    func isValid(_ data: Data) -> Bool
}
