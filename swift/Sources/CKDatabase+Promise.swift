import CloudKit.CKDatabase

private func proxy<T>(fulfill: (T)->(), reject: (NSError)->())(value: T!, error: NSError!) {
    if value != nil { fulfill(value!) } else { reject(error!) }
}

extension CKDatabase {
    public func fetchRecordWithID(recordID: CKRecordID) -> Promise<CKRecord> {
        return Promise { d in
            self.fetchRecordWithID(recordID, completionHandler: proxy(d))
        }
    }

    public func fetchRecordZoneWithID(recordZoneID: CKRecordZoneID) -> Promise<CKRecordZone> {
        return Promise { d in
            self.fetchRecordZoneWithID(recordZoneID, completionHandler: proxy(d))
        }
    }

    public func fetchSubscriptionWithID(subscriptionID :String) -> Promise<CKSubscription> {
        return Promise { d in
            self.fetchSubscriptionWithID(subscriptionID, completionHandler: proxy(d))
        }
    }

    public func fetchAllRecordZones() -> Promise<[CKRecordZone]> {
        return Promise { d in
            self.fetchAllRecordZonesWithCompletionHandler({
                proxy(d)(value: $0 as [CKRecordZone], error: $1)
            })
        }
    }

    public func fetchAllSubscriptions() -> Promise<[CKSubscription]> {
        return Promise { d in
            self.fetchAllSubscriptionsWithCompletionHandler({
                proxy(d)(value: $0 as [CKSubscription], error: $1)
            })
        }
    }

    public func save(record: CKRecord) -> Promise<CKRecord> {
        return Promise { d in
            self.saveRecord(record, completionHandler: proxy(d))
        }
    }

    public func save(recordZone: CKRecordZone) -> Promise<CKRecordZone> {
        return Promise { d in
            self.saveRecordZone(recordZone, completionHandler: proxy(d))
        }
    }

    public func save(subscription: CKSubscription) -> Promise<CKSubscription> {
        return Promise { d in
            self.saveSubscription(subscription, completionHandler: proxy(d))
        }
    }

    public func deleteRecordWithID(recordID: CKRecordID) -> Promise<CKRecordID> {
        return Promise { d in
            self.deleteRecordWithID(recordID, completionHandler: proxy(d))
        }
    }

    public func deleteRecordZoneWithID(zoneID: CKRecordZoneID) -> Promise<CKRecordZoneID> {
        return Promise { d in
            self.deleteRecordZoneWithID(zoneID, completionHandler: proxy(d))
        }
    }

    public func deleteSubscriptionWithID(subscriptionID: String) -> Promise<String> {
        return Promise { d in
            self.deleteSubscriptionWithID(subscriptionID, completionHandler: proxy(d))
        }
    }

    public func performQuery(query: CKQuery, inZoneWithID zoneID: CKRecordZoneID? = nil) -> Promise<[CKRecord]> {
        return Promise { d in
            self.performQuery(query, inZoneWithID: zoneID) {
                proxy(d)(value: $0 as [CKRecord], error: $1)
            }
        }
    }

    public func performQuery(query: CKQuery, inZoneWithID zoneID: CKRecordZoneID? = nil) -> Promise<CKRecord> {
        return Promise { d in
            self.performQuery(query, inZoneWithID: zoneID) { (records, error) in
                if records == nil {
                    d.reject(error)
                } else if records.isEmpty {
                    let info = [NSLocalizedDescriptionKey: "No such record found for query: \(query)"]
                    let error = NSError(domain: PMKErrorDomain, code: NoSuchRecord, userInfo: info)
                    d.reject(error)
                } else {
                    d.fulfill(records[0] as CKRecord)
                }
            }
        }
    }
}
