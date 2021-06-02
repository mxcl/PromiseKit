import XCTest
import PromiseKit

class ValueTests: XCTestCase {
    func testValueContext() {
        let exComplete = expectation(description: "after completes")
        Promise.value("hi").cancellize().done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }
    
    func testValueDone() {
        let exComplete = expectation(description: "after completes")
        Promise.value("hi").cancellize().done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }
    
    func testValueThen() {
        let exComplete = expectation(description: "after completes")
        
        Promise.value("hi").cancellize().then { (_: String) -> Promise<String> in
            XCTFail("value not cancelled")
            return Promise.value("bye")
        }.done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }
    
    func testFirstlyValueDone() {
        let exComplete = expectation(description: "after completes")
        
        firstly {
            Promise.value("hi")
        }.cancellize().done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }
    
    func testFirstlyThenValueDone() {
        let exComplete = expectation(description: "after completes")
        
        firstly {
            Promise.value("hi").cancellize()
        }.then { (_: String) -> CancellablePromise<String> in
            XCTFail("'hi' not cancelled")
            return Promise.value("there").cancellize()
        }.done { _ in
            XCTFail("'there' not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()

        wait(for: [exComplete], timeout: 5)
    }
    
    func testFirstlyValueDifferentContextDone() {
        let exComplete = expectation(description: "after completes")
        
        let p = firstly {
            return Promise.value("hi")
        }.cancellize().done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }
        p.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }
    
    func testFirstlyValueDoneDifferentContext() {
        let exComplete = expectation(description: "after completes")
        
        firstly {
            Promise.value("hi")
        }.cancellize().done { _ in
            XCTFail("value not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }
    
    func testCancelForPromise_Then() {
        let exComplete = expectation(description: "after completes")
        
        let promise = CancellablePromise<Void> { seal in
            usleep(100000)
            seal.fulfill(())
        }
        promise.then { () throws -> Promise<String> in
            XCTFail("then not cancelled")
            return Promise.value("x")
        }.done { _ in
            XCTFail("done not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()
        
        wait(for: [exComplete], timeout: 5)
    }

    func testCancelForPromise_ThenDone() {
        let exComplete = expectation(description: "done is cancelled")

        let promise = CancellablePromise<Void> { seal in
            usleep(100000)
            seal.fulfill(())
        }
        promise.then { _ -> CancellablePromise<String> in
            XCTFail("then not cancelled")
            return Promise.value("x").cancellize()
        }.done { _ in
            XCTFail("done not cancelled")
        }.catch(policy: .allErrors) { error in
            error.isCancelled ? exComplete.fulfill() : XCTFail("error: \(error)")
        }.cancel()

        wait(for: [exComplete], timeout: 5)
    }
}
