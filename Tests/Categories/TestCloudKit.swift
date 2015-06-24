import CloudKit
import PromiseKit
import XCTest

//TODO possibly we should interpret eg. request permission result of Denied as error
// PMK should only resolve with values that allow a typical chain to proceed

class TestCKContainer: XCTestCase {

    func testAccountStatus() {
        class MockContainer: CKContainer {
            init(_: Bool = false)
            {}

            private override func accountStatusWithCompletionHandler(completionHandler: (CKAccountStatus, NSError?) -> Void) {
                completionHandler(.CouldNotDetermine, nil)
            }
        }

        let ex = expectationWithDescription("")
        MockContainer().accountStatus().then { status -> Void in
            XCTAssertEqual(status, .CouldNotDetermine)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRequestApplicationPermission() {
        class MockContainer: CKContainer {
            init(_: Bool = false)
            {}

            private override func requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock) {
                completionHandler(.Granted, nil)
            }
        }

        let ex = expectationWithDescription("")
        let pp = CKApplicationPermissions.UserDiscoverability
        MockContainer().requestApplicationPermission(pp).then { perms -> Void in
            XCTAssertEqual(perms, .Granted)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testStatusForApplicationPermission() {
        class MockContainer: CKContainer {
            init(_: Bool = false)
            {}

            private override func statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock) {
                completionHandler(.Granted, nil)
            }
        }

        let ex = expectationWithDescription("")
        let pp = CKApplicationPermissions.UserDiscoverability
        MockContainer().statusForApplicationPermission(pp).then {
            XCTAssertEqual($0, .Granted)
        }.then(ex.fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDiscoverAllContactUserInfos() {
        class MockContainer: CKContainer {
            init(_: Bool = false)
            {}

            private override func discoverAllContactUserInfosWithCompletionHandler(completionHandler: ([CKDiscoveredUserInfo]?, NSError?) -> Void) {
                completionHandler([PMKDiscoveredUserInfo()], nil)
            }
        }

        let ex = expectationWithDescription("")
        MockContainer().discoverAllContactUserInfos().then {
            XCTAssertEqual($0, [PMKDiscoveredUserInfo()])
        }.then(ex.fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDiscoverUserInfoWithEmailAddress() {
        class MockContainer: CKContainer {
            init(_: Bool = false)
            {}

            private override func discoverUserInfoWithEmailAddress(email: String, completionHandler: (CKDiscoveredUserInfo?, NSError?) -> Void) {
                completionHandler(PMKDiscoveredUserInfo(), nil)
            }
        }

        let ex = expectationWithDescription("")
        MockContainer().discoverUserInfo(email: "mxcl@me.com").then {
            XCTAssertEqual($0, PMKDiscoveredUserInfo())
        }.then(ex.fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDiscoverUserInfoWithRecordID() {
        class MockContainer: CKContainer {
            init(_: Bool = false)
            {}

            private override func discoverUserInfoWithUserRecordID(userRecordID: CKRecordID, completionHandler: (CKDiscoveredUserInfo?, NSError?) -> Void) {
                completionHandler(PMKDiscoveredUserInfo(), nil)
            }
        }

        let ex = expectationWithDescription("")
        MockContainer().discoverUserInfo(recordID: dummy()).then {
            XCTAssertEqual($0, PMKDiscoveredUserInfo())
        }.then(ex.fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testFetchUserRecordID() {
        class MockContainer: CKContainer {
            init(_: Bool = false)
            {}

            private override func fetchUserRecordIDWithCompletionHandler(completionHandler: (CKRecordID?, NSError?) -> Void) {
                completionHandler(dummy(), nil)
            }
        }

        let ex = expectationWithDescription("")
        MockContainer().fetchUserRecordID().then {
            XCTAssertEqual($0, dummy())
        }.then(ex.fulfill)
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}



/////////////////////////////////////////////////////////////// resources

private func dummy() -> CKRecordID {
    return CKRecordID(recordName: "foo")
}
