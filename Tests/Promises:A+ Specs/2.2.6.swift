import PromiseKit
import XCTest


class Test226: XCTestCase {
    // 2.2.6: `then` may be called multiple times on the same promise.

    // 2.2.6.1: If/when `promise` is fulfilled, all respective `onFulfilled`
    // callbacks must execute in the order of their originating calls to `then`.

    func test2261_1() {
        // multiple boring fulfillment handlers

        suiteFulfilled(4){ (promise, exes, sentinel) -> () in
            var x = 0
            promise.then{ _->() in
                XCTAssertEqual(++x, 1)
                exes[0].fulfill()
            }
            promise.then{ _->() in
                XCTAssertEqual(++x, 2)
                exes[1].fulfill()
            }
            promise.then{ _->() in
                XCTAssertEqual(++x, 3)
                exes[2].fulfill()
            }
            promise.then{ (value:Int)->() in
                XCTAssertEqual(value, sentinel)
                XCTAssertEqual(x, 3)
                exes[3].fulfill()
            }
        }
    }

    func test2261_2() {
        // multiple fulfillment handlers, one of which throws

        suiteFulfilled(1) { (promise, ee, sentinel) in
            var x = 0
            promise.then{ _->() in
                XCTAssertEqual(++x, 1)
                return
            }
            promise.then{ _->() in
                XCTAssertEqual(++x, 2)
                return
            }
            promise.then{ _-> Promise<Int> in
                XCTAssertEqual(++x, 3)
                return Promise(dammy)
            }
            promise.then{ (value:Int)->() in
                XCTAssertEqual(value, sentinel)
                XCTAssertEqual(x, 3)
                ee[0].fulfill()
            }
        }
    }

    func test2261_3() {
        // results in multiple branching chains with their own fulfillment values

        suiteFulfilled(3) { (promise, exes, memo) in
            let sentinel1 = 671
            let sentinel2 = 672
            let sentinel3 = 673

            promise.then { _->Int in
                return sentinel1
            }.then { value->() in
                XCTAssertEqual(sentinel1, value)
                exes[0].fulfill()
            }

            promise.then{ _ -> Int in
                throw NSError(domain:PMKErrorDomain, code:sentinel2, userInfo:nil)
            }.report { err in
                XCTAssertEqual((err as NSError).code, sentinel2)
                exes[1].fulfill()
            }

            promise.then{ _->Int in
                return sentinel3
            }.then { value->() in
                XCTAssertEqual(value, sentinel3)
                exes[2].fulfill()
            }
        }
    }

    func test2261_4() {
        // `onFulfilled` handlers are called in the original order
        suiteFulfilled(3) { (promise, exes, memo) in
            var x = 0

            promise.then{ _->() in
                XCTAssertEqual(x++, 0)
                exes[0].fulfill()
            }
            promise.then{ _->() in
                XCTAssertEqual(x++, 1)
                exes[1].fulfill()
            }
            promise.then{ _->() in
                XCTAssertEqual(x++, 2)
                exes[2].fulfill()
            }
        }
    }

    func test2261_5() {
        // even when one handler is added inside another handler
        suiteFulfilled(3) { (promise, exes, memo) in
            var x = 0
            promise.then{ _->() in
                XCTAssertEqual(x++, 0)
                exes[0].fulfill()
                promise.then{ _->() in
                    XCTAssertEqual(x++, 2)
                    exes[1].fulfill()
                }
            }
            promise.then{ _->() in
                XCTAssertEqual(x++, 1)
                exes[2].fulfill()
            }
        }
    }

    // 2.2.6.2: If/when `promise` is rejected, all respective `onRejected` callbacks must execute in the order of their originating calls to `then`

    func test2262_1() {
        // multiple boring rejection handlers

        suiteRejected(4){ (promise, exes, sentinel) -> () in
            var x = 0
            promise.report{ _->() in
                XCTAssertEqual(++x, 1)
                exes[0].fulfill()
            }
            promise.report{ _->() in
                XCTAssertEqual(++x, 2)
                exes[1].fulfill()
            }
            promise.report{ _->() in
                XCTAssertEqual(++x, 3)
                exes[2].fulfill()
            }
            promise.report{ err in
                XCTAssertEqual(err, sentinel)
                XCTAssertEqual(x, 3)
                exes[3].fulfill()
            }
        }
    }

    func test2262_2() {
        // multiple rejection handlers, one of which throws

        suiteRejected(1) { (promise, ee, sentinel) in
            let blah = NSError(domain:PMKErrorDomain, code:923764, userInfo:nil)
            var x = 0
            promise.report{ err->() in
                XCTAssertEqual(err, sentinel)
                XCTAssertEqual(++x, 1)
                return
            }
            promise.report{ err->() in
                XCTAssertEqual(err, sentinel)
                XCTAssertEqual(++x, 2)
                return
            }
            promise.recover{ err->Promise<Int> in
                XCTAssertEqual(err, sentinel)
                XCTAssertEqual(++x, 3)
                return Promise(blah)
            }
            promise.report{ err->() in
                XCTAssertEqual(err, sentinel)
                XCTAssertEqual(x, 3)
                ee[0].fulfill()
            }
        }

    }

    func test2262_3() {
        // results in multiple branching chains with their own fulfillment values

        suiteRejected(3) { (promise, exes, memo) in
            let sentinel1 = 671
            let sentinel2 = 672
            let sentinel3 = 673

            promise.recover { _ -> Promise<Int> in
                return Promise(sentinel1)
            }.then { (value: Int) -> Void in
                XCTAssertEqual(sentinel1, value)
                exes[0].fulfill()
            }

            promise.recover{ _ -> Int in
                throw NSError(domain: PMKErrorDomain, code: sentinel2, userInfo: nil)
            }.report { err in
                XCTAssertEqual((err as NSError).code, sentinel2)
                exes[1].fulfill()
            }

            promise.recover{ _ -> Promise<Int> in
                return Promise(sentinel3)
            }.then { value->() in
                XCTAssertEqual(value, sentinel3)
                exes[2].fulfill()
            }
        }
    }

    func test2262_4() {
        // `onRejected` handlers are called in the original order

        suiteRejected(3) { (promise, exes, memo) in
            var x = 0

            promise.report{ _->() in
                XCTAssertEqual(x++, 0)
                exes[0].fulfill()
            }
            promise.report{ _->() in
                XCTAssertEqual(x++, 1)
                exes[1].fulfill()
            }
            promise.report{ _->() in
                XCTAssertEqual(x++, 2)
                exes[2].fulfill()
            }
        }
    }

    func test2262_5() {
        // even when one handler is added inside another handler
        suiteRejected(3) { (promise, exes, memo) in
            var x = 0
            promise.report{ _->() in
                XCTAssertEqual(x++, 0)
                exes[0].fulfill()
                promise.report{ _->() in
                    XCTAssertEqual(x++, 2)
                    exes[1].fulfill()
                }
            }
            promise.report{ _->() in
                XCTAssertEqual(x++, 1)
                exes[2].fulfill()
            }
        }
    }
}
