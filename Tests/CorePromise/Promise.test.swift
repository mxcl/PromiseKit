import PromiseKit
import XCTest

class PromiseTestCase: XCTestCase {
    override func tearDown() {
        PMKUnhandledErrorHandler = { _ in }
    }

    // can return AnyPromise (that fulfills) in then handler
    func test1() {
        let ex = expectationWithDescription("")
        Promise(1).then { _ -> AnyPromise in
            return AnyPromise(bound: after(0).then{ 1 })
        }.then { x -> Void in
            XCTAssertEqual(x as? Int, 1)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // can return AnyPromise (that rejects) in then handler
    func test2() {
        let ex = expectationWithDescription("")

        Promise(1).then { _ -> AnyPromise in
            let promise = after(0.1).then{ throw NSError(domain: "a", code: 1, userInfo: nil) }
            return AnyPromise(bound: promise)
        }.error { err in
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testErrorOnQueue1() {
        let ex = expectationWithDescription("")

        Promise(1).then { _ -> AnyPromise in
            let promise = after(0.1).then{ throw NSError(domain: "a", code: 1, userInfo: nil) }
            return AnyPromise(bound: promise)
            }.errorOnQueue { err in
                XCTAssertEqual(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(PMKDefaultDispatchQueue()))

                ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testErrorOnQueue2() {
        let ex = expectationWithDescription("")

        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

        Promise(1).then { _ -> AnyPromise in
            let promise = after(0.1).then{ throw NSError(domain: "a", code: 1, userInfo: nil) }
            return AnyPromise(bound: promise)
            }.errorOnQueue(on: queue) { err in
                XCTAssertEqual(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue))
                
                ex.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testThenDataRace() {
        let e1 = expectationWithDescription("")

        //will crash if then doesn't protect handlers
        stressDataRace(e1, stressFunction: { promise in
            promise.then { s -> Void in
                XCTAssertEqual("ok", s)
                return
            }
        }, fulfill: { "ok" })

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testCancellation() {
        let ex1 = expectationWithDescription("")

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

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRecoverWithCancellation() {
        let ex1 = expectationWithDescription("")
        let ex2 = expectationWithDescription("")

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

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCatchCancellation() {
        let ex = expectationWithDescription("")

        after(0).then { _ in
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.error(policy: .AllErrors) { err -> Void in
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testThensAreSequentialForLongTime() {
        var values = [Int]()
        let ex = expectationWithDescription("")
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
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
