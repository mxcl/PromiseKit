#if canImport(MapKit) && !os(watchOS)

#if !PMKCocoaPods
import PromiseKit
#endif
import MapKit

/**
     import PMKMapKit
*/
extension MKMapSnapshotter {
    /// Starts generating the snapshot using the options set in this object.
    public func start() -> Promise<MKMapSnapshotter.Snapshot> {
        return Promise { start(completionHandler: $0.resolve) }
    }
}

#endif
