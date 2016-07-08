import PromiseKit
import XCTest

// 2.2.6: `then` may be called multiple times on the same promise.

class Test2261: XCTestCase {

    // 2.2.6.1: If/when `promise` is fulfilled, all respective `onFulfilled`
    // callbacks must execute in the order of their originating calls to `then`.

    func test1() {

        // multiple boring fulfillment handlers

        testFulfilled(4) { (promise, ee, sentinel) -> () in
            var x = 0
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                x += 1
                XCTAssertEqual(x, 1)
                ee[0].fulfill()
            }
            promise.error { _ in XCTFail() }
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                x += 1
                XCTAssertEqual(x, 2)
                ee[1].fulfill()
            }
            promise.error { _ in XCTFail() }
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                x += 1
                XCTAssertEqual(x, 3)
                ee[2].fulfill()
            }
            promise.error { _ in XCTFail() }
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                XCTAssertEqual(x, 3)
                ee[3].fulfill()
            }
        }
    }

    func test2() {

        // multiple fulfillment handlers, one of which throws

        testFulfilled(4) { (promise, ee, sentinel) in
            var x = 0
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                x += 1
                XCTAssertEqual(x, 1)
                ee[0].fulfill()
            }
            promise.error { _ in XCTFail() }
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                x += 1
                XCTAssertEqual(x, 2)
                ee[1].fulfill()
            }
            promise.error { _ in XCTFail() }
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                x += 1
				XCTAssertEqual(x, 3)
                ee[2].fulfill()
                throw Error.Dummy
            }
            promise.error { value in XCTFail() }
            promise.then { value -> Void in
                XCTAssertEqual(value, sentinel)
                XCTAssertEqual(x, 3)
                ee[3].fulfill()
            }
        }
    }

    func test3() {

        // results in multiple branching chains with their own fulfillment values

        testFulfilled(3) { promise, ee, memo in
            let sentinel1 = 671
            let sentinel2 = 672
            let sentinel3 = 673

            promise.then { _ -> Int in
                return sentinel1
            }.then { value -> Void in
                XCTAssertEqual(sentinel1, value)
                ee[0].fulfill()
            }

            promise.then { _ -> Int in
                throw NSError(domain: PMKErrorDomain, code: sentinel2, userInfo: nil)
            }.error { err in
                XCTAssertEqual((err as NSError).code, sentinel2)
                ee[1].fulfill()
            }

            promise.then{ _ -> Int in
                return sentinel3
            }.then { value -> Void in
                XCTAssertEqual(value, sentinel3)
                ee[2].fulfill()
            }
        }
    }

    func test4() {

        // `onFulfilled` handlers are called in the original order

        testFulfilled(3) { promise, ee, memo in
            var x = 0

            promise.then { _ -> Void in
                XCTAssertEqual(x, 0)
                x += 1
                ee[0].fulfill()
            }
            promise.then { _ -> Void in
                XCTAssertEqual(x, 1)
                x += 1
                ee[1].fulfill()
            }
            promise.then { _ -> Void in
                XCTAssertEqual(x, 2)
                x += 1
                ee[2].fulfill()
            }
        }
    }

    func test5() {

        // even when one handler is added inside another handler

        testFulfilled(3) { promise, exes, memo in
            var x = 0
            promise.then { _ -> Void in
                XCTAssertEqual(x, 0)
                x += 1
                exes[0].fulfill()
                promise.then{ _ -> Void in
                    XCTAssertEqual(x, 2)
                    x += 1
                    exes[1].fulfill()
                }
            }
            promise.then { _ -> Void in
                XCTAssertEqual(x, 1)
                x += 1
                exes[2].fulfill()
            }
        }
    }
}


class Test2262: XCTestCase {

    // 2.2.6.2: If/when `promise` is rejected, all respective `onRejected` callbacks must execute in the order of their originating calls to `then`

    func test1() {

        // multiple boring rejection handlers

        testRejected(4) { promise, exes, sentinel in
            var x = 0
            promise.error { err in
                XCTAssertEqual(err, sentinel)
                x += 1
                XCTAssertEqual(x, 1)
                exes[0].fulfill()
            }
            promise.then { _ in XCTFail() }
            promise.error { err in
                XCTAssertEqual(err, sentinel)
                x += 1
                XCTAssertEqual(x, 2)
                exes[1].fulfill()
            }
            promise.then { _ in XCTFail() }
            promise.error { err in
                XCTAssertEqual(err, sentinel)
                x += 1
                XCTAssertEqual(x, 3)
                exes[2].fulfill()
            }
            promise.then { _ in XCTFail() }
            promise.error { err in
                XCTAssertEqual(err, sentinel)
                XCTAssertEqual(x, 3)
                exes[3].fulfill()
            }
        }
    }

    func test2() {

        // multiple rejection handlers, one of which throws

        testRejected(4) { promise, ee, sentinel in
            let blah = NSError(domain: PMKErrorDomain, code: 923764, userInfo: nil)
            var x = 0
            promise.error{ err in
                XCTAssertEqual(err, sentinel)
                x += 1
                XCTAssertEqual(x, 1)
                ee[0].fulfill()
            }
            promise.then { _ in XCTFail() }
            promise.error{ err in
                XCTAssertEqual(err, sentinel)
                x += 1
                XCTAssertEqual(x, 2)
                ee[1].fulfill()
            }
            promise.then { _ in XCTFail() }
            promise.recover { err -> Int in
                XCTAssertEqual(err, sentinel)
                x += 1
                XCTAssertEqual(x, 3)
                ee[2].fulfill()
                throw blah
            }
            promise.then { _ in XCTFail() }
            promise.error{ err in
                XCTAssertEqual(err, sentinel)
                XCTAssertEqual(x, 3)
                ee[3].fulfill()
            }
        }

    }

    func test3() {

        // results in multiple branching chains with their own fulfillment values

        testRejected(3) { promise, exes, memo in
            let sentinel1 = 671
            let sentinel2 = 672
            let sentinel3 = 673

            promise.recover { _ -> Int in
                return sentinel1
            }.then { value -> Void in
                XCTAssertEqual(sentinel1, value)
                exes[0].fulfill()
            }

            promise.recover { _ -> Int in
                throw NSError(domain: PMKErrorDomain, code: sentinel2, userInfo: nil)
            }.error { err in
                XCTAssertEqual((err as NSError).code, sentinel2)
                exes[1].fulfill()
            }

            promise.recover { _ -> Int in
                return sentinel3
            }.then { value -> Void in
                XCTAssertEqual(value, sentinel3)
                exes[2].fulfill()
            }
        }
    }

    func test4() {
        // `onRejected` handlers are called in the original order

        testRejected(3) { promise, exes, memo in
            var x = 0

            promise.error { _ in
                XCTAssertEqual(x, 0)
                x += 1
                exes[0].fulfill()
            }
            promise.error{ _ in
                XCTAssertEqual(x, 1)
                x += 1
                exes[1].fulfill()
            }
            promise.error{ _ in
                XCTAssertEqual(x, 2)
                x += 1
                exes[2].fulfill()
            }
        }
    }

    func test5() {

        // even when one handler is added inside another handler

        testRejected(3) { promise, exes, memo in
            var x = 0

            promise.error { _ in
                XCTAssertEqual(x, 0)
                x += 1
                exes[0].fulfill()
                promise.error { _ in
                    XCTAssertEqual(x, 2)
                    x += 1
                    exes[1].fulfill()
                }
            }
            promise.error{ _ in
                XCTAssertEqual(x, 1)
                x += 1
                exes[2].fulfill()
            }
        }
    }
}
