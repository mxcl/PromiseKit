import Foundation.NSURLError
import PromiseKit
import XCTest

class CancellationTests: XCTestCase {
    func testCancellation() {
        autoreleasepool {
            let ex1 = expectation(description: "")

            let p = after(seconds: 0).done { _ in
                throw LocalError.cancel
            }.done {
                XCTFail()
            }
            p.catch { _ in
                XCTFail()
            }
            p.catch(policy: .allErrors) {
                XCTAssertTrue($0.isCancelled)
                ex1.fulfill()
            }
        }

        waitForExpectations(timeout: 60)
    }

    func testThrowCancellableErrorThatIsNotCancelled() {
        let expct = expectation(description: "")

        after(seconds: 0).done { _ in
            throw LocalError.notCancel
        }.done {
            XCTFail()
        }.catch {
            XCTAssertFalse($0.isCancelled)
            expct.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testRecoverWithCancellation() {
        autoreleasepool {
            let ex1 = expectation(description: "")
            let ex2 = expectation(description: "")

            let p = after(seconds: 0).done { _ in
                throw NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
            }.recover(policy: .allErrors) { err -> Promise<Void> in
                ex1.fulfill()
                XCTAssertTrue(err.isCancelled)
                throw err
            }.done { _ in
                XCTFail()
            }
            p.catch { _ in
                XCTFail()
            }
            p.catch(policy: .allErrors) {
                XCTAssertTrue($0.isCancelled)
                ex2.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testFoundationBridging1() {
        let ex = expectation(description: "")

        let p = after(seconds: 0).done { _ in
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.userCancelled.rawValue)
        }
        p.catch { _ in
            XCTFail()
        }
        p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testFoundationBridging2() {
        let ex = expectation(description: "")

        let p = Promise().done {
            throw NSError(domain: NSURLErrorDomain, code: URLError.cancelled.rawValue)
        }
        p.catch { _ in
            XCTFail()
        }
        p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testBridging() {
        let ex = expectation(description: "")

        let p = Promise().done {
            throw LocalError.cancel as NSError
        }
        p.catch { _ in
            XCTFail()
        }
        p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)

        // here we verify that Swift’s NSError bridging works as advertised

        XCTAssertTrue(LocalError.cancel.isCancelled)
        XCTAssertTrue((LocalError.cancel as NSError).isCancelled)
    }

#if swift(>=3.2)
    func testIsCancelled() {
        XCTAssertTrue(PMKError.cancelled.isCancelled)
        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: URLError.cancelled.rawValue, userInfo: nil).isCancelled)
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: CocoaError.userCancelled.rawValue, userInfo: nil).isCancelled)
        XCTAssertFalse(NSError(domain: NSCocoaErrorDomain, code: CocoaError.coderInvalidValue.rawValue, userInfo: nil).isCancelled)
    }
#endif
}

private enum LocalError: CancellableError {
    case notCancel
    case cancel

    var isCancelled: Bool {
        switch self {
            case .notCancel: return false
            case .cancel: return true
        }
    }
}
