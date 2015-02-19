import PromiseKit
import XCTest


class Test2121: XCTestCase {
    // "When fulfilled, a promise: must not transition to any other state."

    func test1() {
        suiteFulfilled(1) { (promise, ee, _)->() in
            var onFulfilledCalled = false
            promise.then { a in
                onFulfilledCalled = true
            }
            promise.catch { e->() in
                XCTAssertFalse(onFulfilledCalled)
                ee[0].fulfill()
            }
            later {
                ee[0].fulfill()
            }
        }
    }

    func test2() {
        var onFulfilledCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.defer()
        promise.then{ a -> Void in
            onFulfilledCalled = true
        }
        promise.catch{ e -> Void in
            XCTAssertFalse(onFulfilledCalled)
        }
        fulfiller(dummy)
        rejecter(dammy)
        spin()
    }

    func test3() {
        var onFulfilledCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.defer()

        promise.then{ a->() in
            onFulfilledCalled = true;
        }
        promise.catch{ e->() in
            XCTAssertFalse(onFulfilledCalled)
        }

        later {
            fulfiller(dummy)
            rejecter(dammy)
        }
        spin()
    }

    func test4() {
        var onFulfilledCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.defer()

        promise.then{ a in
            onFulfilledCalled = true
        }
        promise.catch{ e->() in
            XCTAssertFalse(onFulfilledCalled)
        }

        fulfiller(dummy)
        later {
            rejecter(dammy)
        }
        spin()
    }
}
