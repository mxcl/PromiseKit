import Foundation
import PromiseKit
import XCTest

class CancellationTests: XCTestCase {
    func testCancellation() {
        let ex = expectation(description: "")

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
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testThrowCancellableErrorThatIsNotCancelled() {
        let ex = expectation(description: "")

        after(seconds: 0).done { _ in
            throw LocalError.notCancel
        }.done {
            XCTFail()
        }.catch {
            XCTAssertFalse($0.isCancelled)
            ex.fulfill()
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

    func testEnsureWithCancellation() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        let p = after(seconds: 0).done { _ in
            throw LocalError.cancel
        }

        _ = p.ensure {
            XCTFail()
        }

        _ = p.ensure(policy: .allErrors) {
            ex1.fulfill()
        }

        _ = p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex2.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testEnsureThenWithCancellation() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        let p = after(seconds: 0).done { _ in
            throw LocalError.cancel
        }

        _ = p.ensureThen {
            XCTFail()
            return Guarantee.value(())
        }

        _ = p.ensureThen(policy: .allErrors) {
            ex1.fulfill()
            return Guarantee.value(())
        }

        _ = p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex2.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testTapWithCancellation() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        let p = after(seconds: 0).done { _ in
            throw LocalError.cancel
        }

        _ = p.tap { _ in
            XCTFail()
        }

        _ = p.tap(policy: .allErrors) { _ in
            ex1.fulfill()
        }

        _ = p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex2.fulfill()
        }

        waitForExpectations(timeout: 1)
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
