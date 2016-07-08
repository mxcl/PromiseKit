import PromiseKit
import XCTest

class RegressionTests: XCTestCase {
    func testReturningPreviousPromiseWorks() {

        // regression test because we were doing this wrong
        // in our A+ tests implementation for spec: 2.3.1

        do {
            let promise1 = Promise.fulfilled()
            let promise2 = promise1.then(on: zalgo) { promise1 }
            promise2.catch(on: zalgo) { _ in XCTFail() }
        }
        do {
            enum Error: ErrorProtocol { case dummy }

            let promise1 = Promise<Void>.resolved(error: Error.dummy)
            let promise2 = promise1.recover(on: zalgo) { _ in promise1 }
            promise2.catch(on: zalgo) { err in
                if case PromiseKit.Error.returnedSelf = err {
                    XCTFail()
                }
            }
        }
    }
}

private enum Error: ErrorProtocol {
    case Dummy
}
