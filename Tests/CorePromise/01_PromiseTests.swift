import PromiseKit
import XCTest

class PromiseTests: XCTestCase {
    override func setUp() {
        InjectedErrorUnhandler = { _ in }
    }

    func testPending() {
        XCTAssertTrue(Promise<Void>.pending().promise.isPending)
        XCTAssertFalse(Promise.fulfilled().isPending)
        XCTAssertFalse(Promise<Void>.resolved(error: Error.dummy).isPending)
    }

    func testResolved() {
        XCTAssertFalse(Promise<Void>.pending().promise.isResolved)
        XCTAssertTrue(Promise.fulfilled().isResolved)
        XCTAssertTrue(Promise<Void>.resolved(error: Error.dummy).isResolved)
    }

    func testFulfilled() {
        XCTAssertFalse(Promise<Void>.pending().promise.isFulfilled)
        XCTAssertTrue(Promise.fulfilled().isFulfilled)
        XCTAssertFalse(Promise<Void>.resolved(error: Error.dummy).isFulfilled)
    }

    func testRejected() {
        XCTAssertFalse(Promise<Void>.pending().promise.isRejected)
        XCTAssertTrue(Promise<Void>.resolved(error: Error.dummy).isRejected)
        XCTAssertFalse(Promise.fulfilled().isRejected)
    }

    func testDispatchQueueAsyncExtensionReturnsPromise() {
        let ex = expectation(description: "")

        DispatchQueue.global().promise {
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }.then { (one: Int) -> Void in
            XCTAssertEqual(one, 1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testDispatchQueueAsyncExtensionCanThrowInBody() {
        let ex = expectation(description: "")

        DispatchQueue.global().promise { _ -> Int in
            throw Error.dummy
        }.then { _ -> Void in
            XCTFail()
        }.catch { _ in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCustomStringConvertible() {
        XCTAssert(String(Promise<Void>.pending().promise).contains("Pending"))
        XCTAssert(String(Promise.fulfilled()).contains("Fulfilled"))
        XCTAssert(String(Promise<Void>.resolved(error: Error.dummy)).contains("Rejected"))
    }
}

private enum Error: ErrorProtocol {
    case dummy
}
