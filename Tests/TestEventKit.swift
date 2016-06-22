import EventKit
import Foundation
import PromiseKit
import XCTest

class Test_EventKit_Swift: XCTestCase {
    func test() {
        let ex = expectation(withDescription: "")
        EKEventStoreRequestAccess().then { _ in
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
