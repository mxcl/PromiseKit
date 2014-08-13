#import "CKDatabase+PromiseKit.h"
#import "PromiseKit/Promise.h"

@implementation CKDatabase (PromiseKit)

#define mkmethod1(method) \
- (PMKPromise *)method { \
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) { \
        [self method ## WithCompletionHandler:^(id result, NSError *error) { \
            if (error) reject(error); else fulfill(result); \
        }]; \
    }]; \
}

#define mkmethod2(method) \
- (PMKPromise *)method { \
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) { \
        [self method completionHandler:^(id result, NSError *error) { \
            if (error) reject(error); else fulfill(result); \
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
