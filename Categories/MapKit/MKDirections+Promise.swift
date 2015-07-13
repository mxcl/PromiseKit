import MapKit

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
        return Promise<MKDirectionsResponse>(sealant: { (sealant: Sealant<MKDirectionsResponse>) -> Void in
            self.calculateDirectionsWithCompletionHandler(sealant.resolve)
        })
    }

    public func promise() -> Promise<MKETAResponse> {
        return Promise<MKETAResponse> { self.calculateETAWithCompletionHandler($0.resolve) }
    }
}
