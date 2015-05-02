import CloudKit
import PromiseKit

/**
 To import the `CKContainer` category:

    use_frameworks!
    pod "PromiseKit/CloudKit"
 
 And then in your sources:

    #import <PromiseKit/PromiseKit.h>
*/
extension CKContainer {
    public func accountStatus() -> Promise<CKAccountStatus> {
        return Promise { accountStatusWithCompletionHandler($0.resolve) }
    }

    public func requestApplicationPermission(applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise { requestApplicationPermission(applicationPermissions, completionHandler: $0.resolve) }
    }

    public func statusForApplicationPermission(applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise { statusForApplicationPermission(applicationPermissions, completionHandler: $0.resolve) }
    }

    public func discoverAllContactUserInfos() -> Promise<[CKDiscoveredUserInfo]> {
        return Promise<[AnyObject]> { self.discoverAllContactUserInfosWithCompletionHandler($0.resolve) }.then(on: zalgo) { $0 as! [CKDiscoveredUserInfo] }
    }

    public func discoverUserInfo(# email: String) -> Promise<CKDiscoveredUserInfo> {
        return Promise { discoverUserInfoWithEmailAddress(email, completionHandler: $0.resolve) }
    }

    public func discoverUserInfo(# recordID: CKRecordID) -> Promise<CKDiscoveredUserInfo> {
        return Promise { discoverUserInfoWithUserRecordID(recordID, completionHandler: $0.resolve) }
    }

    public func fetchUserRecordID() -> Promise<CKRecordID> {
        return Promise { fetchUserRecordIDWithCompletionHandler($0.resolve) }
    }
}
