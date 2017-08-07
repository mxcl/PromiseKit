import PromiseKit
import XCTest

class CatchableTests: XCTestCase {
    func testFinally1() {
        let ex = (expectation(description: ""), expectation(description: ""))
1
        Promise<Void>(error: Error.dummy).catch { _ in
            ex.0.fulfill()
        }.finally {
            ex.1.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testFinally2() {
        let ex = expectation(description: "")

        Promise<Void>(error: PMKError.cancelled).catch { _ in
            XCTFail()
        }.finally {
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}

private enum Error: Swift.Error {
    case dummy
}
