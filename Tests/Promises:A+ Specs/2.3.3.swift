import PromiseKit
import XCTest

class Test233: XCTestCase {

//    func testPromiseResolution(xFactory: ()->Promise<Int>, test: (Promise<Int>, XCTestExpectation)->Void) {
//        // via return from a fulfilled promise
//        let e1 = expectationWithDescription("")
//        var p1 = Promise(dummy).then { _->Promise<Int> in
//            return xFactory()
//        }
//        test(p1, e1)
//
//        // via return from a rejected promise
//        let e2 = expectationWithDescription("")
//        var p2 = Promise(error:dammy).report { _->Promise<Int> in
//            return xFactory()
//        }
//        test(p2, e2)
//    }
//
//    // 2.3.3: Otherwise, if `x` is an object or function,
//    // 2.3.3.1: Let `then` be `x.then`
//
//    func test23311() {
//        // `x` is an object with null prototype
//
//        var numberOfTimesThenWasRetrieved = null;
//
//        beforeEach(function () {
//            numberOfTimesThenWasRetrieved = 0;
//        });
//
//        func xFactory() {
//            return Object.create(null, {
//                then: {
//                    get: function () {
//                        ++numberOfTimesThenWasRetrieved;
//                        return function thenMethodForX(onFulfilled) {
//                            onFulfilled();
//                        };
//                    }
//                }
//            });
//        }
//
//        testPromiseResolution(xFactory) { (promise, ex) in
//            promise.then {
//                XCTAssertEqual(numberOfTimesThenWasRetrieved, 1)
//                ex.fulfill()
//            }
//        }
//    }
}
