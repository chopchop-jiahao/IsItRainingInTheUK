//
//  HTTPSession.swift
//  IsItRainingInTheUK
//
//  Created by Jiahao on 08/12/2025.
//

import Foundation

public protocol HTTPSession {
    func data(from url: URL) async throws -> (Data, URLResponse)
}
