import PromiseKit
import XCTest

private enum E: Error { case dummy }

class AmbiguityTests: XCTestCase {

    func test1() {
        // verify that Guarantee `then` doesn’t become `Guarantee<Promise<Int>>`
        wait { ex in
            func foo(_: Error) { ex.fulfill() }
            let g = Guarantee().then{ Promise<Int>(error: E.dummy) }.catch{ _ in ex.fulfill() }
        }
    }
}
