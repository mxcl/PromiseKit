import EventKit
import Foundation
import PromiseKit
import XCTest

class Test_EventKit_Swift: XCTestCase {
    func test() {
        let ex = expectationWithDescription("")
        EKEventStoreRequestAccess().then { _ in
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
