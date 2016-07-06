import PromiseKit
import XCTest

class Test227: XCTestCase {
    func test() {
        describe("2.2.7: `then` must return a promise: `promise2 = promise1.then(onFulfilled, onRejected)") {
            describe("2.2.7.2: If either `onFulfilled` or `onRejected` throws an exception `e`, `promise2` must be rejected with `e` as the reason.") {

                testFulfilled { promise1, expectation, _ in
                    let sentinel = arc4random()
                    let promise2 = promise1.then { _ in throw Error.sentinel(sentinel) }

                    promise2.catch {
                        if case Error.sentinel(let x) = $0 where x == sentinel {
                            expectation.fulfill()
                        }
                    }
                }

                testRejected { promise1, expectation, _ in
                    let sentinel = arc4random()
                    let promise2 = promise1.recover { _ -> UInt32 in throw Error.sentinel(sentinel) }

                    promise2.catch { error in
                        if case Error.sentinel(let x) = error where x == sentinel {
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
    }
}
