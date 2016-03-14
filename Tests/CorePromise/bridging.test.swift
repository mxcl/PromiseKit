import Foundation
import PromiseKit
import XCTest

class BridgingTestCase_Swift: XCTestCase {
    func testCanBridgeAnyObject() {
        let sentinel = NSURLRequest()
        let p = Promise(sentinel)
        let ap = AnyPromise(bound: p)

        XCTAssertEqual(ap.valueForKey("value") as? NSURLRequest, sentinel)
    }

    func testCanBridgeOptional() {
        let sentinel = Optional.Some(NSURLRequest())
        let p = Promise(sentinel)
        let ap = AnyPromise(bound: p)

        XCTAssertEqual(ap.valueForKey("value") as? NSURLRequest, sentinel!)
    }

    func testCanBridgeSwiftArray() {
        let sentinel = [NSString(),NSString(),NSString()]
        let p = Promise(sentinel)
        let ap = AnyPromise(bound: p)

        XCTAssertEqual(ap.valueForKey("value") as! [NSString], sentinel)
    }

    func testCanBridgeSwiftDictionary() {
        let sentinel = [NSString():NSString()]
        let p = Promise(sentinel)
        let ap = AnyPromise(bound: p)

        XCTAssertEqual(ap.valueForKey("value") as! [NSString:NSString], sentinel)
    }

    func testCanBridgeInt() {
        let sentinel = 3
        let p = Promise(sentinel)
        let ap = AnyPromise(bound: p)
        XCTAssertEqual(ap.valueForKey("value") as? Int, sentinel)
    }

    func testCanBridgeString() {
        let sentinel = "a"
        let p = Promise(sentinel)
        let ap = AnyPromise(bound: p)
        XCTAssertEqual(ap.valueForKey("value") as? String, sentinel)
    }

    func testCanBridgeBool() {
        let sentinel = true
        let p = Promise(sentinel)
        let ap = AnyPromise(bound: p)
        XCTAssertEqual(ap.valueForKey("value") as? Bool, sentinel)
    }

    func testCanChainOffAnyPromiseReturn() {
        let ex = expectationWithDescription("")

        firstly {
            Promise(1)
        }.then { _ -> AnyPromise in
            return PromiseBridgeHelper().valueForKey("bridge2") as! AnyPromise
        }.then { value -> Void in
            XCTAssertEqual(123, value as? Int)
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testCanThenOffAnyPromise() {
        let ex = expectationWithDescription("")

        let ap = PMKDummyAnyPromise_YES() as! AnyPromise
        ap.then { obj -> Void in
            if let value = obj as? NSNumber {
                XCTAssertEqual(value, NSNumber(bool: true))
                ex.fulfill()
            }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCanThenOffManifoldAnyPromise() {
        let ex = expectationWithDescription("")

        let ap = PMKDummyAnyPromise_Manifold() as! AnyPromise
        ap.then { obj -> Void in
            if let value = obj as? NSNumber {
                XCTAssertEqual(value, NSNumber(bool: true))
                ex.fulfill()
            }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}


// for bridging.test.m
@objc(PMKPromiseBridgeHelper) class PromiseBridgeHelper: NSObject {
    @objc func bridge1() -> AnyPromise {
        let p = after(0.01)
        return AnyPromise(bound: p)
    }
}
