import PromiseKit
import XCTest

class Test212: XCTestCase {
    func test() {
        describe("2.1.2.1: When fulfilled, a promise: must not transition to any other state.") {
            testFulfilled { promise, expectation, _ in
                promise.test(onFulfilled: expectation.fulfill, onRejected: { XCTFail() })
            }

            specify("trying to fulfill then immediately reject") { d, expectation in
                d.promise.test(onFulfilled: expectation.fulfill, onRejected: { XCTFail() })
                d.fulfill()
                d.reject(Error.dummy)
            }

            specify("trying to fulfill then reject, delayed") { d, expectation in
                d.promise.test(onFulfilled: expectation.fulfill, onRejected: { XCTFail() })
                after(ticks: 1) {
                    d.fulfill()
                    d.reject(Error.dummy)
                }
            }
        }
    }
}
