#import <CloudKit/CKRecordID.h>
#import "CKContainer+PromiseKit.h"
#import "PromiseKit/Promise.h"

@implementation CKContainer (PromiseKit)

- (PMKPromise *)accountStatus {
    return [PMKPromise promiseWithIntegerAdapter:^(PMKIntegerAdapter adapter) {
        [self accountStatusWithCompletionHandler:adapter];
    }];
}

- (PMKPromise *)requestApplicationPermission:(CKApplicationPermissions)permissions {
    return [PMKPromise promiseWithIntegerAdapter:^(PMKIntegerAdapter adapter) {
        [self requestApplicationPermission:permissions completionHandler:adapter];
    }];
}

- (PMKPromise *)statusForApplicationPermission:(CKApplicationPermissions)applicationPermission {
    return [PMKPromise promiseWithIntegerAdapter:^(PMKIntegerAdapter adapter) {
        [self statusForApplicationPermission:applicationPermission completionHandler:adapter];
    }];
}

- (PMKPromise *)discoverAllContactUserInfos {
    return [PMKPromise promiseWithAdapter:^(PMKAdapter adapter){
        [self discoverAllContactUserInfosWithCompletionHandler:adapter];
    }];
}

- (PMKPromise *)discoverUserInfo:(id)input {
    return [PMKPromise promiseWithAdapter:^(PMKAdapter adapter){
        if ([input isKindOfClass:[CKRecordID class]]) {
            [self discoverUserInfoWithUserRecordID:input completionHandler:adapter];
        } else {
            [self discoverUserInfoWithEmailAddress:input completionHandler:adapter];
        }
    }];
}

- (PMKPromise *)fetchUserRecordID {
    return [PMKPromise promiseWithAdapter:^(PMKAdapter adapter) {
        [self fetchUserRecordIDWithCompletionHandler:adapter];
    }];
}

@end
