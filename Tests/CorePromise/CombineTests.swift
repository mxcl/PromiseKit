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
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            (cancellable as? AnyCancellable)?.cancel()
        }
    }
    
    func testCombinePromiseValue() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let promise = after(.milliseconds(100)).then(on: nil){ Promise.value(1) }
            cancellable = promise.future().sink { result in
                switch result {
                case .failure:
                    XCTAssert(false)
                default:
                    XCTAssert(true)
                }
            } receiveValue: {
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

        wait(for: [ex], timeout: 1)
    }
    
    func testCombineGuaranteeValue() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let promise = after(.milliseconds(100)).then(on: nil){ Guarantee.value(1) }
            cancellable = promise.future().sink { result in
                switch result {
                case .failure:
                    XCTAssert(false)
                default:
                    XCTAssert(true)
                }
            } receiveValue: {
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

        wait(for: [ex], timeout: 1)
    }
    
    func testCombinePromiseThrow() {
        let ex = expectation(description: "")
        #if swift(>=4.1)
        #if canImport(Combine)
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            let promise = after(.milliseconds(100)).then(on: nil){ Promise(error: Error.dummy) }.then(on: nil){ Promise.value(1) }
            cancellable = promise.future().sink { result in
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
            } receiveValue: { _ in
                XCTAssert(false)
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

        wait(for: [ex], timeout: 1)
    }
}
