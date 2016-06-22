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
        return Promise<CKAccountStatus> { self.accountStatus(completionHandler: $0) }
    }

    public func requestApplicationPermission(_ applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise<CKApplicationPermissionStatus> { self.requestApplicationPermission(applicationPermissions, completionHandler: $0) }
    }

    public func statusForApplicationPermission(_ applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise { status(forApplicationPermission: applicationPermissions, completionHandler: $0) }
    }

    public func discoverAllContactUserInfos() -> Promise<[CKDiscoveredUserInfo]> {
        return Promise(resolver: { self.discoverAllContactUserInfos(completionHandler: $0) })
    }

    public func discoverUserInfo(email: String) -> Promise<CKDiscoveredUserInfo> {
        return Promise { self.discoverUserInfo(withEmailAddress: email, completionHandler: $0) }
    }

    public func discoverUserInfo(recordID: CKRecordID) -> Promise<CKDiscoveredUserInfo> {
        return Promise { self.discoverUserInfo(withUserRecordID: recordID, completionHandler: $0) }
    }

    public func fetchUserRecordID() -> Promise<CKRecordID> {
        return Promise { self.fetchUserRecordID(completionHandler: $0) }
    }
}
