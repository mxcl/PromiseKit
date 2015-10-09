import Foundation
import PromiseKit
import XCTest

class Test_NSNotificationCenter_Swift: XCTestCase {
    func test() {
        let ex = expectationWithDescription("")
        let userInfo: [NSObject: AnyObject] = ["a": 1]

        NSNotificationCenter.once(PMKTestNotification).then { d -> Void in
            let a = userInfo as NSDictionary
            let b = d as NSDictionary
            XCTAssertTrue(a.isEqual(b))
            ex.fulfill()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(PMKTestNotification, object: nil, userInfo: userInfo)

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}

private let PMKTestNotification = "PMKTestNotification"
