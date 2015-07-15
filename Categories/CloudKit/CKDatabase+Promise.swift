import CloudKit.CKDatabase
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `CKDatabase` category:

    use_frameworks!
    pod "PromiseKit/CloudKit"
 
 And then in your sources:

    #import <PromiseKit/PromiseKit.h>
*/
extension CKDatabase {
    public func fetchRecordWithID(recordID: CKRecordID) -> Promise<CKRecord> {
        return Promise { fetchRecordWithID(recordID, completionHandler: $0) }
    }

    public func fetchRecordZoneWithID(recordZoneID: CKRecordZoneID) -> Promise<CKRecordZone> {
        return Promise { fetchRecordZoneWithID(recordZoneID, completionHandler: $0) }
    }

    public func fetchSubscriptionWithID(subscriptionID: String) -> Promise<CKSubscription> {
        return Promise { fetchSubscriptionWithID(subscriptionID, completionHandler: $0) }
    }

    public func fetchAllRecordZones() -> Promise<[CKRecordZone]> {
        return Promise { fetchAllRecordZonesWithCompletionHandler($0) }
    }

    public func fetchAllSubscriptions() -> Promise<[CKSubscription]> {
        return Promise { fetchAllSubscriptionsWithCompletionHandler($0) }
    }

    public func save(record: CKRecord) -> Promise<CKRecord> {
        return Promise { saveRecord(record, completionHandler: $0) }
    }

    public func save(recordZone: CKRecordZone) -> Promise<CKRecordZone> {
        return Promise { saveRecordZone(recordZone, completionHandler: $0) }
    }

    public func save(subscription: CKSubscription) -> Promise<CKSubscription> {
        return Promise { saveSubscription(subscription, completionHandler: $0) }
    }

    public func deleteRecordWithID(recordID: CKRecordID) -> Promise<CKRecordID> {
        return Promise { deleteRecordWithID(recordID, completionHandler: $0) }
    }

    public func deleteRecordZoneWithID(zoneID: CKRecordZoneID) -> Promise<CKRecordZoneID> {
        return Promise { deleteRecordZoneWithID(zoneID, completionHandler: $0) }
    }

    public func deleteSubscriptionWithID(subscriptionID: String) -> Promise<String> {
        return Promise { deleteSubscriptionWithID(subscriptionID, completionHandler: $0) }
    }

    public func performQuery(query: CKQuery, inZoneWithID zoneID: CKRecordZoneID? = nil) -> Promise<[CKRecord]> {
        return Promise { performQuery(query, inZoneWithID: zoneID, completionHandler: $0) }
    }

    public func performQuery(query: CKQuery, inZoneWithID zoneID: CKRecordZoneID? = nil) -> Promise<CKRecord?> {
        return Promise { resolve in
            performQuery(query, inZoneWithID: zoneID) { records, error in
                resolve(records?.first, error)
            }
        }
    }

    public func fetchUserRecord(container: CKContainer = CKContainer.defaultContainer()) -> Promise<CKRecord> {
        return container.fetchUserRecordID().then(on: zalgo) { uid -> Promise<CKRecord> in
            return self.fetchRecordWithID(uid)
        }
    }
}
