@testable import PromiseKit
import XCTest

class ZalgoTests: XCTestCase {
    func testZalgoOnSealedPromise() {
        var resolved = false
        Promise(1).then(on: nil) { _ in
            resolved = true
        }
        XCTAssertTrue(resolved)

        let p1 = Promise(1).then(on: nil) { x in
            return 2
        }
        XCTAssertEqual(p1.value!, 2)
    }

    func testZalgoOnUnsealedPromise() {
        var x = 0
        let (promise, pipe) = Promise<Int>.pending()
        promise.then(on: nil) { _ in
            x = 1
        }
        XCTAssertEqual(x, 0)

        // this executes after the current execution context
        pipe.fulfill(1)

        // hence we are still 0
        XCTAssertEqual(x, 0)

        let ex = expectation(description: "")

        Thread.current.afterExecutionContext {
            XCTAssertEqual(x, 1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // returning a pending promise from its own zalgo’d then handler doesn’t hang
    func test3() {
        let ex = (expectation(description: ""), expectation(description: ""))

        var p1: Promise<Void>!
        p1 = after(interval: 0.1).then(on: nil) { _ -> Promise<Void> in
            ex.0.fulfill()
            return p1
        }

        p1.catch { error in
            guard case PMKError.returnedSelf = error else { return XCTFail() }
            ex.1.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    // return a sealed promise from its own zalgo’d then handler doesn’t hang
    func test4() {
        let ex = expectation(description: "")
        let p1 = Promise(1)
        p1.then(on: nil) { _ -> Promise<Int> in
            ex.fulfill()
            return p1
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
