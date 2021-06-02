import class Foundation.Thread
import PromiseKit
import Dispatch
import XCTest

private enum Error: Swift.Error { case dummy }

class CancellableDefaultDispatchQueueTest: XCTestCase {

    let myQueue = DispatchQueue(label: "myQueue")

    override func setUp() {
        // can actually only set the default queue once
        // - See: PMKSetDefaultDispatchQueue
        conf.Q = (myQueue, myQueue)
    }

    override func tearDown() {
        conf.Q = (.main, .main)
    }

    func testOverrodeDefaultThenQueue() {
        let ex = expectation(description: "resolving")

        let p = Promise.value(1).cancellize()
        p.cancel()
        p.then { _ -> CancellablePromise<Void> in
            XCTFail()
            XCTAssertFalse(Thread.isMainThread)
            return CancellablePromise()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
            XCTAssertFalse(Thread.isMainThread)
        }

        XCTAssertTrue(Thread.isMainThread)

        waitForExpectations(timeout: 5)
    }

    func testOverrodeDefaultCatchQueue() {
        let ex = expectation(description: "resolving")

        let p = CancellablePromise<Int>(error: Error.dummy)
        p.cancel()
        p.catch { _ in
            ex.fulfill()
            XCTAssertFalse(Thread.isMainThread)
        }

        XCTAssertTrue(Thread.isMainThread)

        waitForExpectations(timeout: 5)
    }

    func testOverrodeDefaultAlwaysQueue() {
        let ex = expectation(description: "resolving")
        let ex2 = expectation(description: "catching")

        let p = Promise.value(1).cancellize()
        p.cancel()
        p.ensure {
            ex.fulfill()
            XCTAssertFalse(Thread.isMainThread)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex2.fulfill() : XCTFail()
            XCTAssertFalse(Thread.isMainThread)
        }

        XCTAssertTrue(Thread.isMainThread)

        waitForExpectations(timeout: 5)
    }
}
