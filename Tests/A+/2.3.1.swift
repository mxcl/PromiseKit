import PromiseKit
import XCTest

class Test231: XCTestCase {
    func test() {
        describe("2.3.1: If `promise` and `x` refer to the same object, reject `promise` with a `TypeError' as the reason.") {
            specify("via return from a fulfilled promise") { d, expectation in
                var promise: Promise<Void>!
                promise = Promise.fulfilled().then { () -> Promise<Void> in
                    return promise
                }
                promise.catch { err in
                    if case PromiseKit.Error.returnedSelf = err {
                        expectation.fulfill()
                    }
                }
            }
            specify("via return from a rejected promise") { d, expectation in
                var promise: Promise<Void>!
                promise = Promise<Void>.resolved(error: Error.dummy).recover { _ -> Promise<Void> in
                    return promise
                }
                promise.catch { err in
                    if case PromiseKit.Error.returnedSelf = err {
                        expectation.fulfill()
                    }
                }
            }
        }
    }
}
