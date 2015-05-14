import Foundation
import XCTest
import PromiseKit

class TestErrorUnhandler: XCTestCase {

    override func tearDown() {
        PMKUnhandledErrorHandler = { _ in }
    }

    private func twice(@noescape body: (Promise<Int>, XCTestExpectation) -> Void) {
        autoreleasepool {
            let ex = expectationWithDescription("Sealed")
            body(Promise<Int>(error: "HI", code: 1), ex)
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        autoreleasepool {
            let ex = expectationWithDescription("Unsealed")
            let p = Promise<Int>{ sealant in
                sealant.resolve(1)
            }.then { _ -> Promise<Int> in
                return Promise(error: "a", code: 1)
            }
            body(p, ex)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // handler is called if error is not handled
    func test1() {
        twice { promise, ex in
            PMKUnhandledErrorHandler = { err in
                ex.fulfill()
            }
        }
    }

    // handler is *not* called if error is caught
    func test2() {
        twice { promise, ex in
            PMKUnhandledErrorHandler = { err in
                XCTFail()
            }
            promise.catch { error in
                ex.fulfill()
            }
        }
    }

    // handler is *not* called if error is recovered
    func test3() {
        twice { promise, ex in
            PMKUnhandledErrorHandler = { err in
                XCTFail()
            }
            promise.recover { error -> Promise<Int> in
                return Promise(1)
            }.finally {
                ex.fulfill()
            }
        }
    }

    // handler is *still* called if error is *not* recovered
    func test4() {
        twice { promise, ex in
            PMKUnhandledErrorHandler = { err in
                ex.fulfill()
            }
            promise.recover { error -> Promise<Int> in
                return Promise(error)
            }
        }
    }

    // handler is called *once* if recovery fails with a *different* error
    func test5() {
        twice { promise, ex in
            PMKUnhandledErrorHandler = { err in
                ex.fulfill()
            }
            promise.recover { error -> Promise<Int> in
                return Promise(error: "a", code: 123)
            }
        }
    }

    // handler is *not* called if error recovery fails with same error but eventually error is caught
    func test6() {
        twice { promise, ex2 in
            let ex1 = expectationWithDescription("")

            PMKUnhandledErrorHandler = { err in
                XCTFail()
            }
            promise.recover { error in
                return Promise(error)
            }.then { x in
                XCTFail()
            }.finally {
                ex1.fulfill()
            }.catch { err in
                ex2.fulfill()
            }
        }
    }
}
