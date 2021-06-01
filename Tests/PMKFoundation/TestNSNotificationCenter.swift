import PMKFoundation
import Foundation
import PromiseKit
import XCTest

class NSNotificationCenterTests: XCTestCase {
    func test() {
        let ex = expectation(description: "")
        let userInfo = ["a": 1]

        NotificationCenter.default.observe(once: PMKTestNotification).done { value in
            XCTAssertEqual(value.userInfo?.count, 1)
            ex.fulfill()
        }

        NotificationCenter.default.post(name: PMKTestNotification, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: 1)
    }
}

private let PMKTestNotification = Notification.Name("PMKTestNotification")
