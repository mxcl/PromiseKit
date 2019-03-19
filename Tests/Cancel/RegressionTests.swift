import PromiseKit
import XCTest

class RegressionTests: XCTestCase {
    func testReturningPreviousPromiseWorks() {

        // regression test because we were doing this wrong
        // in our A+ tests implementation for spec: 2.3.1

        do {
            let ex = expectation(description: "")
            let promise1 = CancellablePromise()
            promise1.cancel()
            let promise2 = promise1.then(on: nil) { promise1 }
            promise2.catch(on: nil, policy: .allErrors) {
                ex.fulfill()
                if !$0.isCancelled {
                    XCTFail()
                }
            }
            wait(for: [ex], timeout: 1)
        }
        
        do {
            let ex = expectation(description: "")
            let promise1 = CancellablePromise()
            promise1.cancel()
            let promise2 = promise1.then(on: nil) { () -> CancellablePromise<Void> in
                XCTFail()
                return promise1
            }
            promise2.catch(on: nil, policy: .allErrors) {
                ex.fulfill()
                if !$0.isCancelled {
                    XCTFail()
                }
            }
            wait(for: [ex], timeout: 1)
        }
        
        do {
            let ex = expectation(description: "")
            enum Error: Swift.Error { case dummy }

            let promise1 = CancellablePromise<Void>(error: Error.dummy)
            promise1.cancel()
            let promise2 = promise1.recover(on: nil) { _ in promise1 }
            promise2.catch(on: nil, policy: .allErrors) { err in
                if case PMKError.returnedSelf = err {
                    XCTFail()
                }
                ex.fulfill()
            }
            wait(for: [ex], timeout: 1)
        }
    }
}
