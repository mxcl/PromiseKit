import PromiseKit
import XCTest

class WrapTests: XCTestCase {
    class KittenFetcher {
        let value: Int?
        let error: Error?

        init(value: Int?, error: Error?) {
            self.value = value
            self.error = error
        }

        func fetchWithCompletionBlock(block: (Int?, Error?) -> Void) {
            if value != nil {
                block(value, nil)
            } else {
                block(nil, error)
            }
        }
    }

    func testSuccess() {
        let kittenFetcher = KittenFetcher(value: 2, error: nil)
        let promise = PromiseKit.wrap { resolve in
            kittenFetcher.fetchWithCompletionBlock(block: resolve)
        }

        XCTAssertTrue(promise.isFulfilled)
        XCTAssertEqual(2, promise.value)
    }

    func testError() {
        enum Error: Swift.Error {
            case test
        }

        let ex = expectation(description: "")

        let kittenFetcher = KittenFetcher(value: nil, error: Error.test)
        let promise = PromiseKit.wrap { resolve in
            kittenFetcher.fetchWithCompletionBlock(block: resolve)
        }.catch { error in
            if case Error.test = error {
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testInvalidCallingConvention() {
        enum Error: Swift.Error {
            case test
        }

        let ex = expectation(description: "")

        let kittenFetcher = KittenFetcher(value: nil, error: nil)
        let promise = PromiseKit.wrap { resolve in
            kittenFetcher.fetchWithCompletionBlock(block: resolve)
        }.catch { error in
            if case PMKError.invalidCallingConvention = error {
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }
}
