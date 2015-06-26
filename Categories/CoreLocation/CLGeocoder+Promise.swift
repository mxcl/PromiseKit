import CoreLocation.CLGeocoder
import PromiseKit

/**
 To import the `CLGeocoder` category:

    use_frameworks!
    pod "PromiseKit/CoreLocation"

 And then in your sources:

    import PromiseKit
*/
extension CLGeocoder {
    public func reverseGeocodeLocation(location: CLLocation) -> Promise<CLPlacemark> {
        return CLPromise { resolve in
            reverseGeocodeLocation(location) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressDictionary: [String: String]) -> Promise<CLPlacemark> {
        return CLPromise { resolve in
            geocodeAddressDictionary(addressDictionary) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressString: String) -> Promise<CLPlacemark> {
        return CLPromise { resolve in
            geocodeAddressString(addressString) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressString: String, region: CLRegion?) -> Promise<[CLPlacemark]> {
        return CLPromise { resolve in
            geocodeAddressString(addressString, inRegion: region) { placemarks, error in
                resolve(placemarks, error)
            }
        }
    }
}

private var onceToken: dispatch_once_t = 0

private class CLPromise<T>: Promise<T> {
    override init(@noescape resolver: ((T?, NSError?) -> Void) throws -> Void) {
        dispatch_once(&onceToken) {
            NSError.registerCancelledErrorDomain(kCLErrorDomain, code: CLError.GeocodeCanceled.rawValue)
        }
        super.init(resolver: resolver)
    }
}
