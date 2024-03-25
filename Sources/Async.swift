#if swift(>=5.5)
#if canImport(_Concurrency)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Guarantee {
    func async() async -> T {
        await withCheckedContinuation { continuation in
            done { value in
                continuation.resume(returning: value)
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Promise {
    func async() async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            done { value in
                continuation.resume(returning: value)
            }.catch { error in
                continuation.resume(throwing: error)
            }
        }
    }
}
#endif
#endif

