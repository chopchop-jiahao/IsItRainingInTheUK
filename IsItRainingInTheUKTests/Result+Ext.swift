//
//  Result+Ext.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 13/12/2025.
//

import Foundation

extension Result {
    init(asyncCatching body: () async throws -> Success) async where Failure == Error {
        do {
            let result = try await body()
            self = .success(result)
        } catch {
            self = .failure(error)
        }
    }
}
