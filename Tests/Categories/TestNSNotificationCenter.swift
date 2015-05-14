import Foundation
import PromiseKit
import XCTest

private let PMKTestNotification = "PMKTestNotification"

class TestNSNotificationCenter: XCTestCase {
    func test() {
        let ex = expectationWithDescription("")
        let userInfo: [NSObject: AnyObject] = ["a": 1]

        NSNotificationCenter.once(PMKTestNotification).then { (d: [NSObject: AnyObject]) -> Void in
            //XCTAssertEqual(d, userInfo) FIXME swift won't compile this!
            ex.fulfill()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(PMKTestNotification, object: nil, userInfo: userInfo)

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
