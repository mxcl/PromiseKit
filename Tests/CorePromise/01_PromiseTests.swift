import PromiseKit
import XCTest

class PromiseTests: XCTestCase {
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

        DispatchQueue.global().async(.promise) { () -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }.done { one in
            XCTAssertEqual(one, 1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testDispatchQueueAsyncExtensionCanThrowInBody() {
        let ex = expectation(description: "")

        DispatchQueue.global().async(.promise) { () -> Int in
            throw Error.dummy
        }.done { _ in
            XCTFail()
        }.catch { _ in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCustomStringConvertible() {
        XCTAssertEqual(Promise<Int>.pending().promise.debugDescription, "Promise<Int>.pending(handlers: 0)")
        XCTAssertEqual(Promise(value: ()).debugDescription, "Promise<()>.fulfilled(())")
        XCTAssertEqual(Promise<String>(error: Error.dummy).debugDescription, "Promise<String>.rejected(Error.dummy)")

        XCTAssertEqual("\(Promise<Int>.pending().promise)", "Promise(…Int)")
        XCTAssertEqual("\(Promise(value: 3))", "Promise(3)")
        XCTAssertEqual("\(Promise<Void>(error: Error.dummy))", "Promise(dummy)")
    }

    func testCannotFulfillWithError() {
        let foo = Promise(.pending) { seal in
            seal.fulfill(Error.dummy)
        }

        let bar = Promise<Error>.pending()

        let baz = Promise(value: Error.dummy)

        let bad = Promise(value: ()).done { Error.dummy }
    }

#if swift(>=3.1)
    func testCanMakeVoidPromise() {
        let promise = Promise()
        XCTAssert(promise.value is Optional<Void>)

        let guarantee = Guarantee()
        XCTAssert(guarantee.value is Optional<Void>)
    }
#endif

    enum Error: Swift.Error {
        case dummy
    }

    func testThrowInInitializer() {
        let p = Promise<Void>(.pending) { _ in
            throw Error.dummy
        }
        XCTAssertTrue(p.isRejected)
        guard let err = p.error, case Error.dummy = err else { return XCTFail() }
    }
}

