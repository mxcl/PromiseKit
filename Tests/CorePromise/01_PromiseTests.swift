import PromiseKit
import XCTest

class PromiseTests: XCTestCase {
    override func setUp() {
        InjectedErrorUnhandler = { _ in }
    }

    func testPending() {
        XCTAssertTrue(Promise<Void>.pending().promise.isPending)
        XCTAssertFalse(Promise(value: ()).isPending)
        XCTAssertFalse(Promise<Void>(error: Error.dummy).isPending)
    }

    func testResolved() {
        XCTAssertFalse(Promise<Void>.pending().promise.isResolved)
        XCTAssertTrue(Promise(value: ()).isResolved)
        XCTAssertTrue(Promise<Void>(error: Error.dummy).isResolved)
    }

    func testFulfilled() {
        XCTAssertFalse(Promise<Void>.pending().promise.isFulfilled)
        XCTAssertTrue(Promise(value: ()).isFulfilled)
        XCTAssertFalse(Promise<Void>(error: Error.dummy).isFulfilled)
    }

    func testRejected() {
        XCTAssertFalse(Promise<Void>.pending().promise.isRejected)
        XCTAssertTrue(Promise<Void>(error: Error.dummy).isRejected)
        XCTAssertFalse(Promise(value: ()).isRejected)
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

        DispatchQueue.global().promise { () -> Int in
            throw Error.dummy
        }.then { _ -> Void in
            XCTFail()
        }.catch { _ in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCustomStringConvertible() {
        XCTAssert("\(Promise<Void>.pending().promise)".contains("Pending"))
        XCTAssert("\(Promise(value: ()))".contains("Fulfilled"))
        XCTAssert("\(Promise<Void>(error: Error.dummy))".contains("Rejected"))
    }

    func testCannotFulfillWithError() {
        let foo = Promise { fulfill, reject in
            fulfill(Error.dummy)
        }

        let bar = Promise<Error>.pending()

        let baz = Promise(value: Error.dummy)

        let bad = Promise(value: ()).then { Error.dummy }
    }

#if swift(>=3.1)
    func testCanMakeVoidPromise() {
        let promise = Promise()
        XCTAssert(promise.value is Optional<Void>)
    }
#endif
}

private enum Error: Swift.Error {
    case dummy
}
