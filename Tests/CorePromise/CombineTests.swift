#if swift(>=4.1)
#if canImport(Combine)
import Combine
#endif
#endif
import PromiseKit
import XCTest

private enum Error: Swift.Error { case dummy }

class CombineTests: XCTestCase {
    private var cancellable: Any?
    
    override func tearDown() {
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            (cancellable as? AnyCancellable)?.cancel()
        }
        #endif
        #endif
    }
    
    func testCombinePromiseValue() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let promise = after(.milliseconds(100)).then(on: nil){ Promise.value(1) }
            cancellable = promise.future().sink(receiveCompletion: { result in
                switch result {
                case .failure:
                    XCTAssert(false)
                default:
                    XCTAssert(true)
                }
            }, receiveValue: {
                XCTAssertEqual($0, 1)
                ex.fulfill()
            })
        } else {
            ex.fulfill()
        }
        #else
        ex.fulfill()
        #endif
        #else
        ex.fulfill()
        #endif

        wait(for: [ex], timeout: 1)
    }
    
    func testCombineGuaranteeValue() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let promise = after(.milliseconds(100)).then(on: nil){ Guarantee.value(1) }
            cancellable = promise.future().sink(receiveCompletion: { result in
                switch result {
                case .failure:
                    XCTAssert(false)
                default:
                    XCTAssert(true)
                }
            }, receiveValue: {
                XCTAssertEqual($0, 1)
                ex.fulfill()
            })
        } else {
            ex.fulfill()
        }
        #else
        ex.fulfill()
        #endif
        #else
        ex.fulfill()
        #endif

        wait(for: [ex], timeout: 1)
    }
    
    func testCombinePromiseThrow() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let promise = after(.milliseconds(100)).then(on: nil){ Promise(error: Error.dummy) }.then(on: nil){ Promise.value(1) }
            cancellable = promise.future().sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    switch error as? Error {
                    case .dummy:
                        XCTAssert(true)
                    default:
                        XCTAssert(false)
                    }
                default:
                    XCTAssert(false)
                }
                ex.fulfill()
            }, receiveValue: { _ in
                XCTAssert(false)
            })
        } else {
            ex.fulfill()
        }
        #else
        ex.fulfill()
        #endif
        #else
        ex.fulfill()
        #endif

        wait(for: [ex], timeout: 1)
    }
    
    func testPromiseCombineValue() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let promise = Future<Int, Error> { resolver in
                resolver(.success(1))
            }.delay(for: 5, scheduler: RunLoop.main).future().promise()
            promise.done {
                XCTAssertEqual($0, 1)
                ex.fulfill()
            }.catch { _ in
                XCTAssert(false)
                ex.fulfill()
            }
        } else {
            ex.fulfill()
        }
        #else
        ex.fulfill()
        #endif
        #else
        ex.fulfill()
        #endif

        wait(for: [ex], timeout: 10)
    }
    
    func testGuaranteeCombineValue() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let guarantee = Future<Int, Never> { resolver in
                resolver(.success(1))
            }.delay(for: 5, scheduler: RunLoop.main).future().guarantee()
            guarantee.done {
                XCTAssertEqual($0, 1)
                ex.fulfill()
            }
        } else {
            ex.fulfill()
        }
        #else
        ex.fulfill()
        #endif
        #else
        ex.fulfill()
        #endif

        wait(for: [ex], timeout: 10)
    }
    
    func testPromiseCombineThrows() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let promise = Future<Int, Error> { resolver in
                resolver(.failure(.dummy))
            }.delay(for: 5, scheduler: RunLoop.main).map { _ in
                100
            }.future().promise()
            promise.done { _ in
                XCTAssert(false)
                ex.fulfill()
            }.catch { error in
                switch error as? Error {
                case .dummy:
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
                ex.fulfill()
            }
        } else {
            ex.fulfill()
        }
        #else
        ex.fulfill()
        #endif
        #else
        ex.fulfill()
        #endif

        wait(for: [ex], timeout: 10)
    }
}

/// https://stackoverflow.com/a/60444607/2229783
private extension Publisher {
    func future() -> Future<Output, Failure> {
        return Future { promise in
            var ticket: AnyCancellable? = nil
            ticket = sink(
                receiveCompletion: {
                    ticket?.cancel()
                    ticket = nil
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .finished:
                        break
                    }
                },
                receiveValue: {
                    ticket?.cancel()
                    ticket = nil
                    promise(.success($0))
                }
            )
        }
    }
}
