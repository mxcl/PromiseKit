#if canImport(CoreFoundation)

import PromiseKit
import XCTest

class HangTests: XCTestCase {
    func test() {
        let ex = expectation(description: "block executed")
        do {
            let p = after(seconds: 0.02).cancellize().then { _ -> Promise<Int> in
                XCTFail()
                return Promise.value(1)
            }
            p.cancel()
            let value = try hang(p)
            XCTFail()
            XCTAssertEqual(value, 1)
        } catch {
            error.isCancelled ? ex.fulfill() : XCTFail("Unexpected error")
        }
        waitForExpectations(timeout: 5)
    }

    enum Error: Swift.Error {
        case test
    }

    func testError() {
        var value = 0
        do {
            let p = after(seconds: 0.02).cancellize().done {
                XCTFail()
                value = 1
                throw Error.test
            }
            p.cancel()
            _ = try hang(p)
            XCTFail()
            XCTAssertEqual(value, 1)
        } catch Error.test {
            XCTFail()
        } catch {
            if !error.isCancelled {
                XCTFail("Unexpected error (expected PMKError.cancelled)")
            }
            return
        }
        XCTFail("Expected error but no error was thrown")
    }
}

#endif
