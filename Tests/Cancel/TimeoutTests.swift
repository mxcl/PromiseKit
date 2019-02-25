import PromiseKit
import XCTest

class TimeoutTests: XCTestCase {
    func testTimeout() {
        let ex = expectation(description: "")
        
        race(cancellable(after(seconds: 0.5)), cancellable(timeout(seconds: 0.01))).done {
        // race(cancellable(after(seconds: 0.5)), timeout(seconds: 0.01)).done {
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
        waitForExpectations(timeout: 1)
    }

    func testReset() {
        let ex = expectation(description: "")
        let p = cancellable(after(seconds: 0.5))
        race(p, cancellable(timeout(seconds: 2.0)), cancellable(timeout(seconds: 0.01))).done {
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
        waitForExpectations(timeout: 1)
        XCTAssert(p.isCancelled)
    }
    
    func testDoubleTimeout() {
        let ex = expectation(description: "")
        let p = cancellable(after(seconds: 0.5))
        race(p, cancellable(timeout(seconds: 0.01)), cancellable(timeout(seconds: 0.01))).done {
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
        waitForExpectations(timeout: 1)
        XCTAssert(p.isCancelled)
    }
    
    func testNoTimeout() {
        let ex = expectation(description: "")
        race(cancellable(after(seconds: 0.01)), cancellable(timeout(seconds: 0.5))).then { _ -> CancellablePromise<Int> in
            ex.fulfill()
            return cancellable(Promise.value(1))
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1)
    }

    func testCancelBeforeTimeout() {
        let ex = expectation(description: "")
        let p = cancellable(after(seconds: 0.5))
        race(p, cancellable(timeout(seconds: 2))).then { _ -> CancellablePromise<Int> in
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
        }
        p.cancel()
        waitForExpectations(timeout: 1)
    }

    func testCancelRaceBeforeTimeout() {
        let ex = expectation(description: "")
        let ctxt = race(cancellable(after(seconds: 0.5)), cancellable(timeout(seconds: 2))).then { _ -> CancellablePromise<Int> in
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
        ctxt.cancel()
        waitForExpectations(timeout: 1)
    }

    func testMixTypes() {
        let ex = expectation(description: "")
        let promise1, promise2: CancellablePromise<Void>
        promise1 = cancellable(Promise.value("string")).asVoid()
        promise2 = cancellable(Promise.value(22)).asVoid()
        race(promise1, promise2,
            cancellable(Promise.value("string")).asVoid(),
            cancellable(Promise.value(22)).asVoid(),
            cancellable(timeout(seconds: 2))).then { thisone -> CancellablePromise<Int> in
                print("\(thisone)")
            ex.fulfill()
            return cancellable(Promise.value(1))
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1)
    }
}
