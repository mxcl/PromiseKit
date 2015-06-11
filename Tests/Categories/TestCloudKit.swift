import CloudKit
import PromiseKit
import XCTest

//TODO possibly we should interpret eg. request permission result of Denied as error
// PMK should only resolve with values that allow a typical chain to proceed

class TestCKContainer: XCTestCase {

    func __test(swizzler: Selector, body: () -> Promise<Void>) {
        // again, could not subclass CKContainer as then Swift freaks the fuck out
        // and won't alow me to call the class initializer

        swizzle(CKContainer.self, swizzler) {
            let ex = expectationWithDescription("")
            body().then(ex.fulfill)
            waitForExpectationsWithTimeout(1, handler: nil)
        }
    }

    func testAccountStatus() {
        __test("accountStatusWithCompletionHandler:") { ex in
            CKContainer.defaultContainer().accountStatus().then {
                XCTAssertEqual($0, .CouldNotDetermine)
            }
        }
    }

    func testRequestApplicationPermission() {
        let pp = CKApplicationPermissions.UserDiscoverability
        __test("requestApplicationPermission:completionHandler:") {
            CKContainer.defaultContainer().requestApplicationPermission(pp).then {
                XCTAssertEqual($0, .Granted)
            }
        }
    }

    func testStatusForApplicationPermission() {
        let pp = CKApplicationPermissions.UserDiscoverability
        __test("statusForApplicationPermission:completionHandler:") {
            CKContainer.defaultContainer().statusForApplicationPermission(pp).then {
                XCTAssertEqual($0, .Granted)
            }
        }
    }

    func testDiscoverAllContactUserInfos() {
        __test("discoverAllContactUserInfosWithCompletionHandler:") {
            CKContainer.defaultContainer().discoverAllContactUserInfos().then {
                XCTAssertEqual($0, [PMKDiscoveredUserInfo()])
            }
        }
    }

    func testDiscoverUserInfoWithEmailAddress() {
        __test("discoverUserInfoWithEmailAddress:completionHandler:") {
            CKContainer.defaultContainer().discoverUserInfo(email: "mxcl@me.com").then {
                XCTAssertEqual($0, PMKDiscoveredUserInfo())
            }
        }
    }

    func testDiscoverUserInfoWithRecordID() {
        __test("discoverUserInfoWithUserRecordID:completionHandler:") {
            CKContainer.defaultContainer().discoverUserInfo(recordID: dummy()).then {
                XCTAssertEqual($0, PMKDiscoveredUserInfo())
            }
        }
    }

    func testFetchUserRecordID() {
        __test("fetchUserRecordIDWithCompletionHandler:") {
            CKContainer.defaultContainer().fetchUserRecordID().then {
                XCTAssertEqual($0, dummy())
            }
        }
    }
}



/////////////////////////////////////////////////////////////// resources

private func dummy() -> CKRecordID {
    return CKRecordID(recordName: "foo")
}


extension CKContainer {
    @objc private func pmk_accountStatusWithCompletionHandler(completionHandler: ((CKAccountStatus, NSError!) -> Void)!) {
        completionHandler(CKAccountStatus.CouldNotDetermine, nil)
    }

    @objc private func pmk_requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock!) {
        completionHandler(.Granted, nil)
    }

    @objc private func pmk_statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock!) {
        completionHandler(.Granted, nil)
    }

    @objc private func pmk_discoverAllContactUserInfosWithCompletionHandler(completionHandler: (([AnyObject]!, NSError!) -> Void)!) {
        completionHandler([PMKDiscoveredUserInfo()], nil)
    }

    @objc private func pmk_discoverUserInfoWithEmailAddress(email: String!, completionHandler: ((CKDiscoveredUserInfo!, NSError!) -> Void)!) {
        completionHandler(PMKDiscoveredUserInfo(), nil)
    }

    @objc private func pmk_discoverUserInfoWithUserRecordID(userRecordID: CKRecordID!, completionHandler: ((CKDiscoveredUserInfo!, NSError!) -> Void)!) {
        completionHandler(PMKDiscoveredUserInfo(), nil)
    }

    @objc private func pmk_fetchUserRecordIDWithCompletionHandler(completionHandler: ((CKRecordID!, NSError!) -> Void)!) {
        completionHandler(dummy(), nil)
    }
}
