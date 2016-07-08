import CloudKit
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `CKContainer` category:

    use_frameworks!
    pod "PromiseKit/CloudKit"
 
 And then in your sources:

    @import PromiseKit;
*/
extension CKContainer {
    public func accountStatus() -> Promise<CKAccountStatus> {
        return Promise.wrap(resolver: accountStatus)
    }

    public func requestApplicationPermission(_ applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise.wrap { requestApplicationPermission(applicationPermissions, completionHandler: $0) }
    }

    public func statusForApplicationPermission(_ applicationPermissions: CKApplicationPermissions) -> Promise<CKApplicationPermissionStatus> {
        return Promise.wrap { status(forApplicationPermission: applicationPermissions, completionHandler: $0) }
    }

    public func discoverAllContactUserInfos() -> Promise<[CKDiscoveredUserInfo]> {
        return Promise.wrap(resolver: discoverAllContactUserInfos)
    }

    public func discoverUserInfo(withEmailAddress email: String) -> Promise<CKDiscoveredUserInfo> {
        return Promise.wrap { discoverUserInfo(withEmailAddress: email, completionHandler: $0) }
    }

    public func discoverUserInfo(withUserRecordID recordID: CKRecordID) -> Promise<CKDiscoveredUserInfo> {
        return Promise.wrap { self.discoverUserInfo(withUserRecordID: recordID, completionHandler: $0) }
    }

    public func fetchUserRecordID() -> Promise<CKRecordID> {
        return Promise.wrap(resolver: fetchUserRecordID)
    }
}
