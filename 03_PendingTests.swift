import PromiseKit
import XCTest

class JointTests: XCTestCase {
    func testPipingFulfilledPromise() {
        let (promise, pipe) = Promise<Int>.pendingWithPipe()

        XCTAssert(promise.isPending)

        let foo = Promise(value: 3)
        pipe(foo)

        XCTAssertEqual(3, promise.value)
    }

    func testPipingUnfulfilledPromise() {
        let (promise, pipe) = Promise<Int>.pendingWithPipe()

        XCTAssert(promise.isPending)

        let (foo, fulfillFoo, _) = Promise<Int>.pending()
        pipe(foo)

        fulfillFoo(3)

        XCTAssertEqual(3, promise.value)
    }

    func testPipingHandlerWithFulfilledPromise() {
        let ex = expectation(description: "")

        let (promise, pipe) = Promise<Void>.pendingWithPipe()
        promise.then { ex.fulfill() }

        pipe(Promise(value: ()))

        waitForExpectations(timeout: 1)
    }

    func testPipingHandlerWithUnFulfilledPromise() {
        let ex = expectation(description: "")

        let (promise, pipe) = Promise<Void>.pendingWithPipe()
        promise.then { ex.fulfill() }

        let (foo, fulfillFoo, _) = Promise<Void>.pending()
        pipe(foo)

        fulfillFoo()

        waitForExpectations(timeout: 1)
    }
}
