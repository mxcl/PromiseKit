import XCTest
import PromiseKit

class RaceTests: XCTestCase {
    func test1() {
        let ex = expectation(description: "")
        race(after(interval: .milliseconds(10)).then{ 1 }, after(seconds: 1).then{ 2 }).then { index -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test2() {
        let ex = expectation(description: "")
        race(after(seconds: 1).then{ 1 }, after(interval: .milliseconds(10)).then{ 2 }).then { index -> Void in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test1Array() {
        let ex = expectation(description: "")
        try! race(promises: [after(interval: .milliseconds(10)).then{ 1 }, after(seconds: 1).then{ 2 }]).then { index -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test2Array() {
        let ex = expectation(description: "")
        try! race(promises: [after(seconds: 1).then{ 1 }, after(interval: .milliseconds(10)).then{ 2 }]).then { index -> Void in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
