import Foundation
import PromiseKit
import XCTest

class Test_NSObject_Swift: XCTestCase {
    func testKVO() {
        let ex = expectation(description: "")

        let foo = Foo()
        foo.observe(keyPath: "bar").then { (newValue: String) -> Void in
            XCTAssertEqual(newValue, "moo")
            ex.fulfill()
        }.catch { _ in
            XCTFail()
        }
        foo.bar = "moo"

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAfterlife() {
        let ex = expectation(description: "")
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

            after(interval: 0.2).then {
                killme = nil
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMultiObserveAfterlife() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
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

            after(interval: 0.2).then {
                killme = nil
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}

private class Foo: NSObject {
    dynamic var bar: String = "bar"
}
