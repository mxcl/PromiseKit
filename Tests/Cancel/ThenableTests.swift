import PromiseKit
import XCTest

class ThenableTests: XCTestCase {
    func testGet() {
        let ex1 = expectation(description: "")
        Promise.value(1).cancellize().get { _ in
            XCTFail()
        }.done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex1.fulfill() : XCTFail()
        }.cancel()
        wait(for: [ex1], timeout: 5)
    }

    func testCompactMap() {
        let ex = expectation(description: "")
        Promise.value(1.0).cancellize().compactMap { _ in
            XCTFail()
        }.done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        wait(for: [ex], timeout: 5)
    }

    func testCompactMapThrows() {

        enum E: Error { case dummy }

        let ex = expectation(description: "")
        let promise = Promise.value("a").cancellize()
        promise.compactMap { _ -> Int in
            promise.cancel()
            throw E.dummy
        }.catch(policy: .allErrors) {
            if case E.dummy = $0 {} else {
                XCTFail()
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }

    func testRejectedPromiseCompactMap() {

        enum E: Error { case dummy }

        let ex = expectation(description: "")
        CancellablePromise(error: E.dummy).compactMap {
            XCTFail()
        }.catch(policy: .allErrors) {
            if case E.dummy = $0 {} else {
                XCTFail()
            }
            ex.fulfill()
        }.cancel()
        wait(for: [ex], timeout: 5)
    }

    func testPMKErrorCompactMap() {
        let ex = expectation(description: "")
        Promise.value("a").cancellize().compactMap {
            Int($0)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        wait(for: [ex], timeout: 5)
    }

    func testCompactMapValues() {
        let ex = expectation(description: "")
        let promise = Promise.value(["1","2","a","4"]).cancellize()
        promise.compactMapValues {
            Int($0)
        }.done {
            promise.cancel()
            XCTAssertEqual([1,2,4], $0)
            ex.fulfill()
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        wait(for: [ex], timeout: 5)
    }

    func testThenMap() {
        let ex = expectation(description: "")
        let promise = Promise.value([1,2,3,4]).cancellize()
        promise.thenMap { (x: Int) -> Promise<Int> in
            promise.cancel()
            return Promise.value(x) // Intentionally use `Promise` rather than `CancellablePromise`
        }.done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }
        wait(for: [ex], timeout: 5)
    }

    func testThenFlatMap() {
        let ex = expectation(description: "")
        Promise.value([1,2,3,4]).cancellize().thenFlatMap { (x: Int) -> CancellablePromise<[Int]> in
            XCTFail()
            return Promise.value([x, x]).cancellize()
        }.done {
            XCTFail()
            XCTAssertEqual([1,1,2,2,3,3,4,4], $0)
            ex.fulfill()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        wait(for: [ex], timeout: 5)
    }

    func testLastValueForEmpty() {
        XCTAssertTrue(Promise.value([]).cancellize().lastValue.isRejected)
    }

    func testFirstValueForEmpty() {
        XCTAssertTrue(Promise.value([]).cancellize().firstValue.isRejected)
    }

    func testThenOffRejected() {
        // surprisingly missing in our CI, mainly due to
        // extensive use of `done` in A+ tests since PMK 5

        let ex = expectation(description: "")
        CancellablePromise<Int>(error: PMKError.badInput).then { x -> Promise<Int> in
            XCTFail()
            return .value(x)
        }.catch(policy: .allErrors) {
            $0.isCancelled ? XCTFail() : ex.fulfill()
        }.cancel()
        wait(for: [ex], timeout: 5)
    }

    func testBarrier() {
        let ex = expectation(description: "")
        let q = DispatchQueue(label: "\(#file):\(#line)", attributes: .concurrent)
        Promise.value(1).cancellize().done(on: q, flags: .barrier) {
            XCTAssertEqual($0, 1)
            dispatchPrecondition(condition: .onQueueAsBarrier(q))
            ex.fulfill()
        }.catch { _ in
            XCTFail()
        }
        wait(for: [ex], timeout: 5)
    }

    func testDispatchFlagsSyntax() {
        let ex = expectation(description: "")
        let q = DispatchQueue(label: "\(#file):\(#line)", attributes: .concurrent)
        Promise.value(1).cancellize().done(on: q, flags: [.barrier, .inheritQoS]) {
            XCTAssertEqual($0, 1)
            dispatchPrecondition(condition: .onQueueAsBarrier(q))
            ex.fulfill()
        }.catch { _ in
            XCTFail()
        }
        wait(for: [ex], timeout: 5)
    }
}
