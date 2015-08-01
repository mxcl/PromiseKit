import Foundation
import PromiseKit
import XCTest


class TestPromiseBridge: XCTestCase {
    func testCanBridgeSwiftArray() {
        let p = Promise([NSString(),NSString(),NSString()])
        let ap = AnyPromise(bound: p)
        XCTAssertGreaterThan(ap.description.characters.count, 0)

        // no test since we'd need to write objc, but also
        // mainly we are just testing the above compiles
    }

    func testCanBridgeSwiftDictionary() {
        let p = Promise([NSString():NSString()])
        let ap = AnyPromise(bound: p)
        XCTAssertGreaterThan(ap.description.characters.count, 0)

        // no test since we'd need to write objc, but also
        // mainly we are just testing the above compiles
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
