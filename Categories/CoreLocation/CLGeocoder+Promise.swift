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
    public func reverseGeocodeLocation(location: CLLocation) -> Promise<CLPlacemark> {
        return Promise { resolve in
            reverseGeocodeLocation(location) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressDictionary: [String: String]) -> Promise<CLPlacemark> {
        return Promise { resolve in
            geocodeAddressDictionary(addressDictionary) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressString: String) -> Promise<CLPlacemark> {
        return Promise { resolve in
            geocodeAddressString(addressString) { placemarks, error in
                resolve(placemarks?.first, error)
            }
        }
    }
    
    public func geocode(addressString: String, region: CLRegion?) -> Promise<[CLPlacemark]> {
        return Promise { resolve in
            geocodeAddressString(addressString, inRegion: region) { placemarks, error in
                resolve(placemarks, error)
            }
        }
    }
}

extension CLError: CancellableErrorType {
    public var cancelled: Bool {
        return self == .GeocodeCanceled
    }
}
