import CloudKit
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `CKContainer` category:

    use_frameworks!
    pod "PromiseKit/CloudKit"
 
 And then in your sources:

    #import <PromiseKit/PromiseKit.h>
*/
extension CKContainer {
    public func accountStatus() -> Promise<CKAccountStatus> {
        return Promise<CKAccountStatus> { self.accountStatusWithCompletionHandler($0) }
    }

    public func requestApplicationPermission(applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise<CKApplicationPermissionStatus> { self.requestApplicationPermission(applicationPermissions, completionHandler: $0) }
    }

    public func statusForApplicationPermission(applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise { statusForApplicationPermission(applicationPermissions, completionHandler: $0) }
    }

    public func discoverAllContactUserInfos() -> Promise<[CKDiscoveredUserInfo]> {
        return Promise(resolver: { self.discoverAllContactUserInfosWithCompletionHandler($0) })
    }

    public func discoverUserInfo(email email: String) -> Promise<CKDiscoveredUserInfo> {
        return Promise { discoverUserInfoWithEmailAddress(email, completionHandler: $0) }
    }

    public func discoverUserInfo(recordID recordID: CKRecordID) -> Promise<CKDiscoveredUserInfo> {
        return Promise { discoverUserInfoWithUserRecordID(recordID, completionHandler: $0) }
    }

    public func fetchUserRecordID() -> Promise<CKRecordID> {
        return Promise { fetchUserRecordIDWithCompletionHandler($0) }
    }
}
