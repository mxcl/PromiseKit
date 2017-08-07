import XCTest
import PromiseKit

class RaceTests: XCTestCase {
    func test1() {
        let ex = expectation(description: "")
        race(after(.milliseconds(10)).map{ 1 }, after(seconds: 1).map{ 2 }).done { index in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test2() {
        let ex = expectation(description: "")
        race(after(seconds: 1).map{ 1 }, after(.milliseconds(10)).map{ 2 }).done { index in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test1Array() {
        let ex = expectation(description: "")
        let promises = [after(.milliseconds(10)).map{ 1 }, after(seconds: 1).map{ 2 }]
        try! race(promises).done { index in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test2Array() {
        let ex = expectation(description: "")
        let promises = [after(seconds: 1).map{ 1 }, after(.milliseconds(10)).map{ 2 }]
        try! race(promises).done { index in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
