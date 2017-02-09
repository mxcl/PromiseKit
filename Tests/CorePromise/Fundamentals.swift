import PromiseKit
import XCTest

class Fundamentals: XCTest {

    func testValueSetImmediately() {

        // Once `fulfilled`, `value` should be set *immediately*
        // even though the handlers are called delayed

        let (promise, seal) = Promise<Int>.pending()
        seal.fulfill(5)

        XCTAssertEqual(promise.value, 5)
    }
}
