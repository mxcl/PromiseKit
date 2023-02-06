#if swift(>=4.1)
#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Guarantee {
    func future() -> Future<T, Never> {
        .init { promise in
            self.done { value in
                promise(.success(value))
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Promise {
    func future() -> Future<T, Error> {
        .init { promise in
            self.done { value in
                promise(.success(value))
            }.catch { error in
                promise(.failure(error))
            }
        }
    }
}
#endif
#endif
