import PromiseKit
import XCTest

class PromiseTestCase: XCTestCase {
    override func tearDown() {
        PMKUnhandledErrorHandler = { _ in }
    }

    // can return AnyPromise (that fulfills) in then handler
    func test1() {
        let ex = expectation(withDescription: "")
        Promise(1).then { _ -> AnyPromise in
            return AnyPromise(bound: after(0).then{ 1 })
        }.then { x -> Void in
            XCTAssertEqual(x as? Int, 1)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    // can return AnyPromise (that rejects) in then handler
    func test2() {
        let ex = expectation(withDescription: "")

        Promise(1).then { _ -> AnyPromise in
            let promise = after(0.1).then{ throw NSError(domain: "a", code: 1, userInfo: nil) }
            return AnyPromise(bound: promise)
        }.error { err in
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testErrorOnQueue1() {
        let ex = expectation(withDescription: "")

        Promise(1).then { _ -> AnyPromise in
            let promise = after(0.1).then{ throw NSError(domain: "a", code: 1, userInfo: nil) }
            return AnyPromise(bound: promise)
        }.errorOnQueue { err in
            let currentQueueLabel = String(cString: __dispatch_queue_get_label(nil))
            XCTAssertEqual(currentQueueLabel, PMKDefaultDispatchQueue().label)
            ex.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testErrorOnQueue2() {
        let ex = expectation(withDescription: "")

        let queue = DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosDefault)

        Promise(1).then { _ -> AnyPromise in
            let promise = after(0.1).then{ throw NSError(domain: "a", code: 1, userInfo: nil) }
            return AnyPromise(bound: promise)
        }.errorOnQueue(on: queue) { err in
            let currentQueueLabel = String(cString: __dispatch_queue_get_label(nil))
            XCTAssertEqual(currentQueueLabel, queue.label)
            ex.fulfill()
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testThenDataRace() {
        let e1 = expectation(withDescription: "")

        //will crash if then doesn't protect handlers
        stressDataRace(e1, stressFunction: { promise in
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
            XCTAssertTrue((err as NSError).cancelled);
            ex1.fulfill()
        }

        after(0).then { _ in
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.then { _ -> Void in
            XCTFail()
        }.error { _ -> Void in
            XCTFail()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testRecoverWithCancellation() {
        let ex1 = expectation(withDescription: "")
        let ex2 = expectation(withDescription: "")

        PMKUnhandledErrorHandler = { err in
            XCTAssertTrue((err as NSError).cancelled);
            ex2.fulfill()
        }

        after(0).then { _ in
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.recover { err -> Void in
            ex1.fulfill()
            XCTAssertTrue((err as NSError).cancelled)
            throw err
        }.then { _ -> Void in
            XCTFail()
        }.error { _ -> Void in
            XCTFail()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testCatchCancellation() {
        let ex = expectation(withDescription: "")

        after(0).then { _ in
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.error(policy: .allErrors) { err -> Void in
            ex.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testThensAreSequentialForLongTime() {
        var values = [Int]()
        let ex = expectation(withDescription: "")
        var promise = dispatch_promise { 0 }
        let N = 1000
        for x in 1..<N {
            promise = promise.then { y -> Promise<Int> in
                values.append(y)
                XCTAssertEqual(x - 1, y)
                return dispatch_promise { x }
            }
        }
        promise.then { x -> Void in
            values.append(x)
            XCTAssertEqual(values, (0..<N).map{ $0 })
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 10, handler: nil)
    }
}
