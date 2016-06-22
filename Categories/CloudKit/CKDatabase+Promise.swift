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
    public func fetchRecordWithID(_ recordID: CKRecordID) -> Promise<CKRecord> {
        return Promise { fetch(withRecordID: recordID, completionHandler: $0) }
    }

    public func fetchRecordZoneWithID(_ recordZoneID: CKRecordZoneID) -> Promise<CKRecordZone> {
        return Promise { fetch(withRecordZoneID: recordZoneID, completionHandler: $0) }
    }

    public func fetchSubscriptionWithID(_ subscriptionID: String) -> Promise<CKSubscription> {
        return Promise { fetch(withSubscriptionID: subscriptionID, completionHandler: $0) }
    }

    public func fetchAllRecordZones() -> Promise<[CKRecordZone]> {
        return Promise { fetchAll(completionHandler: $0) }
    }

    public func fetchAllSubscriptions() -> Promise<[CKSubscription]> {
        return Promise { fetchAll(completionHandler: $0) }
    }

    public func save(_ record: CKRecord) -> Promise<CKRecord> {
        return Promise { self.save(record, completionHandler: $0) }
    }

    public func save(_ recordZone: CKRecordZone) -> Promise<CKRecordZone> {
        return Promise { self.save(recordZone, completionHandler: $0) }
    }

    public func save(_ subscription: CKSubscription) -> Promise<CKSubscription> {
        return Promise { self.save(subscription, completionHandler: $0) }
    }

    public func deleteRecordWithID(_ recordID: CKRecordID) -> Promise<CKRecordID> {
        return Promise { delete(withRecordID: recordID, completionHandler: $0) }
    }

    public func deleteRecordZoneWithID(_ zoneID: CKRecordZoneID) -> Promise<CKRecordZoneID> {
        return Promise { delete(withRecordZoneID: zoneID, completionHandler: $0) }
    }

    public func deleteSubscriptionWithID(_ subscriptionID: String) -> Promise<String> {
        return Promise { delete(withSubscriptionID: subscriptionID, completionHandler: $0) }
    }

    public func performQuery(_ query: CKQuery, inZoneWithID zoneID: CKRecordZoneID? = nil) -> Promise<[CKRecord]> {
        return Promise { perform(query, inZoneWith: zoneID, completionHandler: $0) }
    }

    public func performQuery(_ query: CKQuery, inZoneWithID zoneID: CKRecordZoneID? = nil) -> Promise<CKRecord?> {
        return Promise { resolve in
            perform(query, inZoneWith: zoneID) { records, error in
                resolve(records?.first, error)
            }
        }
    }

    public func fetchUserRecord(_ container: CKContainer = CKContainer.default()) -> Promise<CKRecord> {
        return container.fetchUserRecordID().then(on: zalgo) { uid -> Promise<CKRecord> in
            return self.fetchRecordWithID(uid)
        }
    }
}
