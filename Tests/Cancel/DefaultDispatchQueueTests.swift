import class Foundation.Thread
@testable import PromiseKit
import Dispatch
import XCTest

private enum Error: Swift.Error { case dummy }

class CancellableDefaultDispatchQueueTest: XCTestCase {

    let myQueue = DispatchQueue(label: "myQueue")

    override func setUp() {
        conf.testMode = true  // Allow free setting of default dispatchers
        conf.setDefaultDispatchers(body: myQueue, tail: myQueue)
    }

    override func tearDown() {
        conf.setDefaultDispatchers(body: .main, tail: .main)
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

        waitForExpectations(timeout: 1)
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

        waitForExpectations(timeout: 1)
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

        waitForExpectations(timeout: 1)
    }
}
