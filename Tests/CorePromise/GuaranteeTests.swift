import PromiseKit
import XCTest

class GuaranteeTests: XCTestCase {
    func testInit() {
        let ex = expectation(description: "")
        Guarantee { seal in
            seal(1)
        }.done {
            XCTAssertEqual(1, $0)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 10)
    }

    func testMap() {
        let ex = expectation(description: "")

        Guarantee.value(1).map {
            $0 * 2
        }.done {
            XCTAssertEqual(2, $0)
            ex.fulfill()
        }

        wait(for: [ex], timeout: 10)
    }

    #if swift(>=4) && !swift(>=5.2)
    func testMapByKeyPath() {
        let ex = expectation(description: "")

        Guarantee.value(Person(name: "Max")).map(\.name).done {
            XCTAssertEqual("Max", $0)
            ex.fulfill()
        }

        wait(for: [ex], timeout: 10)
    }
    #endif

    func testWait() {
        XCTAssertEqual(after(.milliseconds(100)).map(on: nil){ 1 }.wait(), 1)
    }

    func testMapValues() {
        let ex = expectation(description: "")

        Guarantee.value([1, 2, 3])
            .mapValues { $0 * 2 }
            .done { values in
                XCTAssertEqual([2, 4, 6], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }

    #if swift(>=4) && !swift(>=5.2)
    func testMapValuesByKeyPath() {
        let ex = expectation(description: "")

        Guarantee.value([Person(name: "Max"), Person(name: "Roman"), Person(name: "John")])
            .mapValues(\.name)
            .done { values in
                XCTAssertEqual(["Max", "Roman", "John"], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }
    #endif

    func testFlatMapValues() {
        let ex = expectation(description: "")

        Guarantee.value([1, 2, 3])
            .flatMapValues { [$0, $0] }
            .done { values in
                XCTAssertEqual([1, 1, 2, 2, 3, 3], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }

    func testCompactMapValues() {
        let ex = expectation(description: "")

        Guarantee.value(["1","2","a","3"])
            .compactMapValues { Int($0) }
            .done { values in
                XCTAssertEqual([1, 2, 3], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }

    #if swift(>=4) && !swift(>=5.2)
    func testCompactMapValuesByKeyPath() {
        let ex = expectation(description: "")

        Guarantee.value([Person(name: "Max"), Person(name: "Roman", age: 26), Person(name: "John", age: 23)])
            .compactMapValues(\.age)
            .done { values in
                XCTAssertEqual([26, 23], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }
    #endif

    func testThenMap() {

        let ex = expectation(description: "")

        Guarantee.value([1, 2, 3])
            .thenMap { Guarantee.value($0 * 2) }
            .done { values in
                XCTAssertEqual([2, 4, 6], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }

    func testThenFlatMap() {

        let ex = expectation(description: "")

        Guarantee.value([1, 2, 3])
            .thenFlatMap { Guarantee.value([$0, $0]) }
            .done { values in
                XCTAssertEqual([1, 1, 2, 2, 3, 3], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }

    func testFilterValues() {

        let ex = expectation(description: "")

        Guarantee.value([1, 2, 3])
            .filterValues { $0 > 1 }
            .done { values in
                XCTAssertEqual([2, 3], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }

    #if swift(>=4) && !swift(>=5.2)
    func testFilterValuesByKeyPath() {

        let ex = expectation(description: "")

        Guarantee.value([Person(name: "Max"), Person(name: "Roman", age: 26, isStudent: false), Person(name: "John", age: 23, isStudent: true)])
            .filterValues(\.isStudent)
            .done { values in
                XCTAssertEqual([Person(name: "John", age: 23, isStudent: true)], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }
    #endif

    func testSorted() {

        let ex = expectation(description: "")

        Guarantee.value([5, 2, 3, 4, 1])
            .sortedValues()
            .done { values in
                XCTAssertEqual([1, 2, 3, 4, 5], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }

    func testSortedBy() {

        let ex = expectation(description: "")

        Guarantee.value([5, 2, 3, 4, 1])
            .sortedValues { $0 > $1 }
            .done { values in
                XCTAssertEqual([5, 4, 3, 2, 1], values)
                ex.fulfill()
            }

        wait(for: [ex], timeout: 10)
    }

    #if swift(>=3.1)
    func testNoAmbiguityForValue() {
        let ex = expectation(description: "")
        let a = Guarantee<Void>.value
        let b = Guarantee<Void>.value(Void())
        let c = Guarantee<Void>.value(())
        when(fulfilled: a, b, c).done {
            ex.fulfill()
        }.cauterize()
        wait(for: [ex], timeout: 10)
    }
    #endif
}
