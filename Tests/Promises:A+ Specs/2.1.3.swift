import PromiseKit
import XCTest


class Test2131: XCTestCase {
    // "When rejected, a promise: must not transition to any other state."

    func test2131_1() {
        suiteRejected(1) { (promise, exes, _)->() in
            var onRejectedCalled = false
            promise.then { _->() in
                onRejectedCalled = true
                exes[0].fulfill()
            }
            promise.catch { e->() in
                XCTAssertFalse(onRejectedCalled)
            }
            later {
                exes[0].fulfill()
            }
        }
    }

    func test2131_2() {
        var onRejectedCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.deferred()
        promise.then{ a -> Void in
            XCTAssertFalse(onRejectedCalled)
        }
        promise.catch{ e -> Void in
            onRejectedCalled = true
        }
        fulfiller(dummy)
        rejecter(dammy)
        spin()
    }

    func test2131_3() {
        var onRejectedCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.deferred()

        promise.then{ a->() in
            XCTAssertFalse(onRejectedCalled)
        }
        promise.catch{ e->() in
            onRejectedCalled = true;
        }

        later {
            fulfiller(dummy)
            rejecter(dammy)
        }
        spin()
    }

    func test2131_4() {
        var onRejectedCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.deferred()

        promise.then{ a in
            XCTAssertFalse(onRejectedCalled)
        }
        promise.catch{ e->() in
            onRejectedCalled = true
        }

        fulfiller(dummy)
        later {
            rejecter(dammy)
        }
        spin()
    }
}
