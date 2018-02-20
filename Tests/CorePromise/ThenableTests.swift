import PromiseKit
import XCTest

class ThenableTests: XCTestCase {
    func testGet() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        Promise.value(1).get {
            XCTAssertEqual($0, 1)
            ex1.fulfill()
        }.done {
            XCTAssertEqual($0, 1)
            ex2.fulfill()
        }.silenceWarning()
        wait(for: [ex1, ex2], timeout: 10)
    }

    func testCompactMapError() {
        let ex = expectation(description: "")
        Promise.value("a").compactMap {
            Int($0)
        }.catch {
            if case PMKError.compactMap = $0 {} else {
                XCTFail()
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testCompactMapValues() {
        let ex = expectation(description: "")
        Promise.value(["1","2","a","4"]).compactMapValues {
            Int($0)
        }.done {
            XCTAssertEqual([1,2,4], $0)
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }

    func testThenMap() {
        let ex = expectation(description: "")
        Promise.value([1,2,3,4]).thenMap {
            Promise.value($0)
        }.done {
            XCTAssertEqual([1,2,3,4], $0)
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }

    func testThenFlatMap() {
        let ex = expectation(description: "")
        Promise.value([1,2,3,4]).thenFlatMap {
            Promise.value([$0, $0])
        }.done {
            XCTAssertEqual([1,1,2,2,3,3,4,4], $0)
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }

    func testLastValueForEmpty() {
        XCTAssertTrue(Promise.value([]).lastValue.isRejected)
    }

    func testFirstValueForEmpty() {
        XCTAssertTrue(Promise.value([]).firstValue.isRejected)
    }
}
