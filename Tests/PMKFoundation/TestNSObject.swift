import PMKFoundation
import Foundation
import PromiseKit
import XCTest

#if !os(Linux)

class NSObjectTests: XCTestCase {
    func testKVO() {
        let ex = expectation(description: "")

        let foo = Foo()
        foo.observe(.promise, keyPath: "bar").done { newValue in
            XCTAssertEqual(newValue as? String, "moo")
            ex.fulfill()
        }.catch { _ in
            XCTFail()
        }
        foo.bar = "moo"

        waitForExpectations(timeout: 5)
    }

    func testAfterlife() {
        let ex = expectation(description: "")
        var killme: NSObject!

        autoreleasepool {

            func innerScope() {
                killme = NSObject()
                after(life: killme).done { _ in
                    //…
                    ex.fulfill()
                }
            }

            innerScope()

            after(.milliseconds(200)).done {
                killme = nil
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testMultiObserveAfterlife() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        var killme: NSObject!

        autoreleasepool {

            func innerScope() {
                killme = NSObject()
                after(life: killme).done { _ in
                    ex1.fulfill()
                }
                after(life: killme).done { _ in
                    ex2.fulfill()
                }
            }

            innerScope()

            after(.milliseconds(200)).done {
                killme = nil
            }
        }

        waitForExpectations(timeout: 5)
    }
}

private class Foo: NSObject {
    @objc dynamic var bar: String = "bar"
}

#endif
