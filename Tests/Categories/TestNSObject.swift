import Foundation
import PromiseKit
import XCTest

class Test_NSObject_Swift: XCTestCase {
    func testKVO() {
        let ex = expectationWithDescription("")

        let foo = Foo()
        foo.observe("bar").then { (newValue: String) -> Void in
            XCTAssertEqual(newValue, "moo")
            ex.fulfill()
        }.error { err in
            XCTFail()
        }
        foo.bar = "moo"

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testAfterlife() {
        let ex = expectationWithDescription("")
        var killme: NSObject!

        autoreleasepool {

            func innerScope() {
                killme = NSObject()
                after(life: killme).then { _ -> Void in
                    //…
                    ex.fulfill()
                }
            }

            innerScope()

            after(0.2).then {
                killme = nil
            }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testMultiObserveAfterlife() {
        let ex1 = expectationWithDescription("")
        let ex2 = expectationWithDescription("")
        var killme: NSObject!

        autoreleasepool {

            func innerScope() {
                killme = NSObject()
                after(life: killme).then { _ -> Void in
                    ex1.fulfill()
                }
                after(life: killme).then { _ -> Void in
                    ex2.fulfill()
                }
            }

            innerScope()

            after(0.2).then {
                killme = nil
            }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}

private class Foo: NSObject {
    dynamic var bar: String = "bar"
}
