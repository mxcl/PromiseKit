import PromiseKit
import XCTest

// describe: 2.3.2: If `x` is a promise, adopt its state

class Test2321: XCTestCase {

    // describe: 2.3.2.1: If `x` is pending, `promise` must remain pending until `x` is fulfilled or rejected.

    func test1() {
        testPromiseResolution({
            return Promise.pendingPromise().promise
        }, test: { promise in
            let ex = self.expectationWithDescription("")
            var wasFulfilled = false
            var wasRejected = false

            promise.then { _ in
                wasFulfilled = true
            }
            promise.error { _ in
                wasRejected = true
            }
            later(4) {
                XCTAssertFalse(wasFulfilled)
                XCTAssertFalse(wasRejected)
                ex.fulfill()
            }
        })
    }
}


class Test2322: XCTestCase {
    // 2.3.2.2: If/when `x` is fulfilled, fulfill `promise` with the same value.

    func test1() {
        let sentinel = Int(rand())

        // describe: `x` is already-fulfilled

        testPromiseResolution({
            return Promise(sentinel)
        }, test: { promise in
            let ex = self.expectationWithDescription("")

            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                ex.fulfill()
            }
        })
    }

    func test2() {
        let sentinel = Int(rand())

        // `x` is eventually-fulfilled

        testPromiseResolution({
            after(0.1).then { sentinel }
        }, test: { promise in
            let ex = self.expectationWithDescription("")

            promise.then{ value -> Void in
                XCTAssertEqual(value, sentinel)
                ex.fulfill()
            }
        })
    }
}

class Test2323: XCTestCase {

    // describe: 2.3.2.3: If/when `x` is rejected, reject `promise` with the same reason

    func test1() {

        let sentinel = Error.Dummy

        // specify: `x` is already-rejected

        testPromiseResolution({
            return Promise(error: sentinel)
        }, test: { promise in
            let ex = self.expectationWithDescription("")

            promise.error { error -> Void in
                XCTAssertEqual(error, sentinel)
                ex.fulfill()
            }
        })
    }

    func test2() {

        let sentinel = Error.Dummy

        // specify: `x` is eventually-rejected

        testPromiseResolution({
            after(0.1).then { throw sentinel }
        }, test: { promise in
            let ex = self.expectationWithDescription("")

            promise.error { error -> Void in
                XCTAssertEqual(error, sentinel)
                ex.fulfill()
            }
        })
    }
}


/////////////////////////////////////////////////////////////////////////

extension XCTestCase {
    private func testPromiseResolution(factory: () -> Promise<Int>, test: (Promise<Int>) -> Void) {

        // specify: via return from a fulfilled promise
        test(Promise(Int(rand())).then { _ in factory() })
        waitForExpectationsWithTimeout(1, handler: nil)

        // specify: via return from a rejected promise
        test(Promise<Int>(error: Error.Dummy).recover { _ in factory() })
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
