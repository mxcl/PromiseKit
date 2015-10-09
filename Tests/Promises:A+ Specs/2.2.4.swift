import PromiseKit
import XCTest

// 2.2.4: `onFulfilled` or `onRejected` must not be called until
// the execution context stack contains only platform code

class Test224: XCTestCase {

    // describe: `then` returns before the promise becomes fulfilled or rejected"

    func test1() {
        testFulfilled { promise, expectations, dummy in
            var thenHasReturned = false
            promise.then { _ -> Void in
                XCTAssert(thenHasReturned)
                expectations[0].fulfill()
            }
            thenHasReturned = true
        }
        testRejected { promise, expectations, memo in
            var catchHasReturned = false
            promise.error { _->() in
                XCTAssert(catchHasReturned)
                expectations[0].fulfill()
            }
            catchHasReturned = true
        }
    }
}

class Test2242: XCTestCase {

    // describe: Clean-stack execution ordering tests (fulfillment case)

    func test1() {

        // specify: when `onFulfilled` is added immediately before the promise is fulfilled

        let (promise, fulfill, _) = Promise<Void>.pendingPromise()
        var onFulfilledCalled = false

        promise.then {
            onFulfilledCalled = true
        }

        fulfill()

        XCTAssertFalse(onFulfilledCalled)
    }

    func test2() {

        // specify: "when `onFulfilled` is added immediately after the promise is fulfilled"

        let (promise, fulfill, _) = Promise<Void>.pendingPromise()
        var onFulfilledCalled = false

        fulfill()

        promise.then {
            onFulfilledCalled = true
        }

        XCTAssertFalse(onFulfilledCalled)
    }

    func test3() {

        // specify: when one `onFulfilled` is added inside another `onFulfilled`

        let promise = Promise()
        var firstOnFulfilledFinished = false
        let ex = expectationWithDescription("")

        promise.then { _ -> Void in
            promise.then { _ -> Void in
                XCTAssertTrue(firstOnFulfilledFinished)
                ex.fulfill()
            }
            firstOnFulfilledFinished = true
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test4() {

        // specify: when `onFulfilled` is added inside an `onRejected`

        let resolved = Promise()
        let rejected = Promise<Void>(error: Error.Dummy)

        var firstOnRejectedFinished = false
        let ex = expectationWithDescription("")

        rejected.error { _ in
            resolved.then { _ -> Void in
                XCTAssert(firstOnRejectedFinished)
                ex.fulfill()
            }
            firstOnRejectedFinished = true
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test5() {

        // specify: when the promise is fulfilled asynchronously

        let (promise, fulfill, _) = Promise<Void>.pendingPromise()
        var firstStackFinished = false
        let ex = expectationWithDescription("")

        later {
            fulfill()
            firstStackFinished = true
        }

        promise.then { _ -> Void in
            XCTAssert(firstStackFinished)
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}

class Test2243: XCTestCase {

    // describe: Clean-stack execution ordering tests (rejection case)

    func test1() {

        // specify: when `onRejected` is added immediately before the promise is rejected

        let (promise, _, reject) = Promise<Void>.pendingPromise()
        var onRejectedCalled = false

        promise.error { _ in
            onRejectedCalled = true
        }

        reject(Error.Dummy)

        XCTAssertFalse(onRejectedCalled)
    }

    func test2() {

        // specify: when `onRejected` is added immediately after the promise is rejected

        let (promise, _, reject) = Promise<Void>.pendingPromise()
        var onRejectedCalled = false

        reject(Error.Dummy)

        promise.error { _ in
            onRejectedCalled = true
        }

        XCTAssertFalse(onRejectedCalled)
    }

    func test3() {

        // specify: when `onRejected` is added inside an `onFulfilled`

        let resolved = Promise()
        let rejected = Promise<Void>(error: Error.Dummy)
        var firstOnFulfilledFinished = false
        let ex = expectationWithDescription("")

        resolved.then { _ -> Void in
            rejected.error{ _ in
                XCTAssert(firstOnFulfilledFinished)
                ex.fulfill()
            }
            firstOnFulfilledFinished = true
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test4() {

        // specify: when one `onRejected` is added inside another `onRejected`

        let promise = Promise<Void>(error: Error.Dummy)
        var firstOnRejectedFinished = false
        let ex = expectationWithDescription("")

        promise.error { _ in
            promise.error { _ in
                XCTAssertTrue(firstOnRejectedFinished)
                ex.fulfill()
            }
            firstOnRejectedFinished = true
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test5() {

        // specify: when the promise is rejected asynchronously

        let (promise, _, reject) = Promise<Void>.pendingPromise()
        var firstStackFinished = false
        let ex = expectationWithDescription("")

        later {
            reject(Error.Dummy)
            firstStackFinished = true
        }

        promise.error { _ in
            XCTAssert(firstStackFinished)
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
