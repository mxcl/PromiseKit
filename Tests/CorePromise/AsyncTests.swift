import PromiseKit
import Dispatch
import XCTest

private enum Error: Swift.Error { case dummy }

class AsyncTests: XCTestCase {
    
    #if swift(>=5.5)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testAsyncPromiseValue() async throws {
        let promise = after(.milliseconds(100)).then(on: nil){ Promise.value(1) }
        let value = try await promise.async()
        XCTAssertEqual(value, 1)
    }
    #else
    func testAsyncPromiseValue() {

    }
    #endif
    
    #if swift(>=5.5)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testAsyncGuaranteeValue() async {
        let guarantee = after(.milliseconds(100)).then(on: nil){ Guarantee.value(1) }
        let value = await guarantee.async()
        XCTAssertEqual(value, 1)
    }
    #else
    func testAsyncGuaranteeValue() {

    }
    #endif
    
    #if swift(>=5.5)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testAsyncPromiseThrow() async throws {
        do {
            let promise = after(.milliseconds(100)).then(on: nil){ Promise(error: Error.dummy) }.then(on: nil){ Promise.value(1) }
            try await _ = promise.async()
            XCTAssert(false)
        } catch {
            switch error as? Error {
            case .dummy:
                XCTAssert(true)
            default:
                XCTAssert(false)
            }
        }
    }
    #else
    func testAsyncPromiseThrow() {

    }
    #endif
}

