import AddressBook
import Foundation
import PromiseKit
import XCTest

class Test_AddressBook_Swift: XCTestCase {
    func test() {
        // AddressBook behaves differently in CI :(
        guard !isTravis() else { return }

        let ex = expectationWithDescription("")
        ABAddressBookRequestAccess().then { (auth: ABAuthorizationStatus) in
            XCTAssertEqual(auth, ABAuthorizationStatus.Authorized)
        }.then(ex.fulfill)
        waitForExpectationsWithTimeout(30, handler: nil)
    }
}
