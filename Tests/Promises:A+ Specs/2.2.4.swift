import PromiseKit
import XCTest


class Test224: XCTestCase {

    // 2.2.4: `onFulfilled` or `onRejected` must not be called until
    // the execution context stack contains only platform code

    func test2241() {
        // `then` returns before the promise becomes fulfilled or rejected

        suiteFulfilled(1) { (promise, exes, dummy)->() in
            var thenHasReturned = false
            promise.then { _->() in
                XCTAssert(thenHasReturned)
                exes[0].fulfill()
            }
            thenHasReturned = true
        }
        suiteRejected(1) { (promise, exes, memo)->() in
            var catchHasReturned = false
            promise.snatch { _->() in
                XCTAssert(catchHasReturned)
                exes[0].fulfill()
            }
            catchHasReturned = true
        }
    }

    // Clean-stack execution ordering tests (fulfillment case)

    func test2242_1() {
        // when `onFulfilled` is added immediately before the promise is fulfilled
        let (promise, fulfiller, _) = Promise<Int>.pendingPromise()
        var onFulfilledCalled = false

        fulfiller(dummy)
        promise.then{ _->() in
            onFulfilledCalled = true
        }

        XCTAssertFalse(onFulfilledCalled)
    }

    func test2242_2() {
        // when one `onFulfilled` is added inside another `onFulfilled`
        let promise = Promise(dummy)
        var firstOnFulfilledFinished = false
        let ex = expectationWithDescription("")

        promise.then { _->() in
            promise.then { _->() in
                XCTAssert(firstOnFulfilledFinished)
                ex.fulfill()
            }
            firstOnFulfilledFinished = true
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2242_3() {
        // when `onFulfilled` is added inside an `onRejected`
        let resolved = Promise(dummy)
        let rejected = Promise<Int>(dammy)

        var firstOnRejectedFinished = false
        let ex = expectationWithDescription("")

        rejected.snatch { _->() in
            resolved.then { _->() in
                XCTAssert(firstOnRejectedFinished)
                ex.fulfill()
            }
            firstOnRejectedFinished = true
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2242_4() {
        // when the promise is fulfilled asynchronously
        let (promise, fulfiller, _) = Promise<Int>.pendingPromise()
        var firstStackFinished = false
        let ex = expectationWithDescription("")
        later {
            fulfiller(dummy)
            firstStackFinished = true
        }
        promise.then { _->() in
            XCTAssert(firstStackFinished)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // Clean-stack execution ordering tests (rejection case)

    func test2243() {
        // when `onRejected` is added immediately before the promise is rejected
        let (promise, _, rejecter) = Promise<Int>.pendingPromise()
        var onRejectedCalled = false
        promise.snatch{ _->() in
            onRejectedCalled = true
        }
        rejecter(dammy)
        XCTAssertFalse(onRejectedCalled)
    }

    func test2244() {
        // when `onRejected` is added immediately after the promise is rejected
        let (promise, _, rejecter) = Promise<Int>.pendingPromise()
        var onRejectedCalled = false
        rejecter(dammy)
        promise.snatch{ _->() in
            onRejectedCalled = true
        }
        XCTAssertFalse(onRejectedCalled)
    }

    func test2245() {
        // when `onRejected` is added inside an `onFulfilled`
        let resolved = Promise(dummy)
        let rejected = Promise<Int>(dammy)
        var firstOnFulfilledFinished = false
        let ex = expectationWithDescription("")

        resolved.then{ _->() in
            rejected.snatch{ _->() in
                XCTAssert(firstOnFulfilledFinished)
                ex.fulfill()
            }
            firstOnFulfilledFinished = true
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2246() {
        // when one `onRejected` is added inside another `onRejected`
        let promise = Promise<Int>(dammy)
        var firstOnRejectedFinished = false
        let ex = expectationWithDescription("")

        promise.snatch{ _->() in
            promise.snatch{ _->() in
                XCTAssertTrue(firstOnRejectedFinished)
                ex.fulfill()
            }
            firstOnRejectedFinished = true
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2247() {
        // when the promise is rejected asynchronously
        let (promise, _, rejecter) = Promise<Int>.pendingPromise()
        var firstStackFinished = false
        let ex = expectationWithDescription("")

        later {
            rejecter(dammy)
            firstStackFinished = true
        }

        promise.snatch{ _->() in
            XCTAssert(firstStackFinished)
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
