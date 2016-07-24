import PromiseKit
import XCTest

class Test232: XCTestCase {
    func test() {
        describe("2.3.2: If `x` is a promise, adopt its state") {
            describe("2.3.2.1: If `x` is pending, `promise` must remain pending until `x` is fulfilled or rejected.") {

                func xFactory() -> Promise<UInt32> {
                    return Promise.pending().promise
                }

                testPromiseResolution(factory: xFactory) { promise, expectation in
                    var wasFulfilled = false;
                    var wasRejected = false;

                    promise.test(onFulfilled: { wasFulfilled = true }, onRejected: { wasRejected = true })

                    after(ticks: 4) {
                        XCTAssertFalse(wasFulfilled)
                        XCTAssertFalse(wasRejected)
                        expectation.fulfill()
                    }
                }
            }

            describe("2.3.2.2: If/when `x` is fulfilled, fulfill `promise` with the same value.") {
                describe("`x` is already-fulfilled") {
                    let sentinel = arc4random()

                    func xFactory() -> Promise<UInt32> {
                        return Promise(value: sentinel)
                    }

                    testPromiseResolution(factory: xFactory) { promise, expectation in
                        promise.then { value -> Void in
                            XCTAssertEqual(value, sentinel)
                            expectation.fulfill()
                        }
                    }
                }
                describe("`x` is eventually-fulfilled") {
                    let sentinel = arc4random()

                    func xFactory() -> Promise<UInt32> {
                        return Promise { fulfill, _ in
                            after(ticks: 2) {
                                fulfill(sentinel)
                            }
                        }
                    }

                    testPromiseResolution(factory: xFactory) { promise, expectation in
                        promise.then { value -> Void in
                            XCTAssertEqual(value, sentinel)
                            expectation.fulfill()
                        }
                    }
                }
            }

            describe("2.3.2.3: If/when `x` is rejected, reject `promise` with the same reason.") {
                describe("`x` is already-rejected") {
                    let sentinel = arc4random()

                    func xFactory() -> Promise<UInt32> {
                        return Promise(error: Error.sentinel(sentinel))
                    }

                    testPromiseResolution(factory: xFactory) { promise, expectation in
                        promise.catch { err in
                            if case Error.sentinel(let value) = err, value == sentinel {
                                expectation.fulfill()
                            }
                        }
                    }
                }
                describe("`x` is eventually-rejected") {
                    let sentinel = arc4random()

                    func xFactory() -> Promise<UInt32> {
                        return Promise { _, reject in
                            after(ticks: 2) {
                                reject(Error.sentinel(sentinel))
                            }
                        }
                    }

                    testPromiseResolution(factory: xFactory) { promise, expectation in
                        promise.catch { err in
                            if case Error.sentinel(let value) = err, value == sentinel {
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
    }
}


/////////////////////////////////////////////////////////////////////////

extension Test232 {
    fileprivate func testPromiseResolution(factory: @escaping () -> Promise<UInt32>, line: UInt = #line, test: (Promise<UInt32>, XCTestExpectation) -> Void) {
        specify("via return from a fulfilled promise", file: #file, line: line) { d, expectation in
            let promise = Promise(value: arc4random()).then { _ in factory() }
            test(promise, expectation)
        }
        specify("via return from a rejected promise", file: #file, line: line) { d, expectation in
            let promise: Promise<UInt32> = Promise(error: Error.dummy).recover { _ in factory() }
            test(promise, expectation)
        }
    }
}
