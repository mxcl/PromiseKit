import PromiseKit
import Dispatch
import XCTest

class PromiseTests: XCTestCase {
    func testIsPending() {
        XCTAssertTrue(Promise<Void>.pending().promise.isPending)
        XCTAssertFalse(Promise().isPending)
        XCTAssertFalse(Promise<Void>(error: Error.dummy).isPending)
    }

    func testIsResolved() {
        XCTAssertFalse(Promise<Void>.pending().promise.isResolved)
        XCTAssertTrue(Promise().isResolved)
        XCTAssertTrue(Promise<Void>(error: Error.dummy).isResolved)
    }

    func testIsFulfilled() {
        XCTAssertFalse(Promise<Void>.pending().promise.isFulfilled)
        XCTAssertTrue(Promise().isFulfilled)
        XCTAssertFalse(Promise<Void>(error: Error.dummy).isFulfilled)
    }

    func testIsRejected() {
        XCTAssertFalse(Promise<Void>.pending().promise.isRejected)
        XCTAssertTrue(Promise<Void>(error: Error.dummy).isRejected)
        XCTAssertFalse(Promise().isRejected)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatchQueueAsyncExtensionReturnsGuarantee() {
        let ex = expectation(description: "")
        let returnedValue: Any = DispatchQueue.global().async(.promise) { () -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }
        // This is statically determined, but we want to promote it into something that fits into XCTest
        XCTAssert(returnedValue is Guarantee<Int>, "DispatchQueue.async() returns non-Guarantee even when code doesn't throw")
        if let guarantee = returnedValue as? Guarantee<Int> {
            guarantee.done { one in
                XCTAssertEqual(one, 1)
                ex.fulfill()
            }
            waitForExpectations(timeout: 1)
       }
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatcherDispatchExtensionReturnsGuarantee() {
        let ex = expectation(description: "Dispatcher.dispatch -> Guarantee")
        let dispatcher: Dispatcher = DispatchQueue.global()
        let returnedValue: Any = dispatcher.dispatch { () -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }
        // This is statically determined, but we want to promote it into something that fits into XCTest
        XCTAssert(returnedValue is Guarantee<Int>, "Dispatcher.dispatch() returns non-Guarantee even when code doesn't throw")
        if let guarantee = returnedValue as? Guarantee<Int> {
            guarantee.done { one in
                XCTAssertEqual(one, 1)
                ex.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatchQueueAsyncExtensionCanThrowInBody() {
        let ex = expectation(description: "")
        let returnedValue: Any = DispatchQueue.global().async(.promise) { () -> Int in
            throw Error.dummy
        }
        // This is statically determined, but we want to promote it into something that fits into XCTest
        XCTAssert(returnedValue is Promise<Int>, "Dispatcher.dispatch() returns non-Promise even when code can throw")
        XCTAssert(returnedValue is Promise<Int>, "DispatchQueue.async() returns non-Promise even when code can throw")
       if let promise = returnedValue as? Promise<Int> {
            promise.done { _ in
                XCTFail("Promise should not complete normally")
            }.catch { _ in
                ex.fulfill()
            }
            waitForExpectations(timeout: 1)
        } else {
            XCTFail("Could not recover Promise<Int> from Any")
        }
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatcherDispatchExtensionCanThrowInBody() {
        let ex = expectation(description: "Dispatcher.dispatch -> Promise")
        let dispatcher: Dispatcher = DispatchQueue.global()
        let returnedValue: Any = dispatcher.dispatch { () -> Int in
            throw Error.dummy
        }
        // This is statically determined, but we want to promote it into something that fits into XCTest
        XCTAssert(returnedValue is Promise<Int>, "Dispatcher.dispatch() returns non-Promise even when code can throw")
        if let promise = returnedValue as? Promise<Int> {
            promise.done { _ in
                XCTFail("Promise should not complete normally")
                }.catch { _ in
                    ex.fulfill()
            }
            waitForExpectations(timeout: 1)
        } else {
            XCTFail("Could not recover Promise<Int> from Any")
        }
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatcherDispatchExtensionDoesNotInterfereWithRegularDispatch() {
        let dispatcher: Dispatcher = DispatchQueue.global()

        let plain = expectation(description: "plain closure")
        let plainReturn: Any = dispatcher.dispatch {
            plain.fulfill()
        }
        // This is statically determined, but we want to promote it into something that fits into XCTest
        XCTAssert(plainReturn is Void, "Dispatcher.dispatch() returns something other than Void")

        // With a throwing closure, the return should be a Promise, even without a return value.
        // There's no standard Dispatcher API that accepts throwing closures for dispatch.
        let throwing = expectation(description: "throwing closure")
        let throwingReturn: Any = dispatcher.dispatch {
            throwing.fulfill()
            throw Error.dummy
        }
        // This is statically determined, but we want to promote it into something that fits into XCTest
        XCTAssert(throwingReturn is Promise<Void>, "Dispatcher.dispatch() returns something other than Promise<Void> with plain throwing closure")
        waitForExpectations(timeout: 1)
    }

    func testCustomStringConvertible() {
        XCTAssertEqual(Promise<Int>.pending().promise.debugDescription, "Promise<Int>.pending(handlers: 0)")
        XCTAssertEqual(Promise().debugDescription, "Promise<()>.success(())")
        XCTAssertEqual(Promise<String>(error: Error.dummy).debugDescription, "Promise<String>.failure(Error.dummy)")

        XCTAssertEqual("\(Promise<Int>.pending().promise)", "Promise(…Int)")
        XCTAssertEqual("\(Promise.value(3))", "Promise(3)")
        XCTAssertEqual("\(Promise<Void>(error: Error.dummy))", "Promise(dummy)")
    }

    func testCannotFulfillWithError() {

        // sadly this test proves the opposite :(
        // left here so maybe one day we can prevent instantiation of `Promise<Error>`

        _ = Promise { seal in
            seal.fulfill(Error.dummy)
        }

        _ = Promise<Error>.pending()

        _ = Promise.value(Error.dummy)

        _ = Promise().map { Error.dummy }
    }

    func testCanMakeVoidPromise() {
        _ = Promise()
        _ = Guarantee()
    }

    enum Error: Swift.Error {
        case dummy
    }

    func testThrowInInitializer() {
        let p = Promise<Void> { _ in
            throw Error.dummy
        }
        XCTAssertTrue(p.isRejected)
        guard let err = p.error, case Error.dummy = err else { return XCTFail() }
    }

    func testThrowInFirstly() {
        let ex = expectation(description: "")

        firstly { () -> Promise<Int> in
            throw Error.dummy
        }.catch {
            XCTAssertEqual($0 as? Error, Error.dummy)
            ex.fulfill()
        }

        wait(for: [ex], timeout: 10)
    }

    func testWait() throws {
        let p = after(.milliseconds(100)).then(on: nil){ Promise.value(1) }
        XCTAssertEqual(try p.wait(), 1)

        do {
            let p = after(.milliseconds(100)).map(on: nil){ throw Error.dummy }
            try p.wait()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? Error, Error.dummy)
        }
    }

    func testPipeForResolved() {
        let ex = expectation(description: "")
        Promise.value(1).done {
            XCTAssertEqual(1, $0)
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }

    #if swift(>=3.1)
    func testNoAmbiguityForValue() {
        let ex = expectation(description: "")
        let a = Promise<Void>.value
        let b = Promise<Void>.value(Void())
        let c = Promise<Void>.value(())
        when(fulfilled: a, b, c).done {
            ex.fulfill()
        }.cauterize()
        wait(for: [ex], timeout: 10)
    }
    #endif
}
