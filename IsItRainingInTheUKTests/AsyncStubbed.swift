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

// Serial access for all AsyncStubbed instances.
// Each instance has its own data; shared queue just prevents concurrent access.
private let queue = DispatchQueue(label: "AsyncStubbed", qos: .background, attributes: .concurrent)

extension AsyncStubbed {
    /// Pauses execution until `complete(with:at:)` is called.
    /// Each call to this method adds a continuation to the array.
    func wait() async throws -> Stub {
        try await withCheckedThrowingContinuation { continuation in
            // This runs immediately
            queue.sync(flags: .barrier) {
                // Store the continuation so we can resume it later from the test
                self.continuations.append(continuation)
                // Pauses here, waiting...
                // When continuation.resume(returning: value) is called elsewhere,
                //    execution continues and the value is returned
            }
        }
    }

    /// Completes a paused async call at the given index.
    /// Waits until the continuation at that index exists before completing.
    /// Throws if the continuation isn't available within 1 second.
    /// - Parameters:
    ///   - result: The success value or error to return
    ///   - index: Which paused call to complete (0 for first, 1 for second, etc.)
    func complete(with result: Result<Stub, Error>, at index: Int) async throws {
        let start = Date()

        // Wait until continuation exists at this index
        while queue.sync(execute: { continuations.count }) <= index {
            if Date().timeIntervalSince(start) > 1.0 {
                throw timeoutError(at: index)
            }
            await Task.yield()
        }

        let continuation = queue.sync { continuations[index] }

        switch result {
            case let .success(value):
                continuation.resume(returning: value)
            case let .failure(error):
                continuation.resume(throwing: error)
        }
    }

    private func timeoutError(at index: Int) -> NSError {
        NSError(
            domain: "AsyncStubbed",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: "Timeout waiting for continuation at index \(index). Expected \(index + 1) async call(s), but only \(continuations.count) occurred."
            ]
        )
    }
}
