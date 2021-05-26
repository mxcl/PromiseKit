import Foundation
import PromiseKit
import XCTest

#if canImport(StoreKit)
import StoreKit
#endif

class CancellationTests: XCTestCase {
    func testCancellation() {
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
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        let p = after(seconds: 0).done { _ in
            throw CocoaError.cancelled
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

        waitForExpectations(timeout: 1)
    }

    func testFoundationBridging1() {
        let ex = expectation(description: "")

        let p = after(seconds: 0).done { _ in
            throw CocoaError.cancelled
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
            throw URLError.cancelled
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

    func testDoesntCrashSwift() {
      #if os(macOS)
        // Previously exposed a bridging crash in Swift
        // NOTE nobody was brave enough or diligent enough to report this to Apple :{
        // NOTE no Linux test since this constructor doesn’t exist there
        XCTAssertFalse(NSError().isCancelled)
      #endif

      #if canImport(StoreKit)
        do {
            let err = SKError(.paymentCancelled)
            XCTAssertTrue(err.isCancelled)
            throw err
        } catch {
            XCTAssertTrue(error.isCancelled)
        }

        XCTAssertFalse(SKError(.clientInvalid).isCancelled)

      #endif
    }

    func testBridgeToNSError() {
        // Swift.Error types must be cast to NSError for the bridging to occur.
        // The below would throw an expection about an invalid selector without a cast:
        // `(error as AnyObject).value(forKey: "domain")`
        // This simply checks to make sure `isCancelled` is not making that mistake.

        class TestingError: Error { }

        XCTAssertFalse(TestingError().isCancelled)
    }

#if swift(>=3.2)
    func testIsCancelled() {
        XCTAssertTrue(PMKError.cancelled.isCancelled)
        XCTAssertTrue(URLError.cancelled.isCancelled)
        XCTAssertTrue(CocoaError.cancelled.isCancelled)
        XCTAssertFalse(CocoaError(_nsError: NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.coderInvalidValue.rawValue)).isCancelled)
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

private extension URLError {
    static var cancelled: URLError {
        return .init(_nsError: NSError(domain: NSURLErrorDomain, code: URLError.Code.cancelled.rawValue))
    }
}

private extension CocoaError {
    static var cancelled: CocoaError {
        return .init(_nsError: NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.userCancelled.rawValue))
    }
}
