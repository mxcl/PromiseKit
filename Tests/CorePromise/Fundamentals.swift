import PromiseKit
import XCTest

private enum E: Error { case dummy }

/**
 A+ tests most of the fundamentals, but these are unique to
 our platform, language and our special features.
 */
class Fundamentals: XCTestCase {

    func test1() {

        // Once `fulfilled`, `value` should be set *immediately*
        // even though the handlers are called delayed

        let (promise, seal) = Promise<Int>.pending()
        seal.fulfill(5)

        XCTAssertEqual(promise.value, 5)
    }

    func test2a() {
        wait { ex in
            // then is called on main thread
            Promise().then {
                XCTAssert(Thread.isMainThread)
                ex.fulfill()
            }
        }
    }

    func test2b() {
        wait { ex in
            // then is called on main thread
            Promise().ensure {
                XCTAssert(Thread.isMainThread)
                ex.fulfill()
            }
        }
    }

    func test2d() {
        wait { ex in
            // recover is called on main thread
            Promise(error: E.dummy).recover { _ in
                XCTAssert(Thread.isMainThread)
                ex.fulfill()
            }
        }
    }

    func test2c() {
        wait { ex in
            // catch is called on main thread
            Promise<Void>(error: E.dummy).catch { _ in
                XCTAssert(Thread.isMainThread)
                ex.fulfill()
            }
        }
    }

    func test3() {
        // verifies that subsequent thens all execute in the same ExecutionContext
        wait { ex in
            var foo = false

            let p = Promise()
            p.then {
                XCTAssertFalse(foo)
                DispatchQueue.main.async { foo = true }
                XCTAssertFalse(foo)
            }.then {
                XCTAssertFalse(foo)
            }.then {
                XCTAssertFalse(foo)

                p.then {
                    XCTAssertTrue(foo)
                    ex.fulfill()
                }
            }
        }
    }
}
