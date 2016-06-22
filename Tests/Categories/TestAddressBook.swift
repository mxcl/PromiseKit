import AddressBook
import Foundation
import PromiseKit
import XCTest

class Test_AddressBook_Swift: XCTestCase {
    func test() {
        let ex = expectation(withDescription: "")
        ABAddressBookRequestAccess().then { (auth: ABAuthorizationStatus) in
            XCTAssertEqual(auth, ABAuthorizationStatus.authorized)
        }.then(ex.fulfill)
        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
