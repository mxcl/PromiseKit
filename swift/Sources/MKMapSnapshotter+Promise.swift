import MapKit

extension MKMapSnapshotter {
    public func promise() -> Promise<MKMapSnapshot> {
        return Promise { (fulfiller, rejecter) in
            self.startWithCompletionHandler {
                if $1 != nil {
                    rejecter($1)
                } else {
                    fulfiller($0)
                }
            }
        }
    }
}
