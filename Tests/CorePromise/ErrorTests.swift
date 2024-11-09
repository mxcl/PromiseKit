import PromiseKit
import XCTest

class PMKErrorTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertNotNil(PMKError<Void>.invalidCallingConvention.errorDescription)
        XCTAssertNotNil(PMKError<Void>.returnedSelf.errorDescription)
        XCTAssertNotNil(PMKError<Void>.badInput.errorDescription)
        XCTAssertNotNil(PMKError<Void>.cancelled.errorDescription)
        XCTAssertNotNil(PMKError<Int>.compactMap(1).errorDescription)
        XCTAssertNotNil(PMKError<Void>.emptySequence.errorDescription)
    }

    func testCustomDebugStringConvertible() {
        XCTAssertFalse(PMKError<Void>.invalidCallingConvention.debugDescription.isEmpty)
        XCTAssertFalse(PMKError<Void>.returnedSelf.debugDescription.isEmpty)
        XCTAssertNotNil(PMKError<Void>.badInput.debugDescription.isEmpty)
        XCTAssertFalse(PMKError<Void>.cancelled.debugDescription.isEmpty)
        XCTAssertFalse(PMKError<Int>.compactMap(1).debugDescription.isEmpty)
        XCTAssertFalse(PMKError<Void>.emptySequence.debugDescription.isEmpty)
    }
}
