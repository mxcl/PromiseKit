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
        return go { resolve in
            reverseGeocodeLocation(location) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressDictionary: [String: String]) -> Promise<CLPlacemark> {
        return go { resolve in
            geocodeAddressDictionary(addressDictionary) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressString: String) -> Promise<CLPlacemark> {
        return go { resolve in
            geocodeAddressString(addressString) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressString: String, region: CLRegion?) -> Promise<[CLPlacemark]> {
        return go { resolve in
            geocodeAddressString(addressString, inRegion: region) { placemarks, error in
                resolve(placemarks, error)
            }
        }
    }
}

private var onceToken: dispatch_once_t = 0

private func go<T>(@noescape resolver: ((T?, NSError?) -> Void) throws -> Void) -> Promise<T> {
    dispatch_once(&onceToken) {
        NSError.registerCancelledErrorDomain(kCLErrorDomain, code: CLError.GeocodeCanceled.rawValue)
    }
    return Promise(resolver: resolver)
}
