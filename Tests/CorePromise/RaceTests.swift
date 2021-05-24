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

    func testFulfilled() {
        enum Error: Swift.Error { case test1, test2, test3 }
        let ex = expectation(description: "")
        let promises: [Promise<Int>] = [after(seconds: 1).map { _ in throw Error.test1 }, after(seconds: 2).map { _ in throw Error.test2 }, after(seconds: 5).map { 1 }, after(seconds: 4).map { 2 }, after(seconds: 3).map { _ in throw Error.test3 }]
        race(fulfilled: promises).done {
            XCTAssertEqual($0, 2)
            ex.fulfill()
        }.catch { _ in
            XCTFail()
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testFulfilledEmptyArray() {
        let ex = expectation(description: "")
        let empty = [Promise<Int>]()
        race(fulfilled: empty).catch {
            guard case PMKError.badInput = $0 else { return XCTFail() }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testFulfilledWithNoWinner() {
        enum Error: Swift.Error { case test1, test2 }
        let ex = expectation(description: "")
        let promises: [Promise<Int>] = [after(seconds: 1).map { _ in throw Error.test1 }, after(seconds: 2).map { _ in throw Error.test2 }]
        race(fulfilled: promises).done { _ in
            XCTFail()
            ex.fulfill()
        }.catch {
            guard let pmkError = $0 as? PMKError else { return XCTFail() }
            guard case .noWinner = pmkError else { return XCTFail() }
            guard pmkError.debugDescription == "All thenables passed to race(fulfilled:) were rejected" else { return XCTFail() }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }
}
