import PromiseKit
import XCTest

// - Describe: 2.2.7: `then` must return a promise: `promise2 = promise1.then(onFulfilled, onRejected)
// - Specify: is a promise
// - NOOP: it is impossible for Promise<T> to *not* return a promise

// - Describe: 2.2.7.1: If either `onFulfilled` or `onRejected`
//   returns a value `x`, run the Promise Resolution Procedure
//   `[[Resolve]](promise2, x)
// - Specify: see separate 3.3 tests

class Test2272: XCTestCase {

    // describe: 2.2.7.2: If either `onFulfilled` or `onRejected`
    // throws an exception `e`, `promise2` must be rejected with `e`
    // as the reason.

    func test1() {
        testFulfilled { promise1, expectations, _ in
            let promise2 = promise1.then { _ in throw Error.Dummy }

            promise2.error {
                XCTAssertEqual(Error.Dummy, $0)
                expectations[0].fulfill()
            }
        }
    }

    func test2() {
        testRejected { promise1, expectations, _ in
            let promise2 = promise1.recover { _ -> Int in throw Error.Dummy }

            promise2.error {
                XCTAssertEqual(Error.Dummy, $0)
                expectations[0].fulfill()
            }
        }
    }
}

// - Describe: 2.2.7.3: If `onFulfilled` is not a function and
//   `promise1` is fulfilled, `promise2` must be fulfilled with the
//   same value.
// - NOOP: we cannot pass anything but a function in Swift

// - Describe: 2.2.7.4: If `onRejected` is not a function and
//   `promise1` is rejected, `promise2` must be rejected with the
//   same reason.
// - NOOP: we cannot pass anything but a function in Swift
