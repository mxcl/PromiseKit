import PromiseKit
import XCTest

class Test224: XCTestCase {
    func test() {
        describe("2.2.4: `onFulfilled` or `onRejected` must not be called until the execution context stack contains only platform code.") {

            describe("`then` returns before the promise becomes fulfilled or rejected") {
                testFulfilled { promise, expectation, dummy in
                    var thenHasReturned = false
                    promise.done { _ in
                        XCTAssert(thenHasReturned)
                        expectation.fulfill()
                    }.silenceWarning()
                    thenHasReturned = true
                }
                testRejected { promise, expectation, memo in
                    var catchHasReturned = false
                    promise.catch { _->() in
                        XCTAssert(catchHasReturned)
                        expectation.fulfill()
                    }
                    catchHasReturned = true
                }

            }

            describe("Clean-stack execution ordering tests (fulfillment case)") {
                specify("when `onFulfilled` is added immediately before the promise is fulfilled") { d, expectation in
                    var onFulfilledCalled = false
                    d.promise.done {
                        onFulfilledCalled = true
                        expectation.fulfill()
                    }.silenceWarning()
                    d.fulfill()
                    XCTAssertFalse(onFulfilledCalled)
                }
                specify("when `onFulfilled` is added immediately after the promise is fulfilled") { d, expectation in
                    var onFulfilledCalled = false
                    d.fulfill()
                    d.promise.done {
                        onFulfilledCalled = true
                        expectation.fulfill()
                    }.silenceWarning()
                    XCTAssertFalse(onFulfilledCalled)
                }
                specify("when one `onFulfilled` is added inside another `onFulfilled`") { _, expectation in
                    var firstOnFulfilledFinished = false
                    let promise = Promise()
                    promise.done {
                        promise.done {
                            XCTAssertTrue(firstOnFulfilledFinished)
                            expectation.fulfill()
                        }.silenceWarning()
                        firstOnFulfilledFinished = true
                    }.silenceWarning()
                }

                specify("when `onFulfilled` is added inside an `onRejected`") { _, expectation in
                    let promise1 = Promise<Void>(error: Error.dummy)
                    let promise2 = Promise()
                    var firstOnRejectedFinished = false

                    promise1.catch { _ in
                        promise2.done {
                            XCTAssertTrue(firstOnRejectedFinished)
                            expectation.fulfill()
                        }.silenceWarning()
                        firstOnRejectedFinished = true
                    }
                }
                
                specify("when the promise is fulfilled asynchronously") { d, expectation in
                    var firstStackFinished = false

                    after(ticks: 1) {
                        d.fulfill()
                        firstStackFinished = true
                    }

                    d.promise.done {
                        XCTAssertTrue(firstStackFinished)
                        expectation.fulfill()
                    }.silenceWarning()
                }
            }

            describe("Clean-stack execution ordering tests (rejection case)") {
                specify("when `onRejected` is added immediately before the promise is rejected") { d, expectation in
                    var onRejectedCalled = false
                    d.promise.catch { _ in
                        onRejectedCalled = true
                        expectation.fulfill()
                    }
                    d.reject(Error.dummy)
                    XCTAssertFalse(onRejectedCalled)
                }
                specify("when `onRejected` is added immediately after the promise is rejected") { d, expectation in
                    var onRejectedCalled = false
                    d.reject(Error.dummy)
                    d.promise.catch { _ in
                        onRejectedCalled = true
                        expectation.fulfill()
                    }
                    XCTAssertFalse(onRejectedCalled)
                }
                specify("when `onRejected` is added inside an `onFulfilled`") { d, expectation in
                    let promise1 = Promise()
                    let promise2 = Promise<Void>(error: Error.dummy)
                    var firstOnFulfilledFinished = false

                    promise1.done { _ in
                        promise2.catch { _ in
                            XCTAssertTrue(firstOnFulfilledFinished)
                            expectation.fulfill()
                        }
                        firstOnFulfilledFinished = true
                    }.silenceWarning()
                }
                specify("when one `onRejected` is added inside another `onRejected`") { d, expectation in
                    let promise = Promise<Void>(error: Error.dummy)
                    var firstOnRejectedFinished = false;

                    promise.catch { _ in
                        promise.catch { _ in
                            XCTAssertTrue(firstOnRejectedFinished)
                            expectation.fulfill()
                        }
                        firstOnRejectedFinished = true
                    }
                }
                specify("when the promise is rejected asynchronously") { d, expectation in
                    var firstStackFinished = false
                    after(ticks: 1) {
                        d.reject(Error.dummy)
                        firstStackFinished = true
                    }
                    d.promise.catch { _ in
                        XCTAssertTrue(firstStackFinished)
                        expectation.fulfill()
                    }
                }
            }
        }
    }
}
