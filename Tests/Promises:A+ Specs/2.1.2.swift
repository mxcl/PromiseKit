import PromiseKit
import XCTest


class Test2121: XCTestCase {

    // describe: When fulfilled, a promise: must not transition to any other state.

    func test1() {
        testFulfilled { promise, expectations, _ in
            promise.then { _ in
                expectations[0].fulfill()
            }
            promise.error { _ in
                XCTFail()
            }
        }
    }

    func test2() {

        specify("trying to fulfill then immediately reject") { promise, fulfill, reject, expectation in
            promise.then(expectation.fulfill)
            promise.error { _ in XCTFail() }
            fulfill()
            reject(Error.dummy)
        }
    }

    func test3() {

        specify("trying to fulfill then reject, delayed") { promise, fulfill, reject, expectation in
            promise.then(expectation.fulfill)
            promise.error { _ in XCTFail() }
            later {
                fulfill()
                reject(Error.dummy)
            }
        }
    }

    func test4() {

        specify("trying to fulfill immediately then reject delayed") { promise, fulfill, reject, expectation in
            promise.then(expectation.fulfill)
            promise.error { _ in XCTFail() }
            fulfill()
            later {
                reject(Error.dummy)
            }
        }
    }


/////////////////////////////////////////////////////////////////////////

    private func specify(_ desc: String, body: (Promise<Void>, () -> Void, (ErrorProtocol) -> Void, XCTestExpectation) -> Void) {
        let ex1 = expectation(withDescription: "")
        let ex2 = expectation(withDescription: "")
        let (promise, fulfill, reject) = Promise<Void>.pendingPromise()

        body(promise, fulfill, reject, ex2)

        later(2) {
            ex1.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
