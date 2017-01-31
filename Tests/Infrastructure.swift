import XCTest

extension XCTestCase {
    static let defaultTimeout: TimeInterval = getenv("TRAVIS") == nil ? 3 : 20

    func wait(timeout: TimeInterval = XCTestCase.defaultTimeout, file: StaticString = #file, line: UInt = #line, body: (XCTestExpectation) -> Void) {
        let ex = expectation(description: "")
        body(ex)

        switch XCTWaiter().wait(for: [ex], timeout: timeout) {
        case .completed:
            break
        case .incorrectOrder, .invertedFulfillment, .timedOut:
            XCTFail("\(timeout) seconds wait expired", file: file, line: line)
        }
    }
}
