import Foundation
import PromiseKit
import XCTest

class CancellationTests: XCTestCase {
    func testCancellation() {
        let ex1 = expectation(description: "")

        let p = after(seconds: 0).cancellize().done { _ in
            XCTFail()
        }
        p.catch { _ in
            XCTFail()
        }
        p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex1.fulfill()
        }
        
        p.cancel(with: LocalError.cancel)

        waitForExpectations(timeout: 5)
    }

    func testThrowCancellableErrorThatIsNotCancelled() {
        let expect = expectation(description: "")

        let cc = after(seconds: 0).cancellize().done {
            XCTFail()
        }.catch {
            XCTAssertFalse($0.isCancelled)
            expect.fulfill()
        }
        
        cc.cancel(with: LocalError.notCancel)

        waitForExpectations(timeout: 5)
    }

    func testRecoverWithCancellation() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        let p = after(seconds: 0).cancellize().done { _ in
            XCTFail()
        }.recover(policy: .allErrors) { err -> CancellablePromise<Void> in
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
        
        p.cancel(with: CocoaError.cancelled)

        waitForExpectations(timeout: 5)
    }

    func testFoundationBridging1() {
        let ex = expectation(description: "")

        let p = after(seconds: 0).cancellize().done { _ in
            XCTFail()
        }
        p.catch { _ in
            XCTFail()
        }
        p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex.fulfill()
        }

        p.cancel(with: CocoaError.cancelled)
        
        waitForExpectations(timeout: 5)
    }

    func testFoundationBridging2() {
        let ex = expectation(description: "")

        let p = CancellablePromise().done {
            XCTFail()
        }
        p.catch { _ in
            XCTFail()
        }
        p.catch(policy: .allErrors) {
            XCTAssertTrue($0.isCancelled)
            ex.fulfill()
        }
        
        p.cancel(with: URLError.cancelled)

        waitForExpectations(timeout: 5)
    }

    func testIsCancelled() {
        XCTAssertTrue(PMKError.cancelled.isCancelled)
        XCTAssertTrue(URLError.cancelled.isCancelled)
        XCTAssertTrue(CocoaError.cancelled.isCancelled)
        XCTAssertFalse(CocoaError(_nsError: NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.coderInvalidValue.rawValue)).isCancelled)
    }
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
