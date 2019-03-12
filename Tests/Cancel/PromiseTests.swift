import PromiseKit
import Dispatch
import XCTest

class PromiseTests: XCTestCase {
    func testIsPending() {
        XCTAssertTrue(CancellablePromise<Void>.pending().promise.promise.isPending)
        XCTAssertFalse(CancellablePromise().promise.isPending)
        XCTAssertFalse(CancellablePromise<Void>(error: Error.dummy).promise.isPending)
    }

    func testIsResolved() {
        XCTAssertFalse(CancellablePromise<Void>.pending().promise.promise.isResolved)
        XCTAssertTrue(CancellablePromise().promise.isResolved)
        XCTAssertTrue(CancellablePromise<Void>(error: Error.dummy).promise.isResolved)
    }

    func testIsFulfilled() {
        XCTAssertFalse(CancellablePromise<Void>.pending().promise.promise.isFulfilled)
        XCTAssertTrue(CancellablePromise().promise.isFulfilled)
        XCTAssertFalse(CancellablePromise<Void>(error: Error.dummy).promise.isFulfilled)
    }

    func testIsRejected() {
        XCTAssertFalse(CancellablePromise<Void>.pending().promise.promise.isRejected)
        XCTAssertTrue(CancellablePromise<Void>(error: Error.dummy).promise.isRejected)
        XCTAssertFalse(CancellablePromise().promise.isRejected)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatchQueueAsyncExtensionReturnsPromise() {
        let ex = expectation(description: "")

        cancellize(DispatchQueue.global().async(.promise) { () -> Int in
            usleep(100000)
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }).done { one in
            XCTFail()
            XCTAssertEqual(one, 1)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("Error: \($0)")
        }.cancel()

        waitForExpectations(timeout: 1)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatchQueueAsyncExtensionCanThrowInBody() {
        let ex = expectation(description: "")

        cancellize(DispatchQueue.global().async(.promise) { () -> Int in
            throw Error.dummy
        }).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) { _ in
            ex.fulfill()
        }.cancel()

        waitForExpectations(timeout: 1)
    }

    func testCustomStringConvertible() {
        XCTAssertEqual(CancellablePromise<Int>.pending().promise.promise.debugDescription, "Promise<Int>.pending(handlers: 0)")
        XCTAssertEqual(CancellablePromise().promise.debugDescription, "Promise<()>.success(())")
        XCTAssertEqual(CancellablePromise<String>(error: Error.dummy).promise.debugDescription, "Promise<String>.failure(Error.dummy)")

        XCTAssertEqual("\(CancellablePromise<Int>.pending().promise.promise)", "Promise(…Int)")
        XCTAssertEqual("\(cancellize(Promise.value(3)).promise)", "Promise(3)")
        XCTAssertEqual("\(CancellablePromise<Void>(error: Error.dummy).promise)", "Promise(dummy)")
    }

    func testCannotFulfillWithError() {

        // sadly this test proves the opposite :(
        // left here so maybe one day we can prevent instantiation of `CancellablePromise<Error>`

        _ = CancellablePromise { seal in
            seal.fulfill(Error.dummy)
        }

        _ = CancellablePromise<Error>.pending()

        _ = cancellize(Promise.value(Error.dummy))

        _ = CancellablePromise().map { Error.dummy }
    }

#if swift(>=3.1)
    func testCanMakeVoidPromise() {
        _ = CancellablePromise()
        _ = Guarantee()
    }
#endif

    enum Error: Swift.Error {
        case dummy
    }

    func testThrowInInitializer() {
        let p = CancellablePromise<Void> { _ in
            throw Error.dummy
        }
        p.cancel()
        XCTAssertTrue(p.promise.isRejected)
        guard let err = p.promise.error, case Error.dummy = err else { return XCTFail() }
    }

    func testThrowInFirstly() {
        let ex = expectation(description: "")

        firstly { () -> CancellablePromise<Int> in
            throw Error.dummy
        }.catch {
            XCTAssertEqual($0 as? Error, Error.dummy)
            ex.fulfill()
        }.cancel()

        wait(for: [ex], timeout: 1)
    }

    func testWait() throws {
        let p = cancellize(after(.milliseconds(100))).then(on: nil){ cancellize(Promise.value(1)) }
        p.cancel()
        do {
            _ = try p.wait()
            XCTFail()
        } catch {
            XCTAssert(error.isCancelled)
        }

        do {
            let p = cancellize(after(.milliseconds(100))).map(on: nil){ throw Error.dummy }
            p.cancel()
            try p.wait()
            XCTFail()
        } catch {
            XCTAssert(error.isCancelled)
        }
    }

    func testPipeForResolved() {
        let ex = expectation(description: "")
        cancellize(Promise.value(1)).done {
            XCTFail()
            XCTAssertEqual(1, $0)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("\($0)")
        }.cancel()
        wait(for: [ex], timeout: 1)
    }
    
    func testCancellableTask() {
        var resolver: Resolver<Void>!

        let task = DispatchWorkItem {
#if swift(>=4.0)
            resolver.fulfill(())
#else
            resolver.fulfill()
#endif
        }
        
        q.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)

        let p = Promise<Void>(cancellableTask: task) { seal in
            resolver = seal
        }
        
        let ex = expectation(description: "")
        firstly {
            CancellablePromise(p)
        }.done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("\($0)")
        }.cancel()

        wait(for: [ex], timeout: 1)
    }
    
    func testSetCancellableTask() {
        var resolver: Resolver<Void>!

        let task = DispatchWorkItem {
#if swift(>=4.0)
            resolver.fulfill(())
#else
            resolver.fulfill()
#endif
        }
        
        q.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)

        var reject: ((Swift.Error) -> Void)?
        let p = Promise<Void>(cancellableTask: task) { seal in
            resolver = seal
            reject = seal.reject
        }
        p.setCancellableTask(task, reject: reject)

        let ex = expectation(description: "")
        firstly {
            cancellize(p)
        }.done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("\($0)")
        }.cancel()

        wait(for: [ex], timeout: 1)
    }
    
    func testInitCancellableTask() {
        var resolver: Resolver<Void>!

        let task = DispatchWorkItem {
#if swift(>=4.0)
            resolver.fulfill(())
#else
            resolver.fulfill()
#endif
        }
        
        q.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)

        let p = Promise<Void> { seal in
            resolver = seal
        }
        
        let ex = expectation(description: "")
        firstly {
            CancellablePromise(task: task, promise: p, resolver: resolver)
        }.done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("\($0)")
        }.cancel()

        wait(for: [ex], timeout: 1)
    }
    
    func testInitVoidCancellableTask() {
        let task = DispatchWorkItem { }
        q.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)

        let ex = expectation(description: "")
        firstly {
            CancellablePromise(task: task)
        }.done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("\($0)")
        }.cancel()

        wait(for: [ex], timeout: 1)
    }
    
    func testBodyThrowsError() {
        let task = DispatchWorkItem { }
        q.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)

        let p = Promise<Void>(cancellableTask: task) { seal in
            throw PMKError.badInput
        }
        
        let ex = expectation(description: "")
        firstly {
            CancellablePromise(p)
        }.done {
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? XCTFail("\($0)") : ex.fulfill()
        }.cancel()

        wait(for: [ex], timeout: 1)
    }
}

private var q: DispatchQueue {
    if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {
        return DispatchQueue.global(qos: .default)
    } else {
        return DispatchQueue.global(priority: .default)
    }
}
