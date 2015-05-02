import XCTest
import PromiseKit

class TestWhen: XCTestCase {
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
}
