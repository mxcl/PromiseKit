import MapKit
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `MKDirections` category:

    use_frameworks!
    pod "PromiseKit/MapKit"

 And then in your sources:

    import PromiseKit
*/
extension MKDirections {
    /**
     Calling cancel on an MKDirections instance does nothing. The API is a
     lie. Consequently this PromiseKit extension does not support
     cancellation.
    */
    public func promise() -> Promise<MKDirectionsResponse> {
        return Promise { calculateDirectionsWithCompletionHandler($0) }
    }

    public func promise() -> Promise<MKETAResponse> {
        return Promise { calculateETAWithCompletionHandler($0) }
    }
}
