import PromiseKit
import XCTest

class PromiseTupleTests: XCTestCase {

    func testTupleWithThreeMixedTypePromises() {
        let ex = expectation(description: "promise tuple values returned")

        _ = firstly {
            Promise(value: ())
        }.then { () -> (Promise<Int>, Promise<Bool>, Promise<String>) in
            let integer = Promise(value: 1)
            let boolean = Promise(value: true)
            let string = Promise(value: "yes")
            return (integer, boolean, string)
        }.then { integer, boolean, string -> Void in
            XCTAssertEqual(1, integer)
            XCTAssertEqual(true, boolean)
            XCTAssertEqual("yes", string)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTupleWithTwoMixedTypePromises() {
        let ex = expectation(description: "promise tuple values returned")

        _ = firstly {
            Promise(value: ())
        }.then { () -> (Promise<Int>, Promise<String>) in
            let integer = after(interval: 0.1).then { 1 }
            let string = Promise(value: "success")
            return (integer, string)
        }.then { (integer, string) -> Void in
            XCTAssertEqual(1, integer)
            XCTAssertEqual("success", string)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
