import PromiseKit
import XCTest

class PromiseTupleTests: XCTestCase {

    /// test then tuples

    func testThenReturningDoublePromisesTuple() {
        let ex = expectation(description: "promise tuple values returned")
        getPromises { a, b, _, _, _, first in
            first.then { () -> (Promise<Bool>, Promise<Int>) in
                return (a, b)
            }.then { (bool, integer) -> Void in
                XCTAssertEqual(a.value, bool)
                XCTAssertEqual(b.value, integer)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testThenReturningTriplePromisesTuple() {
        let ex = expectation(description: "promise tuple values returned")

        getPromises() { a, b, c, _, _, first in
            first.then { () -> (Promise<Bool>, Promise<Int>, Promise<String>) in
                return (a, b, c)
            }.then { aVal, bVal, cVal -> Void in
                XCTAssertEqual(a.value, aVal)
                XCTAssertEqual(b.value, bVal)
                XCTAssertEqual(c.value, cVal)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testThenReturningQuadruplePromisesTuple() {
        let ex = expectation(description: "promise tuple values returned")

        getPromises() { a, b, c, d, _, first in
            first.then { () -> (Promise<Bool>, Promise<Int>, Promise<String>, Promise<(Int, Int)>) in
                return (a, b, c, d)
            }.then { (boolean, integer, string, integerTuple) -> Void in
                XCTAssertEqual(a.value, boolean)
                XCTAssertEqual(b.value, integer)
                XCTAssertEqual(c.value, string)
                XCTAssertEqual(d.value!.0, integerTuple.0)
                XCTAssertEqual(d.value!.1, integerTuple.1)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testThenReturningQuintuplePromisesTuple() {
        let ex = expectation(description: "promise tuple values returned")

        getPromises { a, b, c, d, e, first in
            first.then { () -> (Promise<Bool>, Promise<Int>, Promise<String>, Promise<(Int, Int)>, Promise<Double>) in
                return (a, b, c, d, e)
            }.then { (boolean, integer, string, integerTuple, double) -> Void in
                XCTAssertEqual(a.value, boolean)
                XCTAssertEqual(b.value, integer)
                XCTAssertEqual(c.value, string)
                XCTAssertEqual(d.value!.0, integerTuple.0)
                XCTAssertEqual(d.value!.1, integerTuple.1)
                XCTAssertEqual(e.value, double)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    // test then tuples fail

    func testThenNtuplePromisesFail(generator: (Promise<Void>, Promise<Any>, Promise<Any>) -> Promise<Void>) {
        let ex = expectation(description: "")

        generator(after(interval: .milliseconds(100)), Promise<Any>(value: 1), Promise<Any>(error: TestError.sthWrong)).then {
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

    func testThenDoublePromisesTupleFail() {
        testThenNtuplePromisesFail { after, success, err in
            after.then { (err, success) }
                 .then { (_: Any, _: Any) in () } // hint to compiler, that tuple version of `then` shall be used
        }
    }

    func testThenTriplePromisesTupleFail() {
        testThenNtuplePromisesFail { after, success, err in
            after.then { (success, err, success) }
                 .then { (_: Any, _: Any, _: Any) in () }
        }
    }

    func testThenQuadruplePromisesTupleFail() {
        testThenNtuplePromisesFail { after, success, err in
            after.then { (err, err, err, success) }
                 .then { (_: Any, _: Any, _: Any, _: Any) in () }
        }
    }

    func testThenQuintuplePromisesTupleFail() {
        testThenNtuplePromisesFail { after, success, err in
            after.then { (success, success, err, err, success) }
                 .then { (_: Any, _: Any, _: Any, _: Any, _: Any) in () }
        }
    }

    // test firstly tuples

    func testFirstlyReturningPromise() {
        let ex = expectation(description: "promise tuple values returned")

        firstly { () -> Promise<Bool> in
            return Promise(value: true)
        }.then { val -> Void in
            XCTAssertEqual(val, true)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFirstlyReturningDoublePromisesTuple() {

        let ex = expectation(description: "promise tuple values returned")

        getPromises { a, b, _, _, _, _ in
            firstly { () -> (Promise<Bool>, Promise<Int>) in
                return (a, b)
            }.then { (aVal: Bool, bVal: Int) -> Void in
                XCTAssertEqual(aVal, a.value)
                XCTAssertEqual(bVal, b.value)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFirstlyReturningTriplePromisesTuple() {

        let ex = expectation(description: "promise tuple values returned")

        getPromises { a, b, c, _, _, _ in
            firstly { () -> (Promise<Bool>, Promise<Int>, Promise<String>) in
                return (a, b, c)
            }.then { (aVal: Bool, bVal: Int, cVal: String) -> Void in
                XCTAssertEqual(aVal, a.value)
                XCTAssertEqual(bVal, b.value)
                XCTAssertEqual(cVal, c.value)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFirstlyReturningQuadruplePromisesTuple() {

        let ex = expectation(description: "promise tuple values returned")

        getPromises { a, b, c, d, _, _ in
            firstly { () -> (Promise<Bool>, Promise<Int>, Promise<String>, Promise<(Int, Int)>) in
                return (a, b, c, d)
            }.then { (aVal: Bool, bVal: Int, cVal: String, dVal: (Int, Int)) -> Void in
                XCTAssertEqual(aVal, a.value)
                XCTAssertEqual(bVal, b.value)
                XCTAssertEqual(cVal, c.value)
                XCTAssertEqual(dVal.0, d.value!.0)
                XCTAssertEqual(dVal.1, d.value!.1)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }


    func testFirstlyReturningQuintuplePromisesTuple() {

        let ex = expectation(description: "promise tuple values returned")

        getPromises { a, b, c, d, e, _ in
            firstly { () -> (Promise<Bool>, Promise<Int>, Promise<String>, Promise<(Int, Int)>, Promise<Double>) in
                return (a, b, c, d, e)
            }.then { (aVal: Bool, bVal: Int, cVal: String, dVal: (Int, Int), eVal: Double) -> Void in
                XCTAssertEqual(aVal, a.value)
                XCTAssertEqual(bVal, b.value)
                XCTAssertEqual(cVal, c.value)
                XCTAssertEqual(dVal.0, d.value!.0)
                XCTAssertEqual(dVal.1, d.value!.1)
                XCTAssertEqual(eVal, e.value)
                ex.fulfill()
            }

        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    // test firstly fail
    func testFirstlyNtuplePromisesFail(generator: (Promise<Void>, Promise<Any>, Promise<Any>) -> Promise<Void>) {
        let ex = expectation(description: "")

        generator(after(interval: .milliseconds(100)), Promise<Any>(value: 1), Promise<Any>(error: TestError.sthWrong)).then {
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

    func testFirstlyDoublePromisesTupleFail() {
        testFirstlyNtuplePromisesFail { after, success, err in
            firstly { (err, success) }.then { (_: Any, _: Any) in () }
        }
    }

    func testFirstlyTriplePromisesTupleFail() {
        testFirstlyNtuplePromisesFail { after, success, err in
            firstly { (success, err, success) }.then { (_: Any, _: Any, _: Any) in () }
        }
    }

    func testFirstlyQuadruplePromisesTupleFail() {
        testFirstlyNtuplePromisesFail { after, success, err in
            firstly { (err, err, err, success) }.then { (_: Any, _: Any, _: Any, _: Any) in () }
        }
    }

    func testFirstlyQuintuplePromisesTupleFail() {
        testFirstlyNtuplePromisesFail { after, success, err in
            firstly { (success, success, err, err, success) }.then { (_: Any, _: Any, _: Any, _: Any, _: Any) in () }
        }
    }
}

fileprivate enum TestError: Error {
    case sthWrong
}

fileprivate func getPromises(callback: ((Promise<Bool>, Promise<Int>, Promise<String>, Promise<(Int, Int)>, Promise<Double>, Promise<Void>)) -> Void) {
    let boolean = after(interval: .milliseconds(100)).then { true }
    let integer = Promise(value: 1)
    let string = Promise(value: "success")
    let integerTuple = after(interval: .milliseconds(100)).then { (2, 3) }
    let double = Promise(value: 0.1)
    let empty = Promise(value: ())
    callback((boolean, integer, string, integerTuple, double, empty))
}
