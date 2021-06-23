#if canImport(CloudKit)

#if !PMKCocoaPods
import PromiseKit
#endif
import CloudKit

/**
 To import the `CKContainer` category:

    use_frameworks!
    pod "PromiseKit/CloudKit"
 
 And then in your sources:

    @import PromiseKit;
*/
public extension CKContainer {
    /// Reports whether the current user’s iCloud account can be accessed.
    func accountStatus() -> Promise<CKAccountStatus> {
        return Promise { accountStatus(completionHandler: $0.resolve) }
    }

    /// Requests the specified permission from the user asynchronously.
#if swift(<5.5)
    func requestApplicationPermission(_ applicationPermissions: CKContainer_Application_Permissions) -> Promise<CKContainer_Application_PermissionStatus> {
        return Promise { requestApplicationPermission(applicationPermissions, completionHandler: $0.resolve) }
    }
#else
    func requestApplicationPermission(_ applicationPermissions: CKContainer.ApplicationPermissions) -> Promise<CKContainer.ApplicationPermissionStatus> {
        return Promise { requestApplicationPermission(applicationPermissions, completionHandler: $0.resolve) }
    }
#endif

    /// Checks the status of the specified permission asynchronously.
#if swift(<5.5)
    func status(forApplicationPermission applicationPermissions: CKContainer_Application_Permissions) -> Promise<CKContainer_Application_PermissionStatus> {
        return Promise { status(forApplicationPermission: applicationPermissions, completionHandler: $0.resolve) }
    }
#else
    func status(forApplicationPermission applicationPermissions: CKContainer.ApplicationPermissions) -> Promise<CKContainer.ApplicationPermissionStatus> {
        return Promise { status(forApplicationPermission: applicationPermissions, completionHandler: $0.resolve) }
    }
#endif
    /// Retrieves information about a single user based on the ID of the corresponding user record.
    @available(macOS 10.12, iOS 10, tvOS 10, *)
    func discoverUserIdentity(withUserRecordID recordID: CKRecord.ID) -> Promise<CKUserIdentity> {
        return Promise { discoverUserIdentity(withUserRecordID: recordID, completionHandler: $0.resolve) }
    }

    /// Returns the user record ID associated with the current user.
    func fetchUserRecordID() -> Promise<CKRecord.ID> {
        return Promise { fetchUserRecordID(completionHandler: $0.resolve) }
    }
}

#if !os(tvOS)
@available(macOS 10.12, iOS 10, tvOS 10, *)
public extension CKContainer {
    func discoverAllIdentities() -> Promise<[CKUserIdentity]> {
        return Promise { discoverAllIdentities(completionHandler: $0.resolve) }
    }
}
#endif

#endif
