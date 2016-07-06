import Foundation
import PromiseKit
import XCTest

class AnyPromiseTestSuite_Swift: XCTestCase {
    func test1() {
        let ex = expectation(withDescription: "")

        // AnyPromise.then { return x }

        let input = after(interval: 0).then{ 1 }

        AnyPromise(bound: input).then { obj -> Int in
            XCTAssertEqual(obj as? Int, 1)
            return 2
        }.then { value -> Void in
            XCTAssertEqual(value, 2)
            ex.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func test2() {
        let ex = expectation(withDescription: "")

        // AnyPromise.then { return AnyPromise }

        let input = after(interval: 0).then{ 1 }

        AnyPromise(bound: input).then { obj -> AnyPromise in
            XCTAssertEqual(obj as? Int, 1)
            return AnyPromise(bound: after(interval: 0).then{ 2 })
        }.then { obj -> Void  in
            XCTAssertEqual(obj as? Int, 2)
            ex.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func test3() {
        let ex = expectation(withDescription: "")

        // AnyPromise.then { return Promise<Int> }

        let input = after(interval: 0).then{ 1 }

        AnyPromise(bound: input).then { obj -> Promise<Int> in
            XCTAssertEqual(obj as? Int, 1)
            return after(interval: 0).then{ 2 }
        }.then { value -> Void  in
            XCTAssertEqual(value, 2)
            ex.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
