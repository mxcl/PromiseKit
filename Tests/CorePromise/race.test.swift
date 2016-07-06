import XCTest
import PromiseKit

class RaceTestCase_Swift: XCTestCase {
    func test1() {
        let ex = expectation(withDescription: "")
        race(after(interval: 0.01).then{ 1 }, after(interval: 1.0).then{ 2 }).then { index -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func test2() {
        let ex = expectation(withDescription: "")
        race(after(interval: 1.0).then{ 1 }, after(interval: 0.01).then{ 2 }).then { index -> Void in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func test1Array() {
        let ex = expectation(withDescription: "")
        try! race(promises: [after(interval: 0.01).then{ 1 }, after(interval: 1.0).then{ 2 }]).then { index -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func test2Array() {
        let ex = expectation(withDescription: "")
        try! race(promises: [after(interval: 1.0).then{ 1 }, after(interval: 0.01).then{ 2 }]).then { index -> Void in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
