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
}
