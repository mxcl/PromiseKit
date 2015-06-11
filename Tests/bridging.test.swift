import Foundation
import PromiseKit
import XCTest


class TestPromiseBridge: XCTestCase {
    func testCanBridgeSwiftArray() {
        let p = Promise([NSString(),NSString(),NSString()])
        let ap = AnyPromise(bound: p)

        // no test since we'd need to write objc, but also
        // mainly we are just testing the above compiles
    }

    func testCanBridgeSwiftDictionary() {
        let p = Promise([NSString():NSString()])
        let ap = AnyPromise(bound: p)

        // no test since we'd need to write objc, but also
        // mainly we are just testing the above compiles
    }
}
