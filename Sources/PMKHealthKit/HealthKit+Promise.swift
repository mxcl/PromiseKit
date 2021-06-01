#if !os(tvOS) && canImport(HealthKit)

#if !PMKCocoaPods
import PromiseKit
#endif
import HealthKit

public extension HKHealthStore {
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?) -> Promise<Bool> {
        return Promise { seal in
            requestAuthorization(toShare: typesToShare, read: typesToRead, completion: seal.resolve)
        }
    }

#if os(iOS)
    func enableBackgroundDelivery(for type: HKObjectType, frequency: HKUpdateFrequency) -> Promise<Bool> {
        return Promise { seal in
            enableBackgroundDelivery(for: type, frequency: frequency, withCompletion: seal.resolve)
        }
    }
#endif
}

public extension HKStatisticsQuery {
    static func promise(quantityType: HKQuantityType, quantitySamplePredicate: NSPredicate? = nil, options: HKStatisticsOptions = [], healthStore: HKHealthStore = .init()) -> Promise<HKStatistics> {
        return Promise { seal in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantitySamplePredicate, options: options) {
                seal.resolve($1, $2)
            }
            healthStore.execute(query)
        }
    }
}

public extension HKAnchoredObjectQuery {
    static func promise(type: HKSampleType, predicate: NSPredicate? = nil, anchor: HKQueryAnchor? = nil, limit: Int = HKObjectQueryNoLimit, healthStore: HKHealthStore = .init()) -> Promise<([HKSample], [HKDeletedObject], HKQueryAnchor)> {
        return Promise { seal in
            let query = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: anchor, limit: limit) {
                if let a = $1, let b = $2, let c = $3 {
                    seal.fulfill((a, b, c))
                } else if let e = $4 {
                    seal.reject(e)
                } else {
                    seal.reject(PMKError.invalidCallingConvention)
                }
            }
            healthStore.execute(query)
        }
    }

}

public extension HKStatisticsCollectionQuery {
    func promise(healthStore: HKHealthStore = .init()) -> Promise<HKStatisticsCollection> {
        return Promise { seal in
            initialResultsHandler = {
                seal.resolve($1, $2)
            }
            healthStore.execute(self)
        }
    }
}

public extension HKSampleQuery {
    static func promise(sampleType: HKSampleType, predicate: NSPredicate? = nil, limit: Int = HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor]? = nil, healthStore: HKHealthStore = .init()) -> Promise<[HKSample]> {
        return Promise { seal in
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) {
                seal.resolve($1, $2)
            }
            healthStore.execute(query)
        }
    }
}

@available(iOS 9.3, iOSApplicationExtension 9.3, watchOSApplicationExtension 2.2, *)
public extension HKActivitySummaryQuery {
    static func promise(predicate: NSPredicate, healthStore: HKHealthStore = .init()) -> Promise<[HKActivitySummary]> {
        return Promise { seal in
            let query = HKActivitySummaryQuery(predicate: predicate) {
                seal.resolve($1, $2)
            }
            healthStore.execute(query)
        }
    }
}

#endif
