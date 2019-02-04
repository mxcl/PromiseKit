import PromiseKit
import XCTest

class PMKErrorTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertNotNil(PMKError.invalidCallingConvention.errorDescription)
        XCTAssertNotNil(PMKError.returnedSelf.errorDescription)
        XCTAssertNotNil(PMKError.badInput.errorDescription)
        XCTAssertNotNil(PMKError.cancelled.errorDescription)
        XCTAssertNotNil(PMKError.compactMap(1, Int.self).errorDescription)
        XCTAssertNotNil(PMKError.emptySequence.errorDescription)
    }

    func testCustomDebugStringConvertible() {
        XCTAssertFalse(PMKError.invalidCallingConvention.debugDescription.isEmpty)
        XCTAssertFalse(PMKError.returnedSelf.debugDescription.isEmpty)
        XCTAssertNotNil(PMKError.badInput.debugDescription.isEmpty)
        XCTAssertFalse(PMKError.cancelled.debugDescription.isEmpty)
        XCTAssertFalse(PMKError.compactMap(1, Int.self).debugDescription.isEmpty)
        XCTAssertFalse(PMKError.emptySequence.debugDescription.isEmpty)
    }
}
