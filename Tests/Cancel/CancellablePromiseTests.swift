import Foundation
import PromiseKit
import XCTest

class CancellablePromiseTests: XCTestCase {
    func login() -> Promise<Int> {
        return Promise.value(1)
    }
    
    func fetch(avatar: Int) -> CancellablePromise<Int> {
        return Promise.value(avatar + 2).cancellize()
    }
    
    func testCancellablePromiseEmbeddedInStandardPromiseChain() {
        let ex = expectation(description: "")
        var imageView: Int?
        let promise = firstly {  /// <-- ERROR: Ambiguous reference to member 'firstly(execute:)'
            /* The 'cancellize' method initiates a cancellable promise chain by
             returning a 'CancellablePromise'. */
            login().cancellize() /// CHANGE TO: "login().cancellize()"
        }.then { creds in
            self.fetch(avatar: creds)
        }.done { image in
            imageView = image
            XCTAssert(imageView == 3)
            XCTFail()
        }.catch(policy: .allErrors) { error in
            if error.isCancelled {
                // the chain has been cancelled!
                ex.fulfill()
            } else {
                XCTFail()
            }
        }
        
        // …
        
        promise.cancel()
        
        waitForExpectations(timeout: 1)
    }
    
    func testReturnTypeForAMultiLineClosureIsNotExplicitlyStated() {
        let ex = expectation(description: "")
        var imageView: Int?
        firstly {
            login()
        }.cancellize().then { creds -> CancellablePromise<Int> in
            let f = self.fetch(avatar: creds)
            return f
        }.done { image in
            imageView = image
            XCTAssert(imageView == 3)
            ex.fulfill()
        }.catch(policy: .allErrors) { error in
            XCTFail()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testTryingToCancelAStandardPromiseChain() {
        let ex = expectation(description: "")
        var imageView: Int?
        let promise = firstly {
            login()
        }.cancellize().then { creds in
            self.fetch(avatar: creds)
        }.done { image in
            imageView = image
            XCTAssert(imageView == 3)
            XCTFail()
        }.catch(policy: .allErrors) { error in
            if error.isCancelled {
                // the chain has been cancelled!
                ex.fulfill()
            } else {
                XCTFail()
            }
        }
        
        // …
        
        promise.cancel()  /// <-- ERROR: Value of type 'PMKFinalizer' has no member 'cancel'

        waitForExpectations(timeout: 1)
    }
    
    func testCancel() {
        let ex = expectation(description: "")
        let p = CancellablePromise<Int>.pending()
        p.promise.then { (val: Int) -> Promise<String> in
            Promise.value("hi")
        }.done { _ in
            XCTFail()
            ex.fulfill()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }
        p.resolver.fulfill(3)
        p.promise.cancel()

        wait(for: [ex], timeout: 1)
    }
    
    func testFirstly() {
        let ex = expectation(description: "")
        firstly {
            Promise.value(3)
        }.cancellize().then { (_: Int) -> Promise<String> in
            XCTFail()
            return Promise.value("hi")
        }.done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        
        wait(for: [ex], timeout: 1)
    }
    
    func testFirstlyWithPromise() {
        let ex = expectation(description: "")
        firstly {
            return Promise.value(3)
        }.cancellize().then { (_: Int) -> Promise<String> in
            XCTFail()
            return Promise.value("hi")
        }.done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail("\($0)")
        }.cancel()
        
        wait(for: [ex], timeout: 1)
    }
    
    func testThenMapSuccess() {
        let ex = expectation(description: "")
        firstly {
            Promise.value([1,2,3])
        }.cancellize().thenMap { (integer: Int) -> Promise<Int> in
            return Promise.value(integer * 2)
        }.done { _ in
            ex.fulfill()
            // $0 => [2,4,6]
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testThenMapCancel() {
        let ex = expectation(description: "")
        firstly {
            Promise.value([1,2,3])
        }.cancellize().thenMap { (integer: Int) -> Promise<Int> in
            XCTFail()
            return Promise.value(integer * 2)
        }.done { _ in
            XCTFail()
            // $0 => [2,4,6]
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1)
    }
    
    func testChain() {
        let ex = expectation(description: "")
        firstly {
            Promise.value(1)
        }.cancellize().then { (integer: Int) -> Promise<Int> in
            XCTFail()
            return Promise.value(integer * 2)
        }.done { _ in
            // $0 => [2,4,6]
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex.fulfill() : XCTFail()
        }.cancel()
        waitForExpectations(timeout: 1)
    }
    
    func testBridge() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        
        let (promise, seal) = Promise<Void>.pending()
        DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + 0.2) { seal.fulfill(()) }

        CancellablePromise(promise).done { _ in
            XCTFail()
        }.catch(policy: .allErrors) {
            $0.isCancelled ? ex2.fulfill() : XCTFail()
        }.cancel()
        
        promise.done { _ in
            ex1.fulfill()
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        
        waitForExpectations(timeout: 1)
    }
}
