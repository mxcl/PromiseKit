import Foundation
import XCTest
import PromiseKit


private enum Error: ErrorProtocol {
    case dummy
}

class ErrorHandlingTests_Swift: XCTestCase {

    var oldHandler: ((ErrorProtocol) -> Void)!

    override func setUp() {
        oldHandler = PMKUnhandledErrorHandler
    }
    override func tearDown() {
        PMKUnhandledErrorHandler = oldHandler
    }

    private func twice(@noescape _ body: (Promise<Int>, XCTestExpectation) -> Void) {
        autoreleasepool {
            let ex = expectation(withDescription: "Sealed")
            body(Promise<Int>(error: Error.dummy), ex)
        }
        waitForExpectations(withTimeout: 1, handler: nil)

        autoreleasepool {
            let ex = expectation(withDescription: "Unsealed")
            let p = Promise { fulfill, _ in
                fulfill(1)
            }.then { (_: Int) -> Int in
                throw Error.dummy
            }
            body(p, ex)
        }
        waitForExpectations(withTimeout: 1, handler: nil)
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
            promise.error { error in
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
            }.always {
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
            promise.recover { error -> Int in
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
                firstly { throw Error.dummy }
            }
        }
    }

    // handler is *not* called if error recovery fails with same error but eventually error is caught
    func test6() {
        twice { promise, ex2 in
            let ex1 = expectation(withDescription: "")

            PMKUnhandledErrorHandler = { err in
                XCTFail()
            }
            promise.recover { error -> Int in
                throw error
            }.then { x in
                XCTFail()
            }.always {
                ex1.fulfill()
            }.error { err in
                ex2.fulfill()
            }
        }
    }

    // a temporary alias `onError` exists for the `error` function
    func test7() {
        twice { promise, ex in
            PMKUnhandledErrorHandler = { err in
                XCTFail()
            }

            promise.onError { error in
                ex.fulfill()
            }
        }
    }

    func testDoubleRejectDoesNotTriggerUnhandler() {
        enum Error: ErrorProtocol {
            case test
        }

        PMKUnhandledErrorHandler = { err in
            XCTFail()
        }

        let (p, _, r) = Promise<Void>.pendingPromise()

        let ex1 = expectation(withDescription: "")
        let ex2 = expectation(withDescription: "")
        let ex3 = expectation(withDescription: "")
        let ex4 = expectation(withDescription: "")

        after(0.1).then { _ -> Void in r(Error.test); ex1.fulfill() }
        after(0.15).then { _ -> Void in r(Error.test); ex2.fulfill() }.always { ex3.fulfill() }

        p.error { error in
            ex4.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testPassThrough() {
        let ex = expectation(withDescription: "")

        PMKUnhandledErrorHandler = { err in
            ex.fulfill()
        }

        enum Error: ErrorProtocol {
            case test
        }

        _ = Promise<Void> { _, reject in
            after(0.1).then {
                throw Error.test
            }.error { err in
                reject(err)
            }
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testConsumedPromiseStaysConsumedAsAnyPromise() {
        enum Error: ErrorProtocol {
            case test
        }

        PMKUnhandledErrorHandler = { err in
            XCTFail()
        }

        let ex1 = expectation(withDescription: "")

        let p: Promise<Int> = firstly {
            throw Error.test
        }

        XCTAssertTrue(p.rejected)

        let anyp = AnyPromise(bound: p)

        p.error { err in
            ex1.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)

        print(anyp)
    }
}


extension NSError {
    @objc class public func pmk_setUnhandledErrorHandler(_ handler: (NSError) -> Void) {
        PMKUnhandledErrorHandler = { (error: ErrorProtocol) -> Void in
            handler(error as NSError)
        }
    }
}
