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
    public func reverseGeocodeLocation(_ location: CLLocation) -> PlacemarkPromise {
        return PlacemarkPromise.go { resolve in
            reverseGeocodeLocation(location, completionHandler: resolve)
        }
    }
    
    public func geocode(_ addressDictionary: [String: String]) -> PlacemarkPromise {
        return PlacemarkPromise.go { resolve in
            geocodeAddressDictionary(addressDictionary, completionHandler: resolve)
        }
    }
    
    public func geocode(_ addressString: String) -> PlacemarkPromise {
        return PlacemarkPromise.go { resolve in
            geocodeAddressString(addressString, completionHandler: resolve)
        }
    }
    
    public func geocode(_ addressString: String, region: CLRegion?) -> PlacemarkPromise {
        return PlacemarkPromise.go { resolve in
            geocodeAddressString(addressString, in: region, completionHandler: resolve)
        }
    }
}

extension CLError: CancellableError {
    public var isCancelled: Bool {
        return self == .geocodeCanceled
    }
}

public class PlacemarkPromise: Promise<CLPlacemark> {

    public func allResults() -> Promise<[CLPlacemark]> {
        return then(on: zalgo) { _ in return self.placemarks }
    }

    private var placemarks: [CLPlacemark]!

    private class func go(_ body: @noescape (([CLPlacemark]?, NSError?) -> Void) -> Void) -> PlacemarkPromise {
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

    private override init(resolvers: @noescape (fulfill: (CLPlacemark) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }
}
