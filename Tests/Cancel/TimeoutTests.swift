import PromiseKit
import XCTest

class TimeoutTests: XCTestCase {
    func testTimeout() {
        let ex = expectation(description: "")
        cancellable(after(seconds: 0.5)).then { _ -> CancellablePromise<Int> in
            XCTFail()
            return cancellable(Promise.value(1))
        }.catch(policy: .allErrors) {
            do {
                throw $0
            } catch PMKError.timeout {
                ex.fulfill()
            } catch {
                XCTFail()
            }
        }.cancelContext.timeout(after: 0.01)
        waitForExpectations(timeout: 1)
    }

    func testReset() {
        let ex = expectation(description: "")
        let ctxt = cancellable(after(seconds: 0.5)).then { _ -> CancellablePromise<Int> in
            XCTFail()
            return cancellable(Promise.value(1))
        }.catch(policy: .allErrors) {
            do {
                throw $0
            } catch PMKError.timeout {
                ex.fulfill()
            } catch {
                XCTFail()
            }
        }.cancelContext
        ctxt.timeout(after: 2.0)
        ctxt.timeout(after: 0.01)
        waitForExpectations(timeout: 1)
    }
    
    func testNoTimeout() {
        let ex = expectation(description: "")
        let ctxt = cancellable(after(seconds: 0.01)).then { _ -> CancellablePromise<Int> in
            ex.fulfill()
            return cancellable(Promise.value(1))
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }.cancelContext
        ctxt.timeout(after: 0.5)
        waitForExpectations(timeout: 1)
    }

    func testCancelBeforeTimeout() {
        let ex = expectation(description: "")
        let ctxt = cancellable(after(seconds: 0.5)).then { _ -> CancellablePromise<Int> in
            XCTFail()
            return cancellable(Promise.value(1))
        }.catch(policy: .allErrors) {
            do {
                throw $0
            } catch PMKError.cancelled {
                ex.fulfill()
            } catch {
                XCTFail()
            }
        }.cancelContext
        ctxt.timeout(after: 0.01)
        ctxt.cancel()
        waitForExpectations(timeout: 1)
    }
}
