import PromiseKit
import XCTest

private let dummy = 123_987_456


class Test2131: XCTestCase {

    // describe: When rejected, a promise: must not transition to any other state.

    func test1() {
        testRejected { promise, expectations, _ in
            promise.then { _ in
                XCTFail()
            }
            promise.error { _ in
                expectations[0].fulfill()
            }
        }
    }

    func test2() {

        // specify: trying to reject then immediately fulfill

        harness { promise, fulfill, reject, ex in
            promise.then { _ in
                XCTFail()
            }
            promise.error{ _ in
                ex.fulfill()
            }
            reject(Error.dummy)
            fulfill(dummy)
        }
    }

    func test3() {

        // specify: trying to reject then fulfill, delayed

        harness { promise, fulfill, reject, ex in
            promise.then { _ in
                XCTFail()
            }
            promise.error { _ in
                ex.fulfill()
            }
            later {
                reject(Error.dummy)
                fulfill(dummy)
            }
        }
    }

    func test4() {

        // specify: trying to reject immediately then fulfill delayed

        harness { promise, fulfill, reject, ex in
            promise.then { _ in
                XCTFail()
            }
            promise.error { _ in
                ex.fulfill()
            }
            reject(Error.dummy)
            later {
                fulfill(dummy)
            }
        }
    }


/////////////////////////////////////////////////////////////////////////

    private func harness(_ body: (Promise<Int>, (Int) -> Void, (ErrorProtocol) -> Void, XCTestExpectation) -> Void) {
        let ex1 = expectation(withDescription: "")
        let ex2 = expectation(withDescription: "")
        let (promise, fulfill, reject) = Promise<Int>.pendingPromise()

        body(promise, fulfill, reject, ex2)

        later(2) {
            ex1.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
