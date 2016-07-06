import PromiseKit
import XCTest

private enum Error: ErrorProtocol, CancellableError {
    case Dummy
    case Cancel

    var isCancelled: Bool {
        switch self {
            case .Dummy: return false
            case .Cancel: return true
        }
    }
}

class PromiseTestCase: XCTestCase {
    override func tearDown() {
        PMKUnhandledErrorHandler = { _ in }
    }

    // can return AnyPromise (that fulfills) in then handler
    func test1() {
        let ex = expectation(withDescription: "")
        Promise.resolved(value: 1).then { _ -> AnyPromise in
            return AnyPromise(bound: after(interval: 0).then{ 1 })
        }.then { x -> Void in
            XCTAssertEqual(x as? Int, 1)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    // can return AnyPromise (that rejects) in then handler
    func test2() {
        let ex = expectation(withDescription: "")

        Promise.resolved(value: 1).then { _ -> AnyPromise in
            let promise = after(interval: 0.1).then{ throw Error.Dummy }
            return AnyPromise(bound: promise)
        }.catch { err in
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testCatchOnQueue() {
        let ex = expectation(withDescription: "")

        let queue = DispatchQueue.global()

        Promise.resolved(value: 1).then { _ -> AnyPromise in
            let promise = after(interval: 0.1).then{ throw Error.Dummy }
            return AnyPromise(bound: promise)
        }.catch(on: queue) { err in
            let currentQueueLabel = String(cString: __dispatch_queue_get_label(nil))
            XCTAssertEqual(currentQueueLabel, queue.label)
            ex.fulfill()
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testThenDataRace() {
        let e1 = expectation(withDescription: "")

        //will crash if then doesn't protect handlers
        stressDataRace(expectation: e1, stressFunction: { promise in
            promise.then { s -> Void in
                XCTAssertEqual("ok", s)
                return
            }
        }, fulfill: { "ok" })

        waitForExpectations(withTimeout: 10, handler: nil)
    }

    func testCancellation() {
        let ex1 = expectation(withDescription: "")

        PMKUnhandledErrorHandler = { err in
            XCTAssertTrue((err as? CancellableError)?.isCancelled ?? false);
            ex1.fulfill()
        }

        after(interval: 0).then { _ in
            throw Error.Cancel
        }.then {
            XCTFail()
        }.catch { _ in
            XCTFail()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testRecoverWithCancellation() {
        let ex1 = expectation(withDescription: "")
        let ex2 = expectation(withDescription: "")

        PMKUnhandledErrorHandler = { err in
            XCTAssertTrue((err as NSError).isCancelled);
            ex2.fulfill()
        }

        after(interval: 0).then { _ in
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.recover { err -> Void in
            ex1.fulfill()
            XCTAssertTrue((err as NSError).isCancelled)
            throw err
        }.then {
            XCTFail()
        }.catch { _ in
            XCTFail()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testCatchCancellation() {
        let ex = expectation(withDescription: "")

        after(interval: 0).then { _ in
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.catch(policy: .allErrors) { err in
            ex.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testThensAreSequentialForLongTime() {
        var values = [Int]()
        let ex = expectation(withDescription: "")
        var promise = DispatchQueue.global().async{ 0 }
        let N = 1000
        for x in 1..<N {
            promise = promise.then { y -> Promise<Int> in
                values.append(y)
                XCTAssertEqual(x - 1, y)
                return DispatchQueue.global().async { x }
            }
        }
        promise.then { x -> Void in
            values.append(x)
            XCTAssertEqual(values, (0..<N).map{ $0 })
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }

    func testReturningPreviousPromiseWorks() {

        // regression test because we were doing this wrong
        // in our A+ tests implementation for spec: 2.3.1

        do {
            let promise1 = Promise.fulfilled()
            let promise2 = promise1.then(on: zalgo) { promise1 }
            promise2.catch(on: zalgo) { _ in XCTFail() }
        }
        do {
            enum Error: ErrorProtocol { case dummy }

            let promise1 = Promise<Void>.resolved(error: Error.dummy)
            let promise2 = promise1.recover(on: zalgo) { _ in promise1 }
            promise2.catch(on: zalgo) { err in
                if case PromiseKit.Error.returnedSelf = err {
                    XCTFail()
                }
            }
        }
    }
}
