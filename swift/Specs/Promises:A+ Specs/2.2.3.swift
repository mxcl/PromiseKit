import PromiseKit
import XCTest


class Test223: XCTestCase {
    // 2.2.3: If `onRejected` is a function

    func test2231() {
        // 2.2.3.1: it must be called after `promise` is rejected,
        // with `promise`’s rejection reason as its first argument
        suiteRejected(1) { (promise, exes, memo) -> () in
            promise.catch { error->() in
                XCTAssertEqual(error, memo)
                return exes[0].fulfill()
            }
            return
        }
    }

    func test22321() {
        // 2.2.3.2: it must not be called before `promise` is fulfilled

        let expectation = expectationWithDescription("rejected after a delay")
        let (promise, _, rejecter) = Promise<Int>.defer()
        var isRejected = false

        promise.catch { _->() in
            XCTAssertTrue(isRejected)
            expectation.fulfill()
        }
        later {
            rejecter(dammy)
            isRejected = true
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test22322() {
        let expectation = expectationWithDescription("never rejected")
        let (promise, _, rejecter) = Promise<Int>.defer()
        var onRejectedCalled = false

        promise.catch { _->() in
            onRejectedCalled = true
            expectation.fulfill()
        }
        later {
            XCTAssertFalse(onRejectedCalled)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test22331() {
        // 2.2.3.3: it must not be called more than once.
        // already-rejected
        var timesCalled = 0
        Promise(error:dammy).catch { _->() in
            XCTAssertEqual(++timesCalled, 1)
        }
    }

    func test22332() {
        // trying to reject a pending promise more than once, immediately
        let (promise, _, rejecter) = Promise<Int>.defer()
        var timesCalled = 0
        promise.catch { _->() in
            XCTAssertEqual(++timesCalled, 1)
        }
        rejecter(dammy)
        rejecter(dammy)
    }

    func test22333() {
        let (promise, _, rejecter) = Promise<Int>.defer()
        var timesCalled = 0
        let expectation = expectationWithDescription("trying to reject a pending promise more than once, delayed")

        promise.catch { _->() in
            XCTAssertEqual(++timesCalled, 1)
            expectation.fulfill()
        }
        later {
            rejecter(dammy)
            rejecter(dammy)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test22334() {
        let (promise, _, rejecter) = Promise<Int>.defer()
        var timesCalled = 0
        let expectation = expectationWithDescription("trying to fulfill a pending promise more than once, immediately then delayed")

        promise.catch { _->() in
            XCTAssertEqual(++timesCalled, 1)
            expectation.fulfill()
        }
        rejecter(dammy)
        later {
            rejecter(dammy)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test22335() {
        let (promise, _, rejecter) = Promise<Int>.defer()
        var timesCalled = [0, 0, 0]
        let desc = "when multiple `then` calls are made, spaced apart in time"
        let e1 = expectationWithDescription(desc)
        let e2 = expectationWithDescription(desc)
        let e3 = expectationWithDescription(desc)

        promise.catch { _->() in
            XCTAssertEqual(++timesCalled[0], 1)
            e1.fulfill()
        }
        later(50.0) {
            promise.catch { _->() in
                XCTAssertEqual(++timesCalled[1], 1)
                e2.fulfill()
            }
            return
        }
        later(100.0) {
            promise.catch { _->() in
                XCTAssertEqual(++timesCalled[2], 1)
                e3.fulfill()
            }
            return
        }
        later(150) {
            rejecter(dammy)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2234() {
        let (promise, _, rejecter) = Promise<Int>.defer()
        var timesCalled = [0, 0]
        let expectation = expectationWithDescription("when `then` is interleaved with fulfillment")

        promise.catch { _->() in
            XCTAssertEqual(++timesCalled[0], 1)
        }

        rejecter(dammy)

        promise.catch { _->() in
            XCTAssertEqual(++timesCalled[1], 1)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
