import PromiseKit
import XCTest

class PromiseTests: XCTestCase {
    func testPending() {
        XCTAssertTrue(Promise<Void>.pending().promise.isPending)
        XCTAssertFalse(Promise().isPending)
        XCTAssertFalse(Promise<Void>(error: Error.dummy).isPending)
    }

    func testResolved() {
        XCTAssertFalse(Promise<Void>.pending().promise.isResolved)
        XCTAssertTrue(Promise().isResolved)
        XCTAssertTrue(Promise<Void>(error: Error.dummy).isResolved)
    }

    func testFulfilled() {
        XCTAssertFalse(Promise<Void>.pending().promise.isFulfilled)
        XCTAssertTrue(Promise().isFulfilled)
        XCTAssertFalse(Promise<Void>(error: Error.dummy).isFulfilled)
    }

    func testRejected() {
        XCTAssertFalse(Promise<Void>.pending().promise.isRejected)
        XCTAssertTrue(Promise<Void>(error: Error.dummy).isRejected)
        XCTAssertFalse(Promise().isRejected)
    }

    func testDispatchQueueAsyncExtensionReturnsPromise() {
        let ex = expectation(description: "")

        DispatchQueue.global().promise { _ -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }.then { one in
            XCTAssertEqual(one, 1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testDispatchQueueAsyncExtensionCanThrowInBody() {
        let ex = expectation(description: "")

        DispatchQueue.global().promise { _ -> Int in
            throw Error.dummy
        }.then { _ in
            XCTFail()
        }.catch { _ in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCustomStringConvertible() {
        let e1 = expectation(description: "")
        let e2 = expectation(description: "")

        let a = Promise<Void>.pending().promise   // isPending
        let b = Promise()                         // SealedState
        let c = Promise<Int>(error: Error.dummy)  // SealedState
        let d = Promise{ pipe in pipe.fulfill("myValue") }.ensure(that: e1.fulfill)         // UnsealedState
        let e = Promise<Void>{ pipe in pipe.reject(Error.dummy) }.ensure(that: e2.fulfill)  // UnsealedState

        XCTAssertEqual("\(a)", "Promise<Void>(.pending(handlers: 0))")
        XCTAssertEqual("\(b)", "Promise()")
        XCTAssertEqual("\(c)", "Promise<Int>(Error.dummy)")

        waitForExpectations(timeout: 1)

        XCTAssertEqual("\(d)", "Promise(myValue)")
        XCTAssertEqual("\(e)", "Promise<Void>(Error.dummy)")
    }
}

private enum Error: Swift.Error {
    case dummy
}
