#import <CloudKit/CKRecordID.h>
#import "CKContainer+PromiseKit.h"
#import "PromiseKit/Promise.h"

@implementation CKContainer (PromiseKit)

- (PMKPromise *)accountStatus {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [self accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
            if (error)
                reject(error);
            else
                fulfill(@(accountStatus));
        }];
    }];
}

- (PMKPromise *)requestApplicationPermission:(CKApplicationPermissions)permissions {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [self requestApplicationPermission:permissions completionHandler:^(CKApplicationPermissionStatus status, NSError *error) {
            if (error)
                reject(error);
            else
                fulfill(@(status));
        }];
    }];
}

- (PMKPromise *)statusForApplicationPermission:(CKApplicationPermissions)applicationPermission {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [self statusForApplicationPermission:applicationPermission completionHandler:^(CKApplicationPermissionStatus status, NSError *error) {
            if (error)
                reject(error);
            else
                fulfill(@(status));
        }];
    }];
}

- (PMKPromise *)discoverAllContactUserInfos {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [self discoverAllContactUserInfosWithCompletionHandler:^(NSArray *userInfos, NSError *error) {
            if (error)
                reject(error);
            else
                fulfill(userInfos);
        }];
    }];
}

- (PMKPromise *)discoverUserInfo:(id)input {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        void (^handler)(CKDiscoveredUserInfo *, NSError *) = ^(CKDiscoveredUserInfo *info, NSError *error) {
            if (error)
                reject(error);
            else
                fulfill(info);
        };
        if ([input isKindOfClass:[CKRecordID class]]) {
            [self discoverUserInfoWithUserRecordID:input completionHandler:handler];
        } else {
            [self discoverUserInfoWithEmailAddress:input completionHandler:handler];
        }
    }];
}

- (PMKPromise *)fetchUserRecordID {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [self fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
            if (error)
                reject(error);
            else
                fulfill(recordID);
        }];
    }];
}

@end
