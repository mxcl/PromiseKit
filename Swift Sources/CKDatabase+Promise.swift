import CloudKit.CKDatabase

private func proxy<T>(fulfill: (T)->(), reject: (NSError)->())(value: T!, error: NSError!) {
    if value != nil { fulfill(value!) } else { reject(error!) }
}

extension CKDatabase {
    public func fetchRecordWithID(recordID: CKRecordID) -> Promise<CKRecord> {
        return Promise { f, r in
            self.fetchRecordWithID(recordID, completionHandler: proxy(f, r))
        }
    }

    public func fetchRecordZoneWithID(recordZoneID: CKRecordZoneID) -> Promise<CKRecordZone> {
        return Promise { f, r in
            self.fetchRecordZoneWithID(recordZoneID, completionHandler: proxy(f, r))
        }
    }

    public func fetchSubscriptionWithID(subscriptionID: String) -> Promise<CKSubscription> {
        return Promise { f, r in
            self.fetchSubscriptionWithID(subscriptionID, completionHandler: proxy(f, r))
        }
    }

    public func fetchAllRecordZones() -> Promise<[CKRecordZone]> {
        return Promise { f, r in
            self.fetchAllRecordZonesWithCompletionHandler({
                proxy(f, r)(value: $0 as! [CKRecordZone], error: $1)
            })
        }
    }

    public func fetchAllSubscriptions() -> Promise<[CKSubscription]> {
        return Promise { f, r in
            self.fetchAllSubscriptionsWithCompletionHandler({
                proxy(f, r)(value: $0 as! [CKSubscription], error: $1)
            })
        }
    }

    public func save(record: CKRecord) -> Promise<CKRecord> {
        return Promise { f, r in
            self.saveRecord(record, completionHandler: proxy(f, r))
        }
    }

    public func save(recordZone: CKRecordZone) -> Promise<CKRecordZone> {
        return Promise { f, r in
            self.saveRecordZone(recordZone, completionHandler: proxy(f, r))
        }
    }

    public func save(subscription: CKSubscription) -> Promise<CKSubscription> {
        return Promise { f, r in
            self.saveSubscription(subscription, completionHandler: proxy(f, r))
        }
    }

    public func deleteRecordWithID(recordID: CKRecordID) -> Promise<CKRecordID> {
        return Promise { f, r in
            self.deleteRecordWithID(recordID, completionHandler: proxy(f, r))
        }
    }

    public func deleteRecordZoneWithID(zoneID: CKRecordZoneID) -> Promise<CKRecordZoneID> {
        return Promise { f, r in
            self.deleteRecordZoneWithID(zoneID, completionHandler: proxy(f, r))
        }
    }

    public func deleteSubscriptionWithID(subscriptionID: String) -> Promise<String> {
        return Promise { f, r in
            self.deleteSubscriptionWithID(subscriptionID, completionHandler: proxy(f, r))
        }
    }

    public func performQuery(query: CKQuery, inZoneWithID zoneID: CKRecordZoneID? = nil) -> Promise<[CKRecord]> {
        return Promise { f, r in
            self.performQuery(query, inZoneWithID: zoneID) {
                proxy(f, r)(value: $0 as! [CKRecord], error: $1)
            }
        }
    }

    public func performQuery(query: CKQuery, inZoneWithID zoneID: CKRecordZoneID? = nil) -> Promise<CKRecord?> {
        return Promise { fulfill, reject in
            self.performQuery(query, inZoneWithID: zoneID) { (records, error) in
                if records == nil {
                    reject(error)
                } else if records.isEmpty {
                    fulfill(nil)
                } else {
                    fulfill((records as! [CKRecord])[0])
                }
            }
        }
    }

    public func fetchUserRecord(container: CKContainer = CKContainer.defaultContainer()) -> Promise<CKRecord> {
        return container.fetchUserRecordID().then { uid->Promise<CKRecord> in
            return self.fetchRecordWithID(uid)
        }
    }
}
