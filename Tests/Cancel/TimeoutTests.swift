import PromiseKit
import XCTest

class TimeoutTests: XCTestCase {
    func testTimeout() {
        let ex = expectation(description: "")
        
        race(after(seconds: 0.5).cancellize(), timeout(seconds: 0.01).cancellize()).done {
        // race(cancellize(after(seconds: 0.5)), timeout(seconds: 0.01)).done {
            XCTFail()
        }.catch(policy: .allErrors) {
            do {
                throw $0
            } catch PMKError.timedOut {
                ex.fulfill()
            } catch {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 5)
    }

    func testReset() {
        let ex = expectation(description: "")
        let p = after(seconds: 0.5).cancellize()
        race(p, timeout(seconds: 2.0).cancellize(), timeout(seconds: 0.01).cancellize()).done {
            XCTFail()
        }.catch(policy: .allErrors) { err in
            do {
                throw err
            } catch PMKError.timedOut {
                _ = (err as? PMKError).debugDescription
                ex.fulfill()
            } catch {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 5)
        XCTAssert(p.isCancelled)
    }
    
    func testDoubleTimeout() {
        let ex = expectation(description: "")
        let p = after(seconds: 0.5).cancellize()
        race(p, timeout(seconds: 0.01).cancellize(), timeout(seconds: 0.01).cancellize()).done {
            XCTFail()
            }.catch(policy: .allErrors) {
                do {
                    throw $0
                } catch PMKError.timedOut {
                    ex.fulfill()
                } catch {
                    XCTFail()
                }
        }
        waitForExpectations(timeout: 5)
        XCTAssert(p.isCancelled)
    }
    
    func testNoTimeout() {
        let ex = expectation(description: "")
        race(after(seconds: 0.01).cancellize(), timeout(seconds: 0.5).cancellize()).then { _ -> Promise<Int> in
            ex.fulfill()
            return Promise.value(1)
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 5)
    }

    func testCancelBeforeTimeout() {
        let ex = expectation(description: "")
        let p = after(seconds: 0.5).cancellize()
        race(p, timeout(seconds: 2).cancellize()).then { _ -> Promise<Int> in
            XCTFail()
            return Promise.value(1)
        }.catch(policy: .allErrors) {
            do {
                throw $0
            } catch PMKError.cancelled {
                ex.fulfill()
            } catch {
                XCTFail()
            }
        }
        p.cancel()
        waitForExpectations(timeout: 5)
    }

    func testCancelRaceBeforeTimeout() {
        let ex = expectation(description: "")
        let ctxt = race(after(seconds: 0.5).cancellize(), timeout(seconds: 2).cancellize()).then { _ -> Promise<Int> in
            XCTFail()
            return Promise.value(1)
        }.catch(policy: .allErrors) {
            do {
                throw $0
            } catch PMKError.cancelled {
                ex.fulfill()
            } catch {
                XCTFail()
            }
        }.cancelContext
        ctxt.cancel()
        waitForExpectations(timeout: 5)
    }

    func testMixTypes() {
        let ex = expectation(description: "")
        let promise1, promise2: CancellablePromise<Void>
        promise1 = Promise.value("string").cancellize().asVoid()
        promise2 = Promise.value(22).cancellize().asVoid()
        race(promise1, promise2,
            Promise.value("string").cancellize().asVoid(),
            Promise.value(22).cancellize().asVoid(),
            timeout(seconds: 2).cancellize()).then { thisone -> Promise<Int> in
                print("\(thisone)")
            ex.fulfill()
            return Promise.value(1)
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 5)
    }
}
