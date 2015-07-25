import Accounts
import PromiseKit
import XCTest

class Test_ACAccountStore_Swift: XCTestCase {
    var dummy: ACAccount { return ACAccount() }

    func test_renewCredentialsForAccount() {
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

    func test_requestAccessToAccountsWithType() {
        class MockAccountStore: ACAccountStore {
            override func requestAccessToAccountsWithType(accountType: ACAccountType!, options: [NSObject : AnyObject]!, completion: ACAccountStoreRequestAccessCompletionHandler!) {
                completion(true, nil)
            }
        }

        let ex = expectationWithDescription("")
        let store = MockAccountStore()
        let type = store.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        store.requestAccessToAccountsWithType(type).then { _ in
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_saveAccount() {
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

    func test_removeAccount() {
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
