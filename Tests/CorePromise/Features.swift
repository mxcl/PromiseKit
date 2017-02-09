import PromiseKit
import XCTest

class FeatureFlatMapTests: XCTestCase {
    func testPromise() {
        let foo: Any? = ["a": 1]

        wait { ex in
            Promise(foo).flatMap{ $0 as? [String: Any] }.then {
                XCTAssertEqual($0["a"] as? Int, 1)
                ex.fulfill()
            }
        }
    }

    func testGuarantee() {
        let foo: Any? = ["a": 1]

        wait { ex in
            Guarantee(foo).flatMap{ $0 as? [String: Any] }.then {
                XCTAssertEqual($0["a"] as? Int, 1)
                ex.fulfill()
            }
        }
    }
}


class FeatureAfterTests: XCTestCase {
    func testZero() {
        wait { ex in
            after(interval: 0).then(execute: ex.fulfill)
        }
    }

    func testNegative() {
        wait { ex in
            after(interval: -1).then(execute: ex.fulfill)
        }
    }

    func testPositive() {
        wait { ex in
            after(interval: 1).then(execute: ex.fulfill)
        }
    }
}


class FeatureRaceTests: XCTestCase {
    func testCompilationAmbiguity() {
        let p1 = after(interval: 0.01).then{ 1 }
        let p2 = after(interval: 0.01).then{ 1 }

        let p3 = race([p1, p2])
        let p4 = race(p1, p2)

        XCTAssert(p1 is Guarantee<Int>)
        XCTAssert(p2 is Guarantee<Int>)
        XCTAssert(p3 is Guarantee<Int>)
        XCTAssert(p4 is Guarantee<Int>)

        let p5: Promise<Int> = after(interval: 0.01).then{ 1 }
        let p6: Promise<Int> = after(interval: 0.01).then{ 1 }

        let p7 = race([p5, p6])
        let p8 = race(p5, p6)

        XCTAssert(p5 is Promise<Int>)
        XCTAssert(p6 is Promise<Int>)
        XCTAssert(p7 is Promise<Int>)
        XCTAssert(p8 is Promise<Int>)
    }

    func testSomeoneWins() {
        let p1: Promise<Int> = after(interval: 0.2).then{ 1 }
        let p2: Promise<Int> = Promise{ _ in }

        wait { ex in
            race(p1, p2).then { value in
                XCTAssertEqual(value, 1)
                ex.fulfill()
            }
        }
    }
}
