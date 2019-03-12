import XCTest
import PromiseKit

class ValueTests: XCTestCase {
    func testValueContext() {
        let exComplete = expectation(description: "after completes")
        cancellize(Promise.value("hi")).done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 1)
    }
    
    func testValueDone() {
        let exComplete = expectation(description: "after completes")
        cancellize(Promise.value("hi")).done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 1)
    }
    
    func testValueThen() {
        let exComplete = expectation(description: "after completes")
        
        cancellize(Promise.value("hi")).then { (_: String) -> CancellablePromise<String> in
            XCTFail("value not cancelled")
            return cancellize(Promise.value("bye"))
        }.done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 1)
    }
    
    func testFirstlyValueDone() {
        let exComplete = expectation(description: "after completes")
        
        firstly {
            cancellize(Promise.value("hi"))
        }.done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 1)
    }
    
    func testFirstlyThenValueDone() {
        let exComplete = expectation(description: "after completes")
        
        firstly {
            cancellize(Promise.value("hi"))
        }.then { (_: String) -> CancellablePromise<String> in
            XCTFail("'hi' not cancelled")
            return cancellize(Promise.value("there"))
        }.done { _ in
            XCTFail("'there' not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()

        wait(for: [exComplete], timeout: 1)
    }
    
    func testFirstlyValueDifferentContextDone() {
        let exComplete = expectation(description: "after completes")
        
        let p = firstly {
            return cancellize(Promise.value("hi"))
        }.done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }
        p.cancel()
        
        wait(for: [exComplete], timeout: 1)
    }
    
    func testFirstlyValueDoneDifferentContext() {
        let exComplete = expectation(description: "after completes")
        
        firstly {
            cancellize(Promise.value("hi"))
        }.done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 1)
    }
    
    func testCancelForPromise_Then() {
        let exComplete = expectation(description: "after completes")
        
        let promise = CancellablePromise<Void> { seal in
            usleep(100000)
            seal.fulfill(())
        }
        promise.cancellableThen { () throws -> Promise<String> in
            XCTFail("then not cancelled")
            return Promise.value("x")
        }.done { _ in
            XCTFail("done not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 1)
    }

    func testCancelForPromise_ThenDone() {
        let exComplete = expectation(description: "done is cancelled")

        let promise = CancellablePromise<Void> { seal in
            usleep(100000)
            seal.fulfill(())
        }
        promise.then { _ -> CancellablePromise<String> in
            XCTFail("then not cancelled")
            return cancellize(Promise.value("x"))
        }.done { _ in
            XCTFail("done not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()

        wait(for: [exComplete], timeout: 1)
    }
}
