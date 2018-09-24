import PromiseKit
import XCTest

class Test226: XCTestCase {
    func test() {
        describe("2.2.6: `then` may be called multiple times on the same promise.") {
            describe("2.2.6.1: If/when `promise` is fulfilled, all respective `onFulfilled` callbacks must execute in the order of their originating calls to `then`.") {
                describe("multiple boring fulfillment handlers") {
                    testFulfilled(withExpectationCount: 4) { promise, exes, sentinel -> () in
                        var orderValidator = 0
                        promise.done {
                            XCTAssertEqual($0, sentinel)
                            XCTAssertEqual(++orderValidator, 1)
                            exes[0].fulfill()
                        }.silenceWarning()
                        promise.catch { _ in XCTFail() }
                        promise.done {
                            XCTAssertEqual($0, sentinel)
                            XCTAssertEqual(++orderValidator, 2)
                            exes[1].fulfill()
                        }.silenceWarning()
                        promise.catch { _ in XCTFail() }
                        promise.done {
                            XCTAssertEqual($0, sentinel)
                            XCTAssertEqual(++orderValidator, 3)
                            exes[2].fulfill()
                        }.silenceWarning()
                        promise.catch { _ in XCTFail() }
                        promise.done {
                            XCTAssertEqual($0, sentinel)
                            XCTAssertEqual(++orderValidator, 4)
                            exes[3].fulfill()
                        }.silenceWarning()
                    }
                }
                describe("multiple fulfillment handlers, one of which throws") {
                    testFulfilled(withExpectationCount: 4) { promise, exes, sentinel in
                        var orderValidator = 0
                        promise.done {
                            XCTAssertEqual($0, sentinel)
                            XCTAssertEqual(++orderValidator, 1)
                            exes[0].fulfill()
                        }.silenceWarning()
                        promise.catch { _ in XCTFail() }
                        promise.done {
                            XCTAssertEqual($0, sentinel)
                            XCTAssertEqual(++orderValidator, 2)
                            exes[1].fulfill()
                        }.silenceWarning()
                        promise.catch { _ in XCTFail() }
                        promise.done {
                            XCTAssertEqual($0, sentinel)
                            XCTAssertEqual(++orderValidator, 3)
                            exes[2].fulfill()
                            throw Error.dummy
                        }.silenceWarning()
                        promise.catch { value in XCTFail() }
                        promise.done {
                            XCTAssertEqual($0, sentinel)
                            XCTAssertEqual(++orderValidator, 4)
                            exes[3].fulfill()
                        }.silenceWarning()
                    }
                }
                describe("results in multiple branching chains with their own fulfillment values") {
                    testFulfilled(withExpectationCount: 3) { promise, exes, memo in
                        let sentinel1 = 671
                        let sentinel2: UInt32 = 672
                        let sentinel3 = 673

                        promise.map { _ in
                            return sentinel1
                        }.done { value in
                            XCTAssertEqual(sentinel1, value)
                            exes[0].fulfill()
                        }.silenceWarning()

                        promise.done { _ in
                            throw Error.sentinel(sentinel2)
                        }.catch { err in
                            switch err {
                            case Error.sentinel(let err) where err == sentinel2:
                                break
                            default:
                                XCTFail()
                            }
                            exes[1].fulfill()
                        }

                        promise.map { _ in
                            sentinel3
                        }.done {
                            XCTAssertEqual($0, sentinel3)
                            exes[2].fulfill()
                        }.silenceWarning()
                    }
                }
                describe("`onFulfilled` handlers are called in the original order") {
                    testFulfilled(withExpectationCount: 3) { promise, exes, memo in
                        var orderValidator = 0

                        promise.done { _ in
                            XCTAssertEqual(++orderValidator, 1)
                            exes[0].fulfill()
                        }.silenceWarning()
                        promise.done { _ in
                            XCTAssertEqual(++orderValidator, 2)
                            exes[1].fulfill()
                        }.silenceWarning()
                        promise.done { _ in
                            XCTAssertEqual(++orderValidator, 3)
                            exes[2].fulfill()
                        }.silenceWarning()
                    }
                }
                describe("even when one handler is added inside another handler") {
                    testFulfilled(withExpectationCount: 3) { promise, exes, memo in
                        var x = 0
                        promise.done { _ in
                            XCTAssertEqual(x, 0)
                            x += 1
                            exes[0].fulfill()
                            promise.done { _ in
                                XCTAssertEqual(x, 2)
                                x += 1
                                exes[1].fulfill()
                            }.silenceWarning()
                        }.silenceWarning()
                        promise.done { _ in
                            XCTAssertEqual(x, 1)
                            x += 1
                            exes[2].fulfill()
                        }.silenceWarning()
                    }
                }
            }
            describe("2.2.6.2: If/when `promise` is rejected, all respective `onRejected` callbacks must execute in the order of their originating calls to `then`.") {
                describe("multiple boring rejection handlers") {
                    testRejected(withExpectationCount: 4) { promise, exes, sentinel in
                        var ticket = 0

                        promise.catch { err in
                            guard case Error.sentinel(let x) = err, x == sentinel else { return XCTFail() }
                            XCTAssertEqual(++ticket, 1)
                            exes[0].fulfill()
                        }
                        promise.done { _ in XCTFail() }.silenceWarning()
                        promise.catch { err in
                            guard case Error.sentinel(let x) = err, x == sentinel else { return XCTFail() }
                            XCTAssertEqual(++ticket, 2)
                            exes[1].fulfill()
                        }
                        promise.done { _ in XCTFail() }.silenceWarning()
                        promise.catch { err in
                            guard case Error.sentinel(let x) = err, x == sentinel else { return XCTFail() }
                            XCTAssertEqual(++ticket, 3)
                            exes[2].fulfill()
                        }
                        promise.done { _ in XCTFail() }.silenceWarning()
                        promise.catch { err in
                            guard case Error.sentinel(let x) = err, x == sentinel else { return XCTFail() }
                            XCTAssertEqual(++ticket, 4)
                            exes[3].fulfill()
                        }
                    }
                }
                describe("multiple rejection handlers, one of which throws") {
                    testRejected(withExpectationCount: 4) { promise, exes, sentinel in
                        var orderValidator = 0

                        promise.catch { err in
                            guard case Error.sentinel(let x) = err, x == sentinel else { return XCTFail() }
                            XCTAssertEqual(++orderValidator, 1)
                            exes[0].fulfill()
                        }
                        promise.done { _ in XCTFail() }.silenceWarning()
                        promise.catch { err in
                            guard case Error.sentinel(let x) = err, x == sentinel else { return XCTFail() }
                            XCTAssertEqual(++orderValidator, 2)
                            exes[1].fulfill()
                        }
                        promise.done { _ in XCTFail() }.silenceWarning()
                        promise.recover { err -> Promise<UInt32> in
                            if case Error.sentinel(let x) = err {
                                XCTAssertEqual(x, sentinel)
                            } else {
                                XCTFail()
                            }
                            XCTAssertEqual(++orderValidator, 3)
                            exes[2].fulfill()
                            throw Error.dummy
                        }.silenceWarning()
                        promise.done { _ in XCTFail() }.silenceWarning()
                        promise.catch { err in
                            guard case Error.sentinel(let x) = err, x == sentinel else { return XCTFail() }
                            XCTAssertEqual(++orderValidator, 4)
                            exes[3].fulfill()
                        }
                    }
                }
                describe("results in multiple branching chains with their own fulfillment values") {
                    testRejected(withExpectationCount: 3) { promise, exes, memo in
                        let sentinel1 = arc4random()
                        let sentinel2 = arc4random()
                        let sentinel3 = arc4random()

                        promise.recover { _ in
                            return .value(sentinel1)
                        }.done { value in
                            XCTAssertEqual(sentinel1, value)
                            exes[0].fulfill()
                        }

                        promise.recover { _ -> Promise<UInt32> in
                            throw Error.sentinel(sentinel2)
                        }.catch { err in
                            if case Error.sentinel(let x) = err, x == sentinel2 {
                                exes[1].fulfill()
                            }
                        }
                        
                        promise.recover { _ in
                            .value(sentinel3)
                        }.done { value in
                            XCTAssertEqual(value, sentinel3)
                            exes[2].fulfill()
                        }
                    }
                }
                describe("`onRejected` handlers are called in the original order") {
                    testRejected(withExpectationCount: 3) { promise, exes, memo in
                        var x = 0

                        promise.catch { _ in
                            XCTAssertEqual(x, 0)
                            x += 1
                            exes[0].fulfill()
                        }
                        promise.catch { _ in
                            XCTAssertEqual(x, 1)
                            x += 1
                            exes[1].fulfill()
                        }
                        promise.catch { _ in
                            XCTAssertEqual(x, 2)
                            x += 1
                            exes[2].fulfill()
                        }
                    }
                }
                describe("even when one handler is added inside another handler") {
                    testRejected(withExpectationCount: 3) { promise, exes, memo in
                        var x = 0

                        promise.catch { _ in
                            XCTAssertEqual(x, 0)
                            x += 1
                            exes[0].fulfill()
                            promise.catch { _ in
                                XCTAssertEqual(x, 2)
                                x += 1
                                exes[1].fulfill()
                            }
                        }
                        promise.catch { _ in
                            XCTAssertEqual(x, 1)
                            x += 1
                            exes[2].fulfill()
                        }
                    }
                }
            }
        }
    }
}
