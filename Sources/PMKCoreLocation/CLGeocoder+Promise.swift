#if canImport(CoreLocation)

import CoreLocation.CLGeocoder
#if !PMKCocoaPods
import PromiseKit
#endif
#if os(iOS) || os(watchOS) || os(macOS)
import class Contacts.CNPostalAddress
#endif

/**
 To import the `CLGeocoder` category:

    use_frameworks!
    pod "PromiseKit/CoreLocation"

 And then in your sources:

    import PromiseKit
*/
extension CLGeocoder {
    /// Submits a reverse-geocoding request for the specified location.
    public func reverseGeocode(location: CLLocation) -> Promise<[CLPlacemark]> {
        return Promise { seal in
            reverseGeocodeLocation(location, completionHandler: seal.resolve)
        }
    }

    /// Submits a forward-geocoding request using the specified address dictionary.
    @available(iOS, deprecated: 11.0)
    public func geocode(_ addressDictionary: [String: String]) -> Promise<[CLPlacemark]> {
        return Promise { seal in
            geocodeAddressDictionary(addressDictionary, completionHandler: seal.resolve)
        }
    }

    /// Submits a forward-geocoding request using the specified address string.
    public func geocode(_ addressString: String) -> Promise<[CLPlacemark]> {
        return Promise { seal in
            geocodeAddressString(addressString, completionHandler: seal.resolve)
        }
    }

    /// Submits a forward-geocoding request using the specified address string within the specified region.
    public func geocode(_ addressString: String, region: CLRegion?) -> Promise<[CLPlacemark]> {
        return Promise { seal in
            geocodeAddressString(addressString, in: region, completionHandler: seal.resolve)
        }
    }

#if !os(tvOS) && swift(>=3.2)
    /// Submits a forward-geocoding request using the specified postal address.
    @available(iOS 11.0, OSX 10.13, watchOS 4.0, *)
    public func geocodePostalAddress(_ postalAddress: CNPostalAddress) -> Promise<[CLPlacemark]> {
        return Promise { seal in
            geocodePostalAddress(postalAddress, completionHandler: seal.resolve)
        }
    }

    /// Submits a forward-geocoding requesting using the specified locale and postal address
    @available(iOS 11.0, OSX 10.13, watchOS 4.0, *)
    public func geocodePostalAddress(_ postalAddress: CNPostalAddress, preferredLocale locale: Locale?) -> Promise<[CLPlacemark]> {
        return Promise { seal in
            geocodePostalAddress(postalAddress, preferredLocale: locale, completionHandler: seal.resolve)
        }
    }

    /// Submits a reverse-geocoding request for the specified location and a preferred locale.
    @available(iOS 11.0, OSX 10.13, watchOS 4.0, *)
    public func reverseGeocode(location: CLLocation, preferredLocale locale: Locale?) -> Promise<[CLPlacemark]> {
        return Promise { seal in
            reverseGeocodeLocation(location, preferredLocale: locale, completionHandler: seal.resolve)
        }
    }
#endif
}

// TODO still not possible in Swift 3.2
//extension CLError: CancellableError {
//    public var isCancelled: Bool {
//        return self == .geocodeCanceled
//    }
//}

#endif
