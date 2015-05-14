import AddressBook
import Foundation
import PromiseKit
import XCTest

class TestAddressBook: XCTestCase {
    func test1() {
        let ex = expectationWithDescription("")
        ABAddressBookRequestAccess().then { (auth: ABAuthorizationStatus) in
            XCTAssertEqual(auth, .Authorized)
        }.then(ex.fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
