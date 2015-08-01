import PromiseKit
import XCTest


class Test222: XCTestCase {
    // 2.2.2: If `onFulfilled` is a function,

    func test2221() {
        // 2.2.2.1: it must be called after `promise` is fulfilled,
        // with `promise`’s fulfillment value as its first argument.

        suiteFulfilled(1) { (promise, exes, sentinel) -> () in
            promise.then { value->() in
                XCTAssertEqual(value, sentinel)
                exes[0].fulfill()
                return
            }
            return
        }
    }

    func test2222() {
        // 2.2.2.2: it must not be called before `promise` is fulfilled

        let e1 = expectationWithDescription("fulfilled after a delay")
        let (p1, f1, _) = Promise<Int>.defer_()
        var isFulfilled = false

        p1.then { _->() in
            XCTAssertTrue(isFulfilled)
            e1.fulfill()
        }
        later {
            f1(dummy)
            isFulfilled = true
        }
        waitForExpectationsWithTimeout(1, handler: nil)


        let e2 = expectationWithDescription("never fulfilled")
        let (p2, _, _) = Promise<Int>.defer_()
        var onFulfilledCalled = false

        p2.then { _->() in
            onFulfilledCalled = true
            e2.fulfill()
        }
        later {
            XCTAssertFalse(onFulfilledCalled)
            e2.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test22231() {
        // 2.2.2.3: it must not be called more than once.
        // already-fulfilled
        var timesCalled = 0
        Promise(dummy).then { _->() in
            XCTAssertEqual(++timesCalled, 1)
        }
    }

    func test22232() {
        // trying to fulfill a pending promise more than once, immediately
        let (promise, fulfiller, _) = Promise<Int>.defer_()
        var timesCalled = 0
        promise.then { _->() in
            XCTAssertEqual(++timesCalled, 1)
        }
        fulfiller(dummy)
        fulfiller(dummy)
    }

    func test22233() {
        let (promise, fulfiller, _) = Promise<Int>.defer_()
        var timesCalled = 0
        let e1 = expectationWithDescription("trying to fulfill a pending promise more than once, delayed")

        promise.then { _->() in
            XCTAssertEqual(++timesCalled, 1)
            e1.fulfill()
        }
        later {
            fulfiller(dummy)
            fulfiller(dummy)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test22234() {
        let (promise, fulfiller, _) = Promise<Int>.defer_()
        var timesCalled = 0
        let e1 = expectationWithDescription("trying to fulfill a pending promise more than once, immediately then delayed")

        promise.then { _->() in
            XCTAssertEqual(++timesCalled, 1)
            e1.fulfill()
        }
        fulfiller(dummy)
        later {
            fulfiller(dummy)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test22235() {
        let (promise, fulfiller, _) = Promise<Int>.defer_()
        var timesCalled = [0, 0, 0]
        let desc = "when multiple `then` calls are made, spaced apart in time"
        let e1 = expectationWithDescription(desc)
        let e2 = expectationWithDescription(desc)
        let e3 = expectationWithDescription(desc)

        promise.then { _->() in
            XCTAssertEqual(++timesCalled[0], 1)
            e1.fulfill()
        }
        later(50.0) {
            promise.then { _->() in
                XCTAssertEqual(++timesCalled[1], 1)
                e2.fulfill()
            }
            return
        }
        later(100.0) {
            promise.then { _->() in
                XCTAssertEqual(++timesCalled[2], 1)
                e3.fulfill()
            }
            return
        }
        later(150) {
            fulfiller(dummy)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2224() {
        let (promise, fulfiller, _) = Promise<Int>.defer_()
        var timesCalled = [0, 0]
        let e1 = expectationWithDescription("when `then` is interleaved with fulfillment")

        promise.then { _->() in
            XCTAssertEqual(++timesCalled[0], 1)
        }

        fulfiller(dummy)

        promise.then { _->() in
            XCTAssertEqual(++timesCalled[1], 1)
            e1.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
