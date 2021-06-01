#if canImport(CloudKit)

import CloudKit.CKDatabase
#if !PMKCocoaPods
import PromiseKit
#endif


/**
 To import the `CKDatabase` category:

    use_frameworks!
    pod "PromiseKit/CloudKit"
 
 And then in your sources:

    @import PromiseKit;
*/
public extension CKDatabase {
    /// Fetches one record asynchronously from the current database.
    func fetch(withRecordID recordID: CKRecord.ID) -> Promise<CKRecord> {
        return Promise { fetch(withRecordID: recordID, completionHandler: $0.resolve) }
    }

    /// Fetches one record zone asynchronously from the current database.
    func fetch(withRecordZoneID recordZoneID: CKRecordZone.ID) -> Promise<CKRecordZone> {
        return Promise { fetch(withRecordZoneID: recordZoneID, completionHandler: $0.resolve) }
    }
    /// Fetches all record zones asynchronously from the current database.
    func fetchAllRecordZones() -> Promise<[CKRecordZone]> {
        return Promise { fetchAllRecordZones(completionHandler: $0.resolve) }
    }

    /// Saves one record zone asynchronously to the current database.
    func save(_ record: CKRecord) -> Promise<CKRecord> {
        return Promise { save(record, completionHandler: $0.resolve) }
    }

    /// Saves one record zone asynchronously to the current database.
    func save(_ recordZone: CKRecordZone) -> Promise<CKRecordZone> {
        return Promise { save(recordZone, completionHandler: $0.resolve) }
    }

    /// Delete one subscription object asynchronously from the current database.
    func delete(withRecordID recordID: CKRecord.ID) -> Promise<CKRecord.ID> {
        return Promise { delete(withRecordID: recordID, completionHandler: $0.resolve) }
    }

    /// Delete one subscription object asynchronously from the current database.
    func delete(withRecordZoneID zoneID: CKRecordZone.ID) -> Promise<CKRecordZone.ID> {
        return Promise { delete(withRecordZoneID: zoneID, completionHandler: $0.resolve) }
    }

    /// Searches the specified zone asynchronously for records that match the query parameters.
    func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID? = nil) -> Promise<[CKRecord]> {
        return Promise { perform(query, inZoneWith: zoneID, completionHandler: $0.resolve) }
    }

    /// Fetches the record for the current user.
    func fetchUserRecord(_ container: CKContainer = CKContainer.default()) -> Promise<CKRecord> {
        return container.fetchUserRecordID().then(on: nil) { uid in
            return self.fetch(withRecordID: uid)
        }
    }
}

#if !os(watchOS)
public extension CKDatabase {
    /// Fetches one record zone asynchronously from the current database.
    func fetch(withSubscriptionID subscriptionID: String) -> Promise<CKSubscription> {
        return Promise { fetch(withSubscriptionID: subscriptionID, completionHandler: $0.resolve) }
    }

    /// Fetches all subscription objects asynchronously from the current database.
    func fetchAllSubscriptions() -> Promise<[CKSubscription]> {
        return Promise { fetchAllSubscriptions(completionHandler: $0.resolve) }
    }

    /// Saves one subscription object asynchronously to the current database.
    func save(_ subscription: CKSubscription) -> Promise<CKSubscription> {
        return Promise { save(subscription, completionHandler: $0.resolve) }
    }

    /// Delete one subscription object asynchronously from the current database.
    func delete(withSubscriptionID subscriptionID: String) -> Promise<String> {
        return Promise { delete(withSubscriptionID: subscriptionID, completionHandler: $0.resolve) }
    }
}
#endif

#endif
