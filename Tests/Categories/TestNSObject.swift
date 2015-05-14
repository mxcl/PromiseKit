import Foundation
import PromiseKit
import XCTest

private class Foo: NSObject {
    dynamic var bar: String = "bar"
}

class TestNSObject: XCTestCase {
    func testKVO() {
        let ex = expectationWithDescription("")

        let foo = Foo()
        foo.observe("bar").then { (newValue: String) -> Void in
            XCTAssertEqual(newValue, "moo")
            ex.fulfill()
        }.catch { err in
            XCTFail()
        }
        foo.bar = "moo"

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
