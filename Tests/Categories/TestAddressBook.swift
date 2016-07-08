import AddressBook
import Foundation
import PromiseKit
import XCTest

class Test_AddressBook_Swift: XCTestCase {
    func test() {
        let ex = expectation(description: "")
        ABAddressBookRequestAccess().then { (auth: ABAuthorizationStatus) in
            XCTAssertEqual(auth, ABAuthorizationStatus.authorized)
        }.then(execute: ex.fulfill)
        waitForExpectations(timeout: 1)
    }
}
