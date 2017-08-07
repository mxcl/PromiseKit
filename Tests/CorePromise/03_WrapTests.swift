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

        func fetchWithCompletionBlock(block: @escaping(Int?, Error?) -> Void) {
            after(.milliseconds(20)).done {
                block(self.value, self.error)
            }
        }
    }

    func testSuccess() {
        let ex = expectation(description: "")
        let kittenFetcher = KittenFetcher(value: 2, error: nil)
        let promise = Promise(.pending) { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.done {
            XCTAssertEqual($0, 2)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testError() {
        enum Error: Swift.Error {
            case test
        }

        let ex = expectation(description: "")

        let kittenFetcher = KittenFetcher(value: nil, error: Error.test)
        Promise(.pending) { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.catch { error in
            defer { ex.fulfill() }
            guard case Error.test = error else {
                return XCTFail()
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
        Promise(.pending) { seal in
            kittenFetcher.fetchWithCompletionBlock(block: seal.resolve)
        }.catch { error in
            defer { ex.fulfill() }
            guard case PMKError.invalidCallingConvention = error else {
                return XCTFail()
            }
        }

        waitForExpectations(timeout: 1)
    }
}
