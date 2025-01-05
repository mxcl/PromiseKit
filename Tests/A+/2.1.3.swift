import PromiseKit
import XCTest

class Test213: XCTestCase {
    func test() {
        describe("2.1.3.1: When rejected, a promise: must not transition to any other state.") {
            testRejected { promise, expectation, _ in
                promise.test(onFulfilled: { XCTFail() }, onRejected: expectation.fulfill)
            }

            specify("trying to reject then immediately fulfill") { d, expectation in
                d.promise.test(onFulfilled: { XCTFail() }, onRejected: expectation.fulfill)
                d.reject(Error.dummy)
                d.fulfill()
            }

            specify("trying to reject then fulfill, delayed") { d, expectation in
                d.promise.test(onFulfilled: { XCTFail() }, onRejected: expectation.fulfill)
                after(ticks: 1) {
                    d.reject(Error.dummy)
                    d.fulfill()
                }
            }

            specify("trying to reject immediately then fulfill delayed") { d, expectation in
                d.promise.test(onFulfilled: { XCTFail() }, onRejected: expectation.fulfill)
                d.reject(Error.dummy)
                after(ticks: 1) {
                    d.fulfill()
                }
            }
        }
    }
}
