import CloudKit.CKDatabase

private func proxy<T>(fulfill: (T)->(), reject: (NSError)->())(value: T!, error: NSError!) {
    if value != nil { fulfill(value!) } else { reject(error!) }
}

extension CKDatabase {
    func fetchRecordWithID(recordID: CKRecordID) -> Promise<CKRecord> {
        return Promise { d in
            self.fetchRecordWithID(recordID, completionHandler: proxy(d))
        }
    }

    func fetchRecordZoneWithID(recordZoneID: CKRecordZoneID) -> Promise<CKRecordZone> {
        return Promise { d in
            self.fetchRecordZoneWithID(recordZoneID, completionHandler: proxy(d))
        }
    }

    func fetchSubscriptionWithID(subscriptionID :String) -> Promise<CKSubscription> {
        return Promise { d in
            self.fetchSubscriptionWithID(subscriptionID, completionHandler: proxy(d))
        }
    }

    func fetchAllRecordZones() -> Promise<[CKRecordZone]> {
        return Promise { d in
            self.fetchAllRecordZonesWithCompletionHandler({
                proxy(d)(value: $0 as [CKRecordZone], error: $1)
            })
        }
    }

    func fetchAllSubscriptions() -> Promise<[CKSubscription]> {
        return Promise { d in
            self.fetchAllSubscriptionsWithCompletionHandler({
                proxy(d)(value: $0 as [CKSubscription], error: $1)
            })
        }
    }

    func save(record: CKRecord) -> Promise<CKRecord> {
        return Promise { d in
            self.saveRecord(record, completionHandler: proxy(d))
        }
    }

    func save(recordZone: CKRecordZone) -> Promise<CKRecordZone> {
        return Promise { d in
            self.saveRecordZone(recordZone, completionHandler: proxy(d))
        }
    }

    func save(subscription: CKSubscription) -> Promise<CKSubscription> {
        return Promise { d in
            self.saveSubscription(subscription, completionHandler: proxy(d))
        }
    }

    func deleteRecordWithID(recordID: CKRecordID) -> Promise<CKRecordID> {
        return Promise { d in
            self.deleteRecordWithID(recordID, completionHandler: proxy(d))
        }
    }

    func deleteRecordZoneWithID(zoneID: CKRecordZoneID) -> Promise<CKRecordZoneID> {
        return Promise { d in
            self.deleteRecordZoneWithID(zoneID, completionHandler: proxy(d))
        }
    }

    func deleteSubscriptionWithID(subscriptionID: String) -> Promise<String> {
        return Promise { d in
            self.deleteSubscriptionWithID(subscriptionID, completionHandler: proxy(d))
        }
    }

    func performQuery(query: CKQuery, inZoneWithID zoneID: CKRecordZoneID) -> Promise<[CKRecord]> {
        return Promise { d in
            self.performQuery(query, inZoneWithID: zoneID) {
                proxy(d)(value: $0 as [CKRecord], error: $1)
            }
        }
    }
}
