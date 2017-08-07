import PromiseKit
import XCTest

class JointTests: XCTestCase {
    func testPiping() {
        let (promise, joint) = Promise<Int>.joint()

        XCTAssert(promise.isPending)

        let foo = Promise(value: 3)
        foo.join(joint)

        XCTAssertEqual(3, promise.value)
    }

    func testPipingPending() {
        let (promise, joint) = Promise<Int>.joint()

        XCTAssert(promise.isPending)

        let (foo, fulfillFoo, _) = Promise<Int>.pending()
        foo.join(joint)

        fulfillFoo(3)

        XCTAssertEqual(3, promise.value)
    }

    func testCallback() {
        let ex = expectation(description: "")

        let (promise, joint) = Promise<Void>.joint()
        promise.then { ex.fulfill() }

        Promise(value: ()).join(joint)

        waitForExpectations(timeout: 1)
    }

    func testCallbackPending() {
        let ex = expectation(description: "")

        let (promise, joint) = Promise<Void>.joint()
        promise.then { ex.fulfill() }

        let (foo, fulfillFoo, _) = Promise<Void>.pending()
        foo.join(joint)

        fulfillFoo(())

        waitForExpectations(timeout: 1)
    }
}
