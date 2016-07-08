import EventKit
import Foundation
import PromiseKit
import XCTest

class Test_EventKit_Swift: XCTestCase {
    func test() {
        let ex = expectation(description: "")
        EKEventStoreRequestAccess().then { _ in
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
