import Foundation
import XCTest
import PromiseKit

extension XCTestExpectation {
    open func fulfill(error: Error) {
        fulfill()
    }
}

class AfterTests: XCTestCase {
    func fail() { XCTFail() }
    
    func testZero() {
        let ex2 = expectation(description: "")
        let cc2 = after(seconds: 0).cancellize().done(fail).catch(policy: .allErrors, ex2.fulfill)
        cc2.cancel()
        waitForExpectations(timeout: 5, handler: nil)
        
        let ex3 = expectation(description: "")
        let cc3 = after(.seconds(0)).cancellize().done(fail).catch(policy: .allErrors, ex3.fulfill)
        cc3.cancel()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testNegative() {
        let ex2 = expectation(description: "")
        let cc2 = after(seconds: -1).cancellize().done(fail).catch(policy: .allErrors, ex2.fulfill)
        cc2.cancel()
        waitForExpectations(timeout: 5, handler: nil)
        
        let ex3 = expectation(description: "")
        let cc3 = after(.seconds(-1)).cancellize().done(fail).catch(policy: .allErrors, ex3.fulfill)
        cc3.cancel()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testPositive() {
        let ex2 = expectation(description: "")
        let cc2 = after(seconds: 1).cancellize().done(fail).catch(policy: .allErrors, ex2.fulfill)
        cc2.cancel()
        waitForExpectations(timeout: 5, handler: nil)
        
        let ex3 = expectation(description: "")
        let cc3 = after(.seconds(1)).cancellize().done(fail).catch(policy: .allErrors, ex3.fulfill)
        cc3.cancel()
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCancellableAfter() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        // Test the normal 'after' function
        let exComplete = expectation(description: "after completes")
        let afterPromise = after(seconds: 0)
        afterPromise.done {
            exComplete.fulfill()
        }.catch { error in
            XCTFail("afterPromise failed with error: \(error)")
        }
        
        let exCancelComplete = expectation(description: "after completes")
        
        // Test  cancellable `after` to ensure it is fulfilled if not cancelled
        let cancelIgnoreAfterPromise = after(seconds: 0).cancellize()
        cancelIgnoreAfterPromise.done {
            exCancelComplete.fulfill()
        }.catch(policy: .allErrors) { error in
            XCTFail("cancelIgnoreAfterPromise failed with error: \(error)")
        }
        
        // Test cancellable `after` to ensure it is cancelled
        let cancellableAfterPromise = after(seconds: 0).cancellize()
        cancellableAfterPromise.done {
            XCTFail("cancellableAfter not cancelled")
        }.catch(policy: .allErrorsExceptCancellation) { error in
            XCTFail("cancellableAfterPromise failed with error: \(error)")
        }.cancel()
        
        // Test cancellable `after` to ensure it is cancelled and throws a `CancellableError`
        let exCancel = expectation(description: "after cancels")
        let cancellableAfterPromiseWithError = after(seconds: 0).cancellize()
        cancellableAfterPromiseWithError.done {
            XCTFail("cancellableAfterWithError not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exCancel.fulfill() : XCTFail("unexpected error \(error)")
        }.cancel()
        
        wait(for: [exComplete, exCancelComplete, exCancel], timeout: 5)
    }
    
    func testCancelForPromise_Done() {
        let exComplete = expectation(description: "done is cancelled")
        
        let promise = CancellablePromise<Void> { seal in
            seal.fulfill(())
        }
        promise.done { _ in
            XCTFail("done not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }
        
        promise.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }
    
    func testCancelForGuarantee_Done() {
        let exComplete = expectation(description: "done is cancelled")
        
        after(seconds: 0).cancellize().done { _ in
            XCTFail("done not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }
}
