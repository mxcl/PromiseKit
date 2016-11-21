import PromiseKit
import XCTest

class PromiseTupleTests: XCTestCase {


    enum TestError: Error {
        case sthWrong
    }

    func testDoublePromisesTuple() {
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

    func testTriplePromisesTuple() {
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

    func testQuadruplePromisesTuple() {
        let ex = expectation(description: "promise tuple values returned")

        _ = firstly {
            Promise(value: ())
        }.then { () -> (Promise<Bool>, Promise<Int>, Promise<String>, Promise<(Int, Int)>) in
            let boolean = after(interval: 0.1).then { true }
            let integer = Promise(value: 1)
            let string = Promise(value: "success")
            let integerTuple = after(interval: 0.1).then { (2, 3) }
            return (boolean, integer, string, integerTuple)
        }.then { (boolean, integer, string, integerTuple) -> Void in
            XCTAssertEqual(true, boolean)
            XCTAssertEqual(1, integer)
            XCTAssertEqual("success", string)
            XCTAssertEqual(2, integerTuple.0)
            XCTAssertEqual(3, integerTuple.1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQuintuplePromisesTuple() {
        let ex = expectation(description: "promise tuple values returned")

        _ = firstly {
            Promise(value: ())
        }.then { () -> (Promise<Bool>, Promise<Int>, Promise<String>, Promise<(Int, Int)>, Promise<Double>) in
            let boolean = after(interval: 0.1).then { true }
            let integer = Promise(value: 1)
            let string = Promise(value: "success")
            let integerTuple = after(interval: 0.1).then { (2, 3) }
            let double = Promise(value: 0.1)
            return (boolean, integer, string, integerTuple, double)
        }.then { (boolean, integer, string, integerTuple, double) -> Void in
            XCTAssertEqual(true, boolean)
            XCTAssertEqual(1, integer)
            XCTAssertEqual("success", string)
            XCTAssertEqual(2, integerTuple.0)
            XCTAssertEqual(3, integerTuple.1)
            XCTAssertEqual(0.1, double)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }


    func testNtuplePromisesFail(generator: (Promise<Void>, Promise<Any>, Promise<Any>) -> Promise<Void>) {
        let ex = expectation(description: "")

        generator(after(interval: 0.1), Promise<Any>(value: 1), Promise<Any>(error: TestError.sthWrong)).then {
            XCTFail("Then called instead of `catch`")
        }.catch { e in
            if case TestError.sthWrong = e {
                ex.fulfill()
            } else {
                XCTFail("Wrong error received")
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDoublePromisesTupleFail() {
        testNtuplePromisesFail { after, success, err in
            after.then { (err, success) }
                 .then { (_: Any, _: Any) in () } // hint to compiler, that tuple version of `then` shall be used
        }
    }

    func testTriplePromisesTupleFail() {
        testNtuplePromisesFail { after, success, err in
            after.then { (success, err, success) }
                 .then { (_: Any, _: Any, _: Any) in () }
        }
    }

    func testQuadruplePromisesTupleFail() {
        testNtuplePromisesFail { after, success, err in
            after.then { (err, err, err, success) }
                 .then { (_: Any, _: Any, _: Any, _: Any) in () }
        }
    }

    func testQuintuplePromisesTupleFail() {
        testNtuplePromisesFail { after, success, err in
            after.then { (success, success, err, err, success) }
                 .then { (_: Any, _: Any, _: Any, _: Any, _: Any) in () }
        }
    }
}
