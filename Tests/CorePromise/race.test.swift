import XCTest
import PromiseKit

class RaceTestCase_Swift: XCTestCase {
    func test1() {
        let ex = expectation(withDescription: "")
        race(after(0.01).then{ 1 }, after(1.0).then{ 2 }).then { index -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func test2() {
        let ex = expectation(withDescription: "")
        race(after(1.0).then{ 1 }, after(0.01).then{ 2 }).then { index -> Void in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func test1Array() {
        let ex = expectation(withDescription: "")
        try! race([after(0.01).then{ 1 }, after(1.0).then{ 2 }]).then { index -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func test2Array() {
        let ex = expectation(withDescription: "")
        try! race([after(1.0).then{ 1 }, after(0.01).then{ 2 }]).then { index -> Void in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
