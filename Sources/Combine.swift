#if swift(>=4.1)
#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Guarantee {
    func future() -> Future<T, Never> {
        .init { [weak self] promise in
            self?.done { value in
                promise(.success(value))
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Promise {
    func future() -> Future<T, Error> {
        .init { [weak self] promise in
            self?.done { value in
                promise(.success(value))
            }.catch { error in
                promise(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Future {
    func promise() -> PromiseKit.Promise<Output> {
        return .init { [weak self] resolver in
            var cancellable: AnyCancellable?
            cancellable = self?.sink(receiveCompletion: { completion in
                cancellable?.cancel()
                cancellable = nil
                switch completion {
                case .failure(let error):
                    resolver.reject(error)
                case .finished:
                    break
                }
            }, receiveValue: { value in
                cancellable?.cancel()
                cancellable = nil
                resolver.fulfill(value)
            })
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Future where Failure == Never {
    func guarantee() -> Guarantee<Output> {
        return .init { [weak self] resolver in
            var cancellable: AnyCancellable?
            cancellable = self?.sink(receiveValue: { value in
                cancellable?.cancel()
                cancellable = nil
                resolver(value)
            })
        }
    }
}
#endif
#endif
