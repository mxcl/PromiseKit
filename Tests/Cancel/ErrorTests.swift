import PromiseKit
import XCTest

class CancellableErrorTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertNotNil(PMKError.cancelled.errorDescription)
    }
    
    func testCustomDebugStringConvertible() {
        XCTAssertFalse(PMKError.cancelled.debugDescription.isEmpty)
    }
}
