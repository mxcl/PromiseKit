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
            body(Promise<Int>(NSError(domain: "a", code: 1, userInfo: nil)), ex)
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        autoreleasepool {
            let ex = expectationWithDescription("Unsealed")
            let p = Promise { fulfill, _ in
                fulfill(1)
            }.then { _ -> Promise<Int> in
                Promise(NSError(domain: "a", code: 1, userInfo: nil))
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
            promise.report { error in
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
            promise.recover { error in
                throw error
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
                return Promise(NSError(domain: "a", code: 1, userInfo: nil))
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
                throw error
            }.then { x in
                XCTFail()
            }.finally {
                ex1.fulfill()
            }.report { err in
                ex2.fulfill()
            }
        }
    }
}
