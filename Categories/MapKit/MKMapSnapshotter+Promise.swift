import MapKit
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `MKMapSnapshotter` category:

    use_frameworks!
    pod "PromiseKit/MapKit"

 And then in your sources:

    import PromiseKit
*/
extension MKMapSnapshotter {
    /**
      Don’t cancel the Snapshotter, Apple never call the completionHandler if
      you do. Which means the promise will never resolve.
     */
    public func promise() -> Promise<MKMapSnapshot> {
        return Promise { startWithCompletionHandler($0) }
    }
}
