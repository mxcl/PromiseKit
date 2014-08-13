#import <CloudKit/CKContainer.h>
#import <PromiseKit/fwd.h>

@interface CKContainer (PromiseKit)

- (PMKPromise *)accountStatus;
- (PMKPromise *)requestApplicationPermission:(CKApplicationPermissions)applicationPermission;
- (PMKPromise *)statusForApplicationPermission:(CKApplicationPermissions)applicationPermission;

- (PMKPromise *)discoverAllContactUserInfos;
- (PMKPromise *)discoverUserInfo:(id)emailStringOrRecordID;
- (PMKPromise *)fetchUserRecordID;

@end
