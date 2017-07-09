import Foundation
import PromiseKit
import XCTest

class BridgingTests: XCTestCase {

    func testCanBridgeAnyObject() {
        let sentinel = NSURLRequest()
        let p = Promise(value: sentinel)
        let ap = AnyPromise(p)

        XCTAssertEqual(ap.value(forKey: "value") as? NSURLRequest, sentinel)
    }

    func testCanBridgeOptional() {
        let sentinel: NSURLRequest? = NSURLRequest()
        let p = Promise(value: sentinel)
        let ap = AnyPromise(p)

        XCTAssertEqual(ap.value(forKey: "value") as? NSURLRequest, sentinel!)
    }

    func testCanBridgeSwiftArray() {
        let sentinel = [NSString(), NSString(), NSString()]
        let p = Promise(value: sentinel)
        let ap = AnyPromise(p)

        XCTAssertEqual(ap.value(forKey: "value") as! [NSString], sentinel)
    }

    func testCanBridgeSwiftDictionary() {
        let sentinel = [NSString(): NSString()]
        let p = Promise(value: sentinel)
        let ap = AnyPromise(p)

        XCTAssertEqual(ap.value(forKey: "value") as! [NSString: NSString], sentinel)
    }

    func testCanBridgeInt() {
        let sentinel = 3
        let p = Promise(value: sentinel)
        let ap = AnyPromise(p)
        XCTAssertEqual(ap.value(forKey: "value") as? Int, sentinel)
    }

    func testCanBridgeString() {
        let sentinel = "a"
        let p = Promise(value: sentinel)
        let ap = AnyPromise(p)
        XCTAssertEqual(ap.value(forKey: "value") as? String, sentinel)
    }

    func testCanBridgeBool() {
        let sentinel = true
        let p = Promise(value: sentinel)
        let ap = AnyPromise(p)
        XCTAssertEqual(ap.value(forKey: "value") as? Bool, sentinel)
    }

    func testCanChainOffAnyPromiseFromObjC() {
        let ex = expectation(description: "")

        firstly {
            Promise(value: 1)
        }.then { _ -> AnyPromise in
            return PromiseBridgeHelper().value(forKey: "bridge2") as! AnyPromise
        }.then { value -> Void in
            XCTAssertEqual(123, value as? Int)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCanThenOffAnyPromise() {
        let ex = expectation(description: "")

        PMKDummyAnyPromise_YES().then { obj -> Void in
            if let value = obj as? NSNumber {
                XCTAssertEqual(value, NSNumber(value: true))
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testCanThenOffManifoldAnyPromise() {
        let ex = expectation(description: "")

        PMKDummyAnyPromise_Manifold().then { obj -> Void in
            if let value = obj as? NSNumber {
                XCTAssertEqual(value, NSNumber(value: true))
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testCanAlwaysOffAnyPromise() {
        let ex = expectation(description: "")

        PMKDummyAnyPromise_YES().then { obj -> Void in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCanCatchOffAnyPromise() {
        let ex = expectation(description: "")
        PMKDummyAnyPromise_Error().catch { err in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testAsPromise() {
        XCTAssertTrue(PMKDummyAnyPromise_Error().asPromise().isRejected)
        XCTAssertEqual(PMKDummyAnyPromise_YES().asPromise().value as? NSNumber, NSNumber(value: true))
    }

    func testFirstlyReturningAnyPromiseSuccess() {
        let ex = expectation(description: "")
        firstly {
            PMKDummyAnyPromise_Error()
        }.catch { error in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testFirstlyReturningAnyPromiseError() {
        let ex = expectation(description: "")
        firstly {
            PMKDummyAnyPromise_YES()
        }.then { _ in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test1() {
        let ex = expectation(description: "")

        // AnyPromise.then { return x }

        let input = after(seconds: 0).then{ 1 }

        AnyPromise(input).then { obj -> Int in
            XCTAssertEqual(obj as? Int, 1)
            return 2
        }.then { value -> Void in
            XCTAssertEqual(value, 2)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test2() {
        let ex = expectation(description: "")

        // AnyPromise.then { return AnyPromise }

        let input = after(seconds: 0).then{ 1 }

        AnyPromise(input).then { obj -> AnyPromise in
            XCTAssertEqual(obj as? Int, 1)
            return AnyPromise(after(seconds: 0).then{ 2 })
        }.then { obj -> Void  in
            XCTAssertEqual(obj as? Int, 2)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test3() {
        let ex = expectation(description: "")

        // AnyPromise.then { return Promise<Int> }

        let input = after(seconds: 0).then{ 1 }

        AnyPromise(input).then { obj -> Promise<Int> in
            XCTAssertEqual(obj as? Int, 1)
            return after(seconds: 0).then{ 2 }
        }.then { value -> Void  in
            XCTAssertEqual(value, 2)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }


    // can return AnyPromise (that fulfills) in then handler
    func test4() {
        let ex = expectation(description: "")
        Promise(value: 1).then { _ -> AnyPromise in
            return AnyPromise(after(seconds: 0).then{ 1 })
        }.then { x -> Void in
            XCTAssertEqual(x as? Int, 1)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    // can return AnyPromise (that rejects) in then handler
    func test5() {
        let ex = expectation(description: "")

        Promise(value: 1).then { _ -> AnyPromise in
            let promise = after(interval: .milliseconds(100)).then{ throw Error.dummy }
            return AnyPromise(promise)
        }.catch { err in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}

private enum Error: Swift.Error {
    case dummy
}
