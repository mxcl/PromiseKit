import MapKit

extension MKDirections {

    public class func promise(request:MKDirectionsRequest) -> Promise<MKDirectionsResponse> {
        return Promise { (fulfiller, rejecter) in
            MKDirections(request:request).calculateDirectionsWithCompletionHandler {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0)
                }
            }
        }
    }

    public class func promise(request:MKDirectionsRequest) -> Promise<MKETAResponse> {
        return Promise { (fulfiller, rejecter) in
            MKDirections(request:request).calculateETAWithCompletionHandler {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0)
                }
            }
        }
    }
}

extension MKMapSnapshotter {
    public func promise() -> Promise<MKMapSnapshot> {
        return Promise { (fulfiller, rejecter) in
            self.startWithCompletionHandler {
                if ($1) {
                    rejecter($1)
                } else {
                    fulfiller($0)
                }
            }
        }
    }
}
