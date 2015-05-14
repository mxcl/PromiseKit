#import "CKDatabase+AnyPromise.h"

@implementation CKDatabase (PromiseKit)

#define mkmethod1(method) \
- (AnyPromise *)method { \
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) { \
        [self method ## WithCompletionHandler:^(id a, id b){ \
            resolve(b ?: a); \
        }]; \
    }]; \
}

#define mkmethod2(method) \
- (AnyPromise *)method { \
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) { \
        [self method completionHandler:^(id a, id b){ \
            resolve(b ?: a); \
        }]; \
    }]; \
}

mkmethod2(fetchRecordWithID:(CKRecordID *)recordID);
mkmethod2(saveRecord:(CKRecord *)record);
mkmethod2(deleteRecordWithID:(CKRecordID *)recordID);

mkmethod2(performQuery:(CKQuery *)query inZoneWithID:(CKRecordZoneID *)zoneID);

mkmethod1(fetchAllRecordZones);
mkmethod2(fetchRecordZoneWithID:(CKRecordZoneID *)zoneID);
mkmethod2(saveRecordZone:(CKRecordZone *)zone);
mkmethod2(deleteRecordZoneWithID:(CKRecordZoneID *)zoneID);

mkmethod2(fetchSubscriptionWithID:(NSString *)subscriptionID);
mkmethod1(fetchAllSubscriptions);
mkmethod2(saveSubscription:(CKSubscription *)subscription);
mkmethod2(deleteSubscriptionWithID:(NSString *)subscriptionID);

@end
