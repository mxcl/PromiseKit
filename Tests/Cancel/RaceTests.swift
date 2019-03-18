import XCTest
import PromiseKit

class RaceTests: XCTestCase {
    func test1() {
        let ex = expectation(description: "")
        let after1 = after(.milliseconds(10)).cancellize()
        let after2 = after(seconds: 1).cancellize()
        race(after1.then{ Promise.value(1) }, after2.map { 2 }).done { index in
            XCTFail()
            XCTAssertEqual(index, 1)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        XCTAssert(after1.isCancelled)
        XCTAssert(after2.isCancelled)
        XCTAssert(after1.cancelAttempted)
        XCTAssert(after2.cancelAttempted)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test2() {
        let ex = expectation(description: "")
        let after1 = after(seconds: 1).cancellize().map { 1 }
        let after2 = after(.milliseconds(10)).cancellize().map { 2 }
        race(after1, after2).done { index in
            XCTFail()
            XCTAssertEqual(index, 2)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        XCTAssert(after1.isCancelled)
        XCTAssert(after2.isCancelled)
        XCTAssert(after1.cancelAttempted)
        XCTAssert(after2.cancelAttempted)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test1Array() {
        let ex = expectation(description: "")
        let promises = [after(.milliseconds(10)).cancellize().map { 1 }, after(seconds: 1).cancellize().map { 2 }]
        race(promises).done { index in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        for p in promises {
            XCTAssert(p.cancelAttempted)
            XCTAssert(p.isCancelled)
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test2Array() {
        let ex = expectation(description: "")
        let after1 = after(seconds: 1).cancellize().map { 1 }
        let after2 = after(.milliseconds(10)).cancellize().map { 2 }
        race(after1, after2).done { index in
            XCTFail()
            XCTAssertEqual(index, 2)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        XCTAssert(after1.isCancelled)
        XCTAssert(after2.isCancelled)
        XCTAssert(after1.cancelAttempted)
        XCTAssert(after2.cancelAttempted)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testEmptyArray() {
        let ex = expectation(description: "")
        let empty = [CancellablePromise<Int>]()
        race(empty).catch {
            guard case PMKError.badInput = $0 else { return XCTFail() }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 1)
    }

    func testReject() {
        let ex = expectation(description: "")
        race(CancellablePromise<Int>(error: PMKError.timedOut), after(.milliseconds(10)).map{ 2 }.cancellize()).done { index in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCancelInner() {
        let ex = expectation(description: "")

        let after1 = after(.milliseconds(10)).cancellize()
        let after2 = after(seconds: 1).cancellize()
        let r = race(after1.then{ Promise.value(1).cancellize() }, after2.map { 2 })

        r.done { index in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }
        after1.cancel()
        waitForExpectations(timeout: 1, handler: nil)
    }
}
