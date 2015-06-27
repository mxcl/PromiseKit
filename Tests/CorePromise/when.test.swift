import XCTest
import PromiseKit

class TestWhen: XCTestCase {

    func testEmpty() {
        let e = expectationWithDescription("")
        let promises: [Promise<Void>] = []
        when(promises).then { _ in
            e.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testInt() {
        let e1 = expectationWithDescription("")
        let p1 = Promise(1)
        let p2 = Promise(2)
        let p3 = Promise(3)
        let p4 = Promise(4)

        when(p1, p2, p3, p4).then { (x: [Int])->() in
            XCTAssertEqual(x[0], 1)
            XCTAssertEqual(x[1], 2)
            XCTAssertEqual(x[2], 3)
            XCTAssertEqual(x[3], 4)
            XCTAssertEqual(x.count, 4)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testTuple() {
        let e1 = expectationWithDescription("")
        let p1 = Promise(1)
        let p2 = Promise("abc")
        when(p1, p2).then{ (x: Int, y: String) -> Void in
            XCTAssertEqual(x, 1)
            XCTAssertEqual(y, "abc")
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testVoid() {
        let e1 = expectationWithDescription("")
        let p1 = Promise(1).then { x -> Void in }
        let p2 = Promise(2).then { x -> Void in }
        let p3 = Promise(3).then { x -> Void in }
        let p4 = Promise(4).then { x -> Void in }

        when(p1,p2,p3,p4).then(e1.fulfill)

        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testRejected() {
        let e1 = expectationWithDescription("")
        let p1 = after(0.01).then{ true }
        let p2 = after(0.01).then{ return Promise<Bool>(error: "Fail") }
        let p3 = Promise(false)
            
        when(p1, p2, p3).catch { _ in
            e1.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testProgress() {
        let ex = expectationWithDescription("")

        XCTAssertNil(NSProgress.currentProgress())

        let p1 = after(0.01)
        let p2 = after(0.02)
        let p3 = after(0.03)
        let p4 = after(0.04)

        let progress = NSProgress(totalUnitCount: 1)
        progress.becomeCurrentWithPendingUnitCount(1)

        when(p1, p2, p3, p4).then { _ -> Void in
            XCTAssertEqual(progress.completedUnitCount, 1)
            ex.fulfill()
        }

        progress.resignCurrent()

        var cum = Double(0)
        for promise in [p1, p2, p3, p4] {
            promise.then { _ -> Void in
                cum += 0.25
                XCTAssertEqual(cum, progress.fractionCompleted)
            }
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testProgressDoesNotExceed100Percent() {
        let ex1 = expectationWithDescription("")
        let ex2 = expectationWithDescription("")

        XCTAssertNil(NSProgress.currentProgress())

        let p1 = after(0.01)
        let p2 = after(0.02).then { Promise<Void>(NSError(domain: "a", code: 1, userInfo: nil)) }
        let p3 = after(0.03)
        let p4 = after(0.04)

        let progress = NSProgress(totalUnitCount: 1)
        progress.becomeCurrentWithPendingUnitCount(1)

        let promise: Promise<Void> = when(p1, p2, p3, p4)

        progress.resignCurrent()

        promise.catch { _ in
            ex2.fulfill()
        }

        var x = 0
        func finally() {
            if ++x == 4 {
                XCTAssertLessThanOrEqual(1, progress.fractionCompleted)
                XCTAssertEqual(progress.completedUnitCount, 1)
                ex1.fulfill()
            }
        }

        let q = dispatch_get_main_queue()
        p1.finally(on: q, finally)
        p2.finally(on: q, finally)
        p3.finally(on: q, finally)
        p4.finally(on: q, finally)

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
