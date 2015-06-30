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
        return CLPromise { sealant in
            reverseGeocodeLocation(location) { placemarks, error in
                sealant.resolve((placemarks as? [CLPlacemark])?.first, error)
            }
        }
    }
    
    public func geocode(addressDictionary: [String: String]) -> Promise<CLPlacemark> {
        return CLPromise { sealant in
            geocodeAddressDictionary(addressDictionary) { placemarks, error in
                sealant.resolve((placemarks as? [CLPlacemark])?.first, error)
            }
        }
    }
    
    public func geocode(addressString: String) -> Promise<CLPlacemark> {
        return CLPromise { sealant in
            geocodeAddressString(addressString) { placemarks, error in
                sealant.resolve((placemarks as? [CLPlacemark])?.first, error)
            }
        }
    }
    
    public func geocode(addressString: String, region: CLRegion?) -> Promise<[CLPlacemark]> {
        return CLPromise { sealant in
            geocodeAddressString(addressString, inRegion: region) { placemarks, error in
                sealant.resolve((placemarks as? [CLPlacemark]), error)
            }
        }
    }
}

private var onceToken: dispatch_once_t = 0

private class CLPromise<T>: Promise<T> {
    override init(@noescape sealant: (Sealant<T>) -> Void) {
        dispatch_once(&onceToken) {
            NSError.registerCancelledErrorDomain(kCLErrorDomain, code: CLError.GeocodeCanceled.rawValue)
        }
        super.init(sealant: sealant)
    }
}
