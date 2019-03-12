import PromiseKit
import XCTest

class TimeoutTests: XCTestCase {
    func testTimeout() {
        let ex = expectation(description: "")
        
        race(cancellize(after(seconds: 0.5)), cancellize(timeout(seconds: 0.01))).done {
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
        waitForExpectations(timeout: 1)
    }

    func testReset() {
        let ex = expectation(description: "")
        let p = cancellize(after(seconds: 0.5))
        race(p, cancellize(timeout(seconds: 2.0)), cancellize(timeout(seconds: 0.01))).done {
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
        let p = cancellize(after(seconds: 0.5))
        race(p, cancellize(timeout(seconds: 0.01)), cancellize(timeout(seconds: 0.01))).done {
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
        race(cancellize(after(seconds: 0.01)), cancellize(timeout(seconds: 0.5))).then { _ -> CancellablePromise<Int> in
            ex.fulfill()
            return cancellize(Promise.value(1))
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1)
    }

    func testCancelBeforeTimeout() {
        let ex = expectation(description: "")
        let p = cancellize(after(seconds: 0.5))
        race(p, cancellize(timeout(seconds: 2))).then { _ -> CancellablePromise<Int> in
            XCTFail()
            return cancellize(Promise.value(1))
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
        let ctxt = race(cancellize(after(seconds: 0.5)), cancellize(timeout(seconds: 2))).then { _ -> CancellablePromise<Int> in
            XCTFail()
            return cancellize(Promise.value(1))
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
        promise1 = cancellize(Promise.value("string")).asVoid()
        promise2 = cancellize(Promise.value(22)).asVoid()
        race(promise1, promise2,
            cancellize(Promise.value("string")).asVoid(),
            cancellize(Promise.value(22)).asVoid(),
            cancellize(timeout(seconds: 2))).then { thisone -> CancellablePromise<Int> in
                print("\(thisone)")
            ex.fulfill()
            return cancellize(Promise.value(1))
        }.catch(policy: .allErrors) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1)
    }
}
