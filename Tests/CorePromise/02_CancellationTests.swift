import Foundation.NSURLError
import PromiseKit
import XCTest

class CancellationTests: XCTestCase {
    func testCancellation() {
        autoreleasepool {
            let ex1 = expectation(description: "")

            InjectedErrorUnhandler = { err in
                XCTAssertTrue(err.isCancelledError);
                XCTAssertTrue((err as? CancellableError)?.isCancelled ?? false);
                ex1.fulfill()
            }

            after(interval: 0).then { _ in
                throw Error.cancel
            }.then {
                XCTFail()
            }.catch { _ in
                XCTFail()
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
        autoreleasepool {
            let ex1 = expectation(description: "")
            let ex2 = expectation(description: "")

            InjectedErrorUnhandler = { err in
                XCTAssertTrue(err.isCancelledError);
                ex2.fulfill()
            }

            after(interval: 0).then { _ in
                throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
            }.recover(policy: .allErrors) { err -> Void in
                ex1.fulfill()
                XCTAssertTrue(err.isCancelledError)
                throw err
            }.then {
                XCTFail()
            }.catch { _ in
                XCTFail()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testCatchCancellation() {
        let ex = expectation(description: "")

        after(interval: 0).then { _ in
            throw NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: nil)
        }.catch(policy: .allErrors) { err in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testFoundationBridging1() {
        let ex = expectation(description: "")

        InjectedErrorUnhandler = { err in
            XCTAssertTrue(err.isCancelledError);
            ex.fulfill()
        }

        Promise(value: ()).then {
            throw NSError(domain: NSURLErrorDomain, code: URLError.cancelled.rawValue)
        }.catch { _ in
            XCTFail()
        }

        waitForExpectations(timeout: 1)
    }

    func testFoundationBridging2() {
        let ex = expectation(description: "")

        InjectedErrorUnhandler = { err in
            XCTAssertTrue(err.isCancelledError);
            ex.fulfill()
        }

        Promise(value: ()).then {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [:])
        }.catch { _ in
            XCTFail()
        }

        waitForExpectations(timeout: 1)
    }

    func testBridging() {
        let ex = expectation(description: "")

        InjectedErrorUnhandler = { err in
            XCTAssertTrue(err.isCancelledError);
            ex.fulfill()
        }

        Promise(value: ()).then {
            throw Error.cancel as NSError
        }.catch { _ in
            XCTFail()
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
