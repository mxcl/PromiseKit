import XCTest
import PromiseKit

class RaceTests: XCTestCase {
    func test1() {
        let ex = expectation(description: "")
        race(after(.milliseconds(10)).then{ Promise.value(1) }, after(seconds: 1).map{ 2 }).done { index in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }.silenceWarning()
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
        race(promises).done { index in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test2Array() {
        let ex = expectation(description: "")
        race(after(seconds: 1).map{ 1 }, after(.milliseconds(10)).map{ 2 }).done { index in
            XCTAssertEqual(index, 2)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testEmptyArray() {
        let ex = expectation(description: "")
        let empty = [Promise<Int>]()
        race(empty).catch {
            guard case PMKError.badInput = $0 else { return XCTFail() }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }
}
