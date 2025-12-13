//
//  AsyncStubbed.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 13/12/2025.
//

import Foundation

/// A protocol for mocking async functions in tests.
/// Allows you to control when async calls complete and with what result.
protocol AsyncStubbed where Self: AnyObject {
    associatedtype Stub
    /// Stores paused async calls waiting to be completed
    var continuations: [CheckedContinuation<Stub, Error>] { get set }
}

extension AsyncStubbed {
    /// Pauses execution until `complete(with:at:)` is called.
    /// Each call to this method adds a continuation to the array.
    func wait() async throws -> Stub {
        try await withCheckedThrowingContinuation { continuation in
            // Store the continuation so we can resume it later from the test
            continuations.append(continuation)
            // Function is now paused - no return here
            // The return value comes from resume(returning:)
        }
    }
    
    /// Completes a paused async call at the given index.
    /// - Parameters:
    ///   - result: The success value or error to return
    ///   - index: Which paused call to complete (0 for first, 1 for second, etc.)
    func complete(with result: Result<Stub, Error>, at index: Int) {
        switch result {
        case let .success(value):
            // Unpauses wait() and makes it return this value
            continuations[index].resume(returning: value)
        case let .failure(error):
            // Unpauses wait() and makes it throw this error
            continuations[index].resume(throwing: error)
        }
    }
}
