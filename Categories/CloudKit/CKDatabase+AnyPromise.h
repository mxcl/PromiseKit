#import <CloudKit/CKDatabase.h>
#import <PromiseKit/AnyPromise.h>

/**
 To import the `CKDatabase` category:

    use_frameworks!
    pod "PromiseKit/CloudKit"
 
 And then in your sources:

    @import PromiseKit;
*/
@interface CKDatabase (PromiseKit)

- (AnyPromise *)fetchRecordWithID:(CKRecordID *)recordID;
- (AnyPromise *)saveRecord:(CKRecord *)record;
- (AnyPromise *)deleteRecordWithID:(CKRecordID *)recordID;

- (AnyPromise *)performQuery:(CKQuery *)query inZoneWithID:(CKRecordZoneID *)zoneID;

- (AnyPromise *)fetchAllRecordZones;
- (AnyPromise *)fetchRecordZoneWithID:(CKRecordZoneID *)zoneID;
- (AnyPromise *)saveRecordZone:(CKRecordZone *)zone;
- (AnyPromise *)deleteRecordZoneWithID:(CKRecordZoneID *)zoneID;

- (AnyPromise *)fetchSubscriptionWithID:(NSString *)subscriptionID;
- (AnyPromise *)fetchAllSubscriptions;
- (AnyPromise *)saveSubscription:(CKSubscription *)subscription;
- (AnyPromise *)deleteSubscriptionWithID:(NSString *)subscriptionID;

@end
