import PromiseKit
import XCTest

class DeprecationTests: XCTestCase {
    func testWrap1() {
        let dummy = 10

        func completion(_ body: (_ a: Int?, _ b: Error?) -> Void) {
            body(dummy, nil)
        }

        let ex = expectation(description: "")
        wrap(completion).done {
            XCTAssertEqual($0, dummy)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testWrap2() {
        let dummy = 10

        func completion(_ body: (_ a: Int, _ b: Error?) -> Void) {
            body(dummy, nil)
        }

        let ex = expectation(description: "")
        wrap(completion).done {
            XCTAssertEqual($0, dummy)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testWrap3() {
        let dummy = 10

        func completion(_ body: (_ a: Error?, _ b: Int?) -> Void) {
            body(nil, dummy)
        }

        let ex = expectation(description: "")
        wrap(completion).done {
            XCTAssertEqual($0, dummy)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testWrap4() {
        let dummy = 10

        func completion(_ body: (_ a: Error?) -> Void) {
            body(nil)
        }

        let ex = expectation(description: "")
        wrap(completion).done {
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testWrap5() {
        let dummy = 10

        func completion(_ body: (_ a: Int) -> Void) {
            body(dummy)
        }

        let ex = expectation(description: "")
        wrap(completion).done {
            XCTAssertEqual($0, dummy)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testAlways() {
        let ex = expectation(description: "")
        Promise.value(1).always(execute: ex.fulfill)
        wait(for: [ex], timeout: 10)
    }

#if PMKFullDeprecations
    func testFlatMap() {
        let ex = expectation(description: "")
        Promise.value(1).flatMap { _ -> Int? in
            nil
        }.catch {
            //TODO should be `flatMap`, but how to enact that without causing
            // compiler to warn when building PromiseKit for end-users? LOL
            guard case PMKError.compactMap = $0 else { return XCTFail() }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testSequenceMap() {
        let ex = expectation(description: "")
        Promise.value([1, 2]).map {
            $0 + 1
        }.done {
            XCTAssertEqual($0, [2, 3])
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }

    func testSequenceFlatMap() {
        let ex = expectation(description: "")
        Promise.value([1, 2]).flatMap {
            [$0 + 1, $0 + 2]
        }.done {
            XCTAssertEqual($0, [2, 3, 3, 4])
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }
#endif

    func testSequenceFilter() {
        let ex = expectation(description: "")
        Promise.value([0, 1, 2, 3]).filter {
            $0 < 2
        }.done {
            XCTAssertEqual($0, [0, 1])
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }

    func testSorted() {
        let ex = expectation(description: "")
        Promise.value([5, 2, 1, 8]).sorted().done {
            XCTAssertEqual($0, [1,2,5,8])
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testFirst() {
        XCTAssertEqual(Promise.value([1,2]).first.value, 1)
    }

    func testLast() {
        XCTAssertEqual(Promise.value([1,2]).last.value, 2)
    }

    func testPMKErrorFlatMap() {
        XCTAssertNotNil(PMKError.flatMap(1, Int.self).errorDescription)
    }
}


extension Promise {
    func silenceWarning() {}
}
