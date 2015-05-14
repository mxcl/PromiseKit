#import <CloudKit/CKRecordID.h>
#import "CKContainer+AnyPromise.h"

@implementation CKContainer (PromiseKit)

- (AnyPromise *)accountStatus {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
            resolve(error ?: @(accountStatus));
        }];
    }];
}

- (AnyPromise *)requestApplicationPermission:(CKApplicationPermissions)permissions {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestApplicationPermission:permissions completionHandler:^(CKApplicationPermissionStatus status, NSError *error) {
            resolve(error ?: @(status));
        }];
    }];
}

- (AnyPromise *)statusForApplicationPermission:(CKApplicationPermissions)applicationPermission {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self statusForApplicationPermission:applicationPermission completionHandler:^(CKApplicationPermissionStatus status, NSError *error) {
            resolve(error ?: @(status));
        }];
    }];
}

- (AnyPromise *)discoverAllContactUserInfos {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self discoverAllContactUserInfosWithCompletionHandler:^(NSArray *userInfos, NSError *error) {
            resolve(error ?: userInfos);
        }];
    }];
}

- (AnyPromise *)discoverUserInfo:(id)input {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        void (^adapter)(id, id) = ^(id value, id error){
            resolve(error ?: error);
        };
        if ([input isKindOfClass:[CKRecordID class]]) {
            [self discoverUserInfoWithUserRecordID:input completionHandler:adapter];
        } else {
            [self discoverUserInfoWithEmailAddress:input completionHandler:adapter];
        }
    }];
}

- (AnyPromise *)fetchUserRecordID {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
            resolve(error ?: recordID);
        }];
    }];
}

@end
