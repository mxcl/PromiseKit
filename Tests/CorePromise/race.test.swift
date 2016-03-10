import XCTest
import PromiseKit

class RaceTestCase_Swift: XCTestCase {
    func test1WithVariadicArgs() {
        let ex = expectationWithDescription("")
        race(after(0.01).then{ 1 }, after(1.0).then{ 2 }).then { index -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func test2WithVariadicArgs() {
        let ex = expectationWithDescription("")
        race(after(1.0).then{ 1 }, after(0.01).then{ 2 }).then { index -> Void in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test1WithArrayArgs() {
        let ex = expectationWithDescription("")
        race([after(0.01).then{ 1 }, after(1.0).then{ 2 }]).then { index -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test2WithArrayArgs() {
        let ex = expectationWithDescription("")
        race([after(1.0).then{ 1 }, after(0.01).then{ 2 }]).then { index -> Void in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
