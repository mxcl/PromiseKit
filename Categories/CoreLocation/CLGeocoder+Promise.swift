import CoreLocation.CLGeocoder
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `CLGeocoder` category:

    use_frameworks!
    pod "PromiseKit/CoreLocation"

 And then in your sources:

    import PromiseKit
*/
extension CLGeocoder {
    public func reverseGeocodeLocation(location: CLLocation) -> PlacemarkPromise {
        return PlacemarkPromise.go { resolve in
            reverseGeocodeLocation(location, completionHandler: resolve)
        }
    }
    
    public func geocode(addressDictionary: [String: String]) -> PlacemarkPromise {
        return PlacemarkPromise.go { resolve in
            geocodeAddressDictionary(addressDictionary, completionHandler: resolve)
        }
    }
    
    public func geocode(addressString: String) -> PlacemarkPromise {
        return PlacemarkPromise.go { resolve in
            geocodeAddressString(addressString, completionHandler: resolve)
        }
    }
    
    public func geocode(addressString: String, region: CLRegion?) -> PlacemarkPromise {
        return PlacemarkPromise.go { resolve in
            geocodeAddressString(addressString, inRegion: region, completionHandler: resolve)
        }
    }
}

extension CLError: CancellableErrorType {
    public var cancelled: Bool {
        return self == .GeocodeCanceled
    }
}

public class PlacemarkPromise: Promise<CLPlacemark> {

    public func allResults() -> Promise<[CLPlacemark]> {
        return then(on: zalgo) { _ in return self.placemarks }
    }

    private var placemarks: [CLPlacemark]!

    private class func go(@noescape body: (([CLPlacemark]?, NSError?) -> Void) -> Void) -> PlacemarkPromise {
        var promise: PlacemarkPromise!
        promise = PlacemarkPromise { fulfill, reject in
            body { placemarks, error in
                if let error = error {
                    reject(error)
                } else {
                    promise.placemarks = placemarks
                    fulfill(placemarks!.first!)
                }
            }
        }
        return promise
    }

    private override init(@noescape resolvers: (fulfill: (CLPlacemark) -> Void, reject: (ErrorType) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }
}
