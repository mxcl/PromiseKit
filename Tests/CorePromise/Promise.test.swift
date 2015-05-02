import PromiseKit
import XCTest

class TestPromise: XCTestCase {
    override func tearDown() {
        PMKUnhandledErrorHandler = { _ in }
    }

    // can return AnyPromise (that fulfills) in then handler
    func test1() {
        let ex = expectationWithDescription("")
        Promise(1).then { _ -> AnyPromise in
            return AnyPromise(bound: after(0).then{ 1 })
        }.then { x -> Void in
            XCTAssertEqual(x as! Int, 1)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // can return AnyPromise (that rejects) in then handler
    func test2() {
        let ex = expectationWithDescription("")
        Promise(1).then { _ -> AnyPromise in
            return AnyPromise(bound: after(0).then{ Promise<Int>(error: "") })
        }.catch { err -> Void in
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
            XCTAssertTrue(err.cancelled);
            ex1.fulfill()
        }

        after(0).then { _ -> Promise<Int> in
            return Promise(NSError.cancelledError())
        }.then { _ -> Void in
            XCTFail()
        }.catch { _ -> Void in
            XCTFail()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRecoverWithCancellation() {
        let ex1 = expectationWithDescription("")
        let ex2 = expectationWithDescription("")

        PMKUnhandledErrorHandler = { err in
            XCTAssertTrue(err.cancelled);
            ex2.fulfill()
        }

        after(0).then { _ -> Promise<Int> in
            return Promise(NSError.cancelledError())
        }.recover { err -> Promise<Int> in
            ex1.fulfill()
            XCTAssertTrue(err.cancelled)
            return Promise(err)
        }.then { _ -> Void in
            XCTFail()
        }.catch { _ -> Void in
            XCTFail()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCatchCancellation() {
        let ex = expectationWithDescription("")

        after(0).then { _ -> Promise<Int> in
            return Promise(NSError.cancelledError())
        }.catch(policy: .AllErrors) { _ -> Void in
            ex.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
