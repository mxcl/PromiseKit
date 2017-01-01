import PromiseKit
import XCTest

class JointTests: XCTestCase {
    func testPiping() {
        let (promise, pipe) = Promise<Int>.pending()

        XCTAssert(promise.isPending)

        let foo = Promise(3)
        foo.pipe(to: pipe)

        let ex = expectation(description: "")

        DispatchQueue.main.async {
            XCTAssertEqual(3, promise.value)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testPipingPending() {
        let (promise1, pipe1) = Promise<Int>.pending()

        XCTAssert(promise1.isPending)

        let (promise2, pipe2) = Promise<Int>.pending()
        promise2.pipe(to: pipe1)

        pipe2.fulfill(3)

        let ex = expectation(description: "")
        promise1.ensure(that: ex.fulfill)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(3, promise1.value)
    }

    func testCallback() {
        let ex = expectation(description: "")

        let (promise, pipe) = Promise<Void>.pending()
        promise.then { ex.fulfill() }

        Promise().pipe(to: pipe)

        waitForExpectations(timeout: 1)
    }

    func testCallbackPending() {
        let ex = expectation(description: "")

        let (promise, joint) = Promise<Void>.pending()
        promise.then { ex.fulfill() }

        let (foo, pipe) = Promise<Void>.pending()
        foo.pipe(to: joint)

        pipe.fulfill()

        waitForExpectations(timeout: 1)
    }
}
