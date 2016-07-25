import Accounts
import PromiseKit
import XCTest

class TestACAccountStore: XCTestCase {
    var dummy: ACAccount { return ACAccount() }

    func testRenewCredentialsForAccount() {
        let ex = expectationWithDescription("")

        class MockAccountStore: ACAccountStore {
            override func renewCredentialsForAccount(account: ACAccount!, completion: ACAccountStoreCredentialRenewalHandler!) {
                completion(.Renewed, nil)
            }
        }

        MockAccountStore().renewCredentialsForAccount(dummy).then { result -> Void in
            XCTAssertEqual(result, ACAccountCredentialRenewResult.Renewed)
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

//    func testRequestAccessToAccountsWithType() {
//        class MockAccountStore: ACAccountStore {
//            override func requestAccessToAccountsWithType(accountType: ACAccountType!, options: [NSObject : AnyObject]!, completion: ACAccountStoreRequestAccessCompletionHandler!) {
//                completion(true, nil)
//            }
//        }
//
//        let ex = expectationWithDescription("")
//        let store = MockAccountStore()
//        let type = store.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
//        store.requestAccessToAccountsWithType(type).then { _ in
//            ex.fulfill()
//        }
//
//        waitForExpectationsWithTimeout(1, handler: nil)
//    }

    func testSaveAccount() {
        class MockAccountStore: ACAccountStore {
            override func saveAccount(account: ACAccount!, withCompletionHandler completionHandler: ACAccountStoreSaveCompletionHandler!) {
                completionHandler(true, nil)
            }
        }

        let ex = expectationWithDescription("")
        MockAccountStore().saveAccount(dummy).then { _ in
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRemoveAccount() {
        class MockAccountStore: ACAccountStore {
            override func removeAccount(account: ACAccount!, withCompletionHandler completionHandler: ACAccountStoreSaveCompletionHandler!) {
                completionHandler(true, nil)
            }
        }

        let ex = expectationWithDescription("")
        MockAccountStore().removeAccount(dummy).then { _ in
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
