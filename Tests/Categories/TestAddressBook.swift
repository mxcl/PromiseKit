import AddressBook
import Foundation
import PromiseKit
import XCTest

class Test_AddressBook_Swift: XCTestCase {
    func test() {
        let ex = expectationWithDescription("")
        ABAddressBookRequestAccess().then { (auth: ABAuthorizationStatus) in
            XCTAssertEqual(auth, ABAuthorizationStatus.Authorized)
        }.then(ex.fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
