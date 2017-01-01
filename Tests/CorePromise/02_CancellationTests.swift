import Foundation.NSURLError
import PromiseKit
import XCTest

class CancellationTests: XCTestCase {
    func testCancellation() {
        autoreleasepool {
            let ex1 = expectation(description: "")
            let p1 = after(interval: 0).then {
                throw Error.cancel
            }.then {
                XCTFail()
            }

            p1.catch { _ in
                XCTFail()
            }
            p1.catch(policy: .allErrors) { error in
                XCTAssertTrue(error.isCancelledError);
                XCTAssertTrue((error as? CancellableError)?.isCancelled ?? false)
                ex1.fulfill()
            }
        }

        waitForExpectations(timeout: 60)
    }

    func testThrowCancellableErrorThatIsNotCancelled() {
        let expct = expectation(description: "")

        after(interval: 0).then {
            throw Error.dummy
        }.then {
            XCTFail()
        }.catch { _ in
            expct.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testRecoverWithCancellation() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        let p1 = after(interval: 0).then {
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.recover(policy: .allErrors) { err -> Promise<Void> in
            ex1.fulfill()
            XCTAssertTrue(err.isCancelledError)
            throw err
        }.then {
            XCTFail()
        }

        p1.catch { _ in
            XCTFail()
        }
        p1.catch(policy: .allErrors) { err in
            XCTAssertTrue(err.isCancelledError)
            ex2.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCatchCancellation() {
        let ex = expectation(description: "")

        after(interval: 0).then {
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.catch(policy: .allErrors) { err in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testFoundationBridging1() {
        let ex = expectation(description: "")
        let p1 = Promise().then {
            throw NSError(domain: NSURLErrorDomain, code: URLError.cancelled.rawValue)
        }
        p1.catch { _ in
            XCTFail()
        }
        p1.catch(policy: .allErrors) { error in
            XCTAssertTrue(error.isCancelledError);
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testFoundationBridging2() {
        let ex = expectation(description: "")
        let p1 = Promise().then {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [:])
        }
        p1.catch { _ in
            XCTFail()
        }
        p1.catch(policy: .allErrors) { err in
            XCTAssertTrue(err.isCancelledError);
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testBridging() {
        let ex = expectation(description: "")
        let p1 = Promise().then {
            throw Error.cancel as NSError
        }
        p1.catch { _ in
            XCTFail()
        }
        p1.catch(policy: .allErrors) { err in
            XCTAssertTrue(err.isCancelledError);
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)

        // here we verify that Swift’s NSError bridging works as advertised

        XCTAssertTrue(Error.cancel.isCancelled)
        XCTAssertTrue(Error.cancel.isCancelledError)
        XCTAssertTrue((Error.cancel as NSError).isCancelled)
        XCTAssertTrue(((Error.cancel as NSError) as Swift.Error).isCancelledError)
    }
}

private enum Error: CancellableError {
    case dummy
    case cancel

    var isCancelled: Bool {
        switch self {
            case .dummy: return false
            case .cancel: return true
        }
    }
}
