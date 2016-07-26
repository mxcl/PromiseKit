import EventKit
import Foundation
import PromiseKit
import XCTest

class Test_EventKit_Swift: XCTestCase {
    func test() {
        // EventKit behaves differently in CI :(
        guard !isTravis() else { return }

        let ex = expectationWithDescription("")
        EKEventStoreRequestAccess().then { _ in
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(30, handler: nil)
    }
}
