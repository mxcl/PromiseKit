import XCTest
import PromiseKit

class RaceTests: XCTestCase {
    func test1() {
        let ex = expectation(description: "")
        let after1 = cancellable(after(.milliseconds(10)))
        let after2 = cancellable(after(seconds: 1))
        race(after1.then{ cancellable(Promise.value(1)) }, after2.map { 2 }).done { index in
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
        let after1 = cancellable(after(seconds: 1)).map { 1 }
        let after2 = cancellable(after(.milliseconds(10))).map { 2 }
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
        let promises = [cancellable(after(.milliseconds(10))).map { 1 }, cancellable(after(seconds: 1)).map { 2 }]
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
        let after1 = cancellable(after(seconds: 1)).map { 1 }
        let after2 = cancellable(after(.milliseconds(10))).map { 2 }
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
}
