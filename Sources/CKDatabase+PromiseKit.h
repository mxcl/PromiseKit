#import <CloudKit/CKDatabase.h>
#import <PromiseKit/fwd.h>

/**
 To import the `CKDatabase` category:

    pod "PromiseKit/CKDatabase"

 Or you can import all categories on `CloudKit`:

    pod "PromiseKit/CloudKit"
*/
@interface CKDatabase (PromiseKit)

- (PMKPromise *)fetchRecordWithID:(CKRecordID *)recordID;
- (PMKPromise *)saveRecord:(CKRecord *)record;
- (PMKPromise *)deleteRecordWithID:(CKRecordID *)recordID;

- (PMKPromise *)performQuery:(CKQuery *)query inZoneWithID:(CKRecordZoneID *)zoneID;

- (PMKPromise *)fetchAllRecordZones;
- (PMKPromise *)fetchRecordZoneWithID:(CKRecordZoneID *)zoneID;
- (PMKPromise *)saveRecordZone:(CKRecordZone *)zone;
- (PMKPromise *)deleteRecordZoneWithID:(CKRecordZoneID *)zoneID;

- (PMKPromise *)fetchSubscriptionWithID:(NSString *)subscriptionID;
- (PMKPromise *)fetchAllSubscriptions;
- (PMKPromise *)saveSubscription:(CKSubscription *)subscription;
- (PMKPromise *)deleteSubscriptionWithID:(NSString *)subscriptionID;

@end
