import PromiseKit
import XCTest


class Test232: XCTestCase {

    func testPromiseResolution(factory:()->Promise<Int>, test:(Promise<Int>)->()) {
        // via return from a fulfilled promise
        let p1 = Promise(dummy).then{ _->Promise<Int> in
            return factory()
        }
        test(p1)
        waitForExpectationsWithTimeout(1, handler: nil)

        // via return from a rejected promise
        let p2 = Promise<Int>(dammy).recover{ _->Promise<Int> in
            return factory()
        }
        test(p2)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // 2.3.2: If `x` is a promise, adopt its state

    func test2321() {
        // 2.3.2.1: If `x` is pending, `promise` must remain pending until `x` is fulfilled or rejected.

        testPromiseResolution({
            return Promise<Int>.pendingPromise().promise
        }, test: { promise in
            let ex = self.expectationWithDescription("")
            var wasFulfilled = false
            var wasRejected = false

            promise.then { foo in
                wasFulfilled = true
            }
            promise.catch { foo in
                wasRejected = true
            }
            later(100){
                XCTAssertFalse(wasFulfilled)
                XCTAssertFalse(wasRejected)
                ex.fulfill()
            }
        })
    }

    // 2.3.2.2: If/when `x` is fulfilled, fulfill `promise` with the same value.

    func test2322_1() {
        // `x` is already-fulfilled

        testPromiseResolution({
            return Promise(sentinel)
        }, test: { promise in
            let ex = self.expectationWithDescription("")
            let promise = Promise(dummy).then { _-> Promise<Int> in
                return Promise(sentinel)
            }
            promise.then { value->() in
                XCTAssertEqual(value, sentinel)
                ex.fulfill()
            }
        })
    }

    func test2322_2() {
        // `x` is eventually-fulfilled

        testPromiseResolution({
            let (promise, fulfiller, _) = Promise<Int>.pendingPromise()
            later { fulfiller(sentinel) }
            return promise
        }, test: { promise in
            let ex = self.expectationWithDescription("")
            promise.then{ value->Void in
                XCTAssertEqual(value, sentinel)
                ex.fulfill()
            }
        })
    }

    // 2.3.2.3: If/when `x` is rejected, reject `promise` with the same reason

    func test2323_1() {
        // `x` is already-rejected

        testPromiseResolution({
            return Promise(dammy)
        }, test: { promise in
            let ex = self.expectationWithDescription("")
            promise.catch{ error->Void in
                XCTAssertEqual(error, dammy)
                ex.fulfill()
            }
        })
    }

    func test2323_2() {
        // `x` is eventually-rejected
        testPromiseResolution({
            let (promise, _, rejecter) = Promise<Int>.pendingPromise()
            later { rejecter(dammy) }
            return promise
        }, test: { promise in
            let ex = self.expectationWithDescription("")
            promise.catch{ error->Void in
                XCTAssertEqual(error, dammy)
                ex.fulfill()
            }
        })
    }
}
