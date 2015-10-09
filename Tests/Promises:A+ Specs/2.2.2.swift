import PromiseKit
import XCTest

// describe 2.2.2: If `onFulfilled` is a function,

class Test222: XCTestCase {

    // describe: 2.2.2.1: it must be called after `promise` is fulfilled,
    // with `promise`’s fulfillment value as its first argument

    func test1() {
        testFulfilled { promise, expectations, sentinel in
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                expectations[0].fulfill()
            }
        }
    }
}


class Test2222: XCTestCase {

    // describe: 2.2.2.2: it must not be called before `promise` is fulfilled

    func test1() {

        // specify: fulfilled after a delay

        let expectation = expectationWithDescription("")
        let (promise, fulfill, _) = Promise<Void>.pendingPromise()
        var isFulfilled = false

        promise.then { _ -> Void in
            XCTAssertTrue(isFulfilled)
            expectation.fulfill()
        }
        later {
            fulfill()
            isFulfilled = true
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2() {

        // specify: never fulfilled

        class TestPromise : Promise<Void> {
            deinit {
                XCTAssertFalse(fulfilled)
            }
        }

        let expectation = expectationWithDescription("")
        let (promise, _, _) = TestPromise.pendingPromise()

        promise.then { _ in
            XCTFail()
        }
        later {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}


class Test2223: XCTestCase {

    // describe: 2.2.2.3: it must not be called more than once

    func test1() {

        // specify: already-fulfilled

        let ex = expectationWithDescription("")

        Promise().then(ex.fulfill)

        later(4, expectationWithDescription("").fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2() {

        // specify: trying to fulfill a pending promise more than once, immediately

        let ex = expectationWithDescription("")
        let (promise, fulfill, _) = Promise<Void>.pendingPromise()

        promise.then(ex.fulfill)

        fulfill()
        fulfill()

        later(4, expectationWithDescription("").fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test3() {

        // specify: trying to fulfill a pending promise more than once, delayed

        let ex = expectationWithDescription("")
        let (promise, fulfill, _) = Promise<Void>.pendingPromise()
        promise.then(ex.fulfill)

        later {
            fulfill()
            fulfill()
        }

        later(4, expectationWithDescription("").fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test4() {

        // specify: trying to fulfill a pending promise more than once, immediately then delayed

        let ex = expectationWithDescription("")
        let (promise, fulfill, _) = Promise<Void>.pendingPromise()

        promise.then(ex.fulfill)

        fulfill()
        later { fulfill() }

        later(4, expectationWithDescription("").fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test5() {

        // specify: when multiple `then` calls are made, spaced apart in time

        let (promise, fulfill, _) = Promise<Void>.pendingPromise()

        let desc = "when multiple `then` calls are made, spaced apart in time"
        let e1 = expectationWithDescription(desc)
        let e2 = expectationWithDescription(desc)
        let e3 = expectationWithDescription(desc)

        promise.then(e1.fulfill)

        later(1) {
            promise.then(e2.fulfill)
        }
        later(2) {
            promise.then(e3.fulfill)
        }
        later(3) {
            fulfill()
        }

        later(4, expectationWithDescription("").fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test6() {

        //specify: when `then` is interleaved with fulfillment

        let (promise, fulfill, _) = Promise<Void>.pendingPromise()
        let e1 = expectationWithDescription("")
        let e2 = expectationWithDescription("")

        promise.then(e1.fulfill)
        fulfill()
        promise.then(e2.fulfill)

        later(4, expectationWithDescription("").fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
