#import <CloudKit/CKContainer.h>
#import <PromiseKit/AnyPromise.h>

/**
 To import the `CKContainer` category:

    use_frameworks!
    pod "PromiseKit/CloudKit"

 And then in your sources:

    #import <PromiseKit/PromiseKit.h>
*/
@interface CKContainer (PromiseKit)

/**
 Reports whether the current user’s iCloud account can be accessed.

 @return A promise that thens the `CKAccountStatus` of this container.
*/
- (AnyPromise *)accountStatus;

/**
 Requests the specified permission from the user asynchronously.

 @param applicationPermission The requested permission.

 @return A promise that thens the `CKApplicationPermissionStatus` for the
 requested permission.
*/
- (AnyPromise *)requestApplicationPermission:(CKApplicationPermissions)applicationPermission;

/**
 Checks the status of the specified permission asynchronously.

 @param applicationPermission The permission whose status you want to
 check.

 @return A promise that thens the `CKApplicationPermissionStatus` for
 the requested permission.
*/
- (AnyPromise *)statusForApplicationPermission:(CKApplicationPermissions)applicationPermission;

/**

 Retrieves information about all discoverable users that are known to the
 current user.

 @return A promise that thens the array of `CKDiscoveredUserInfo` objects.
*/
- (AnyPromise *)discoverAllContactUserInfos;

/**
 Retrieves information about a single user based on that user’s email
 address or record ID.

 @param emailStringOrRecordID Either the email string or the `CKRecordID`
 for the user record.

 @return A promise that thens the `CKDiscoveredUserInfo` for the
 requested user record.
*/
- (AnyPromise *)discoverUserInfo:(id)emailStringOrRecordID;

/**
 Returns the user record associated with the current user.

 @return A promise that thens the `CKRecord` for the current user or `nil`
 if there is no current user.
*/
- (AnyPromise *)fetchUserRecordID;

@end
