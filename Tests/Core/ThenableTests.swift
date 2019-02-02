import PromiseKit
import Dispatch
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

    func testCompactMap() {
        let ex = expectation(description: "")
        Promise.value(1.0).compactMap {
            Int($0)
        }.done {
            XCTAssertEqual($0, 1)
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }

    func testCompactMapThrows() {

        enum E: Error { case dummy }

        let ex = expectation(description: "")
        Promise.value("a").compactMap { x -> Int in
            throw E.dummy
        }.catch {
            if case E.dummy = $0 {} else {
                XCTFail()
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testRejectedPromiseCompactMap() {

        enum E: Error { case dummy }

        let ex = expectation(description: "")
        Promise(error: E.dummy).compactMap {
            Int($0)
        }.catch {
            if case E.dummy = $0 {} else {
                XCTFail()
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testPMKErrorCompactMap() {
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

    func testThenOffRejected() {
        // surprisingly missing in our CI, mainly due to
        // extensive use of `done` in A+ tests since PMK 5

        let ex = expectation(description: "")
        Promise<Int>(error: PMKError.badInput).then { x -> Promise<Int> in
            XCTFail()
            return .value(x)
        }.catch { _ in
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testBarrier() {
        let ex = expectation(description: "")
        let q = DispatchQueue(label: "\(#file):\(#line)", attributes: .concurrent)
        Promise.value(1).done(on: q, flags: .barrier) {
            XCTAssertEqual($0, 1)
            dispatchPrecondition(condition: .onQueueAsBarrier(q))
            ex.fulfill()
        }.catch { _ in
            XCTFail()
        }
        wait(for: [ex], timeout: 10)
    }

    func testDispatchFlagsSyntax() {
        let ex = expectation(description: "")
        let q = DispatchQueue(label: "\(#file):\(#line)", attributes: .concurrent)
        Promise.value(1).done(on: q, flags: [.barrier, .inheritQoS]) {
            XCTAssertEqual($0, 1)
            dispatchPrecondition(condition: .onQueueAsBarrier(q))
            ex.fulfill()
            }.catch { _ in
                XCTFail()
        }
        wait(for: [ex], timeout: 10)
    }
}
