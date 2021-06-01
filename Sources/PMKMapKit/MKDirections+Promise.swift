#if canImport(MapKit) && !os(watchOS)

#if !PMKCocoaPods
import PromiseKit
#endif
import MapKit

/**
    import PMKMapKit
*/
public extension MKDirections {
    /// Begins calculating the requested route information asynchronously.
    func calculate() -> Promise<Response> {
        return Promise { calculate(completionHandler: $0.resolve) }
    }

    /// Begins calculating the requested travel-time information asynchronously.
    func calculateETA() -> Promise<ETAResponse> {
        return Promise { calculateETA(completionHandler: $0.resolve) }
    }
}

#endif
