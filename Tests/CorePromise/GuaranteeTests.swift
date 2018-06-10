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

    func testWait() {
        XCTAssertEqual(after(.milliseconds(100)).map(on: nil){ 1 }.wait(), 1)
    }

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
}
