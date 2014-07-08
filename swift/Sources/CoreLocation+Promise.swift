import CoreLocation


class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    let fulfiller: (CLLocation) -> Void
    let rejecter: (NSError) -> Void

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let mostRecentLocation = (locations as NSArray).lastObject as CLLocation
        fulfiller(mostRecentLocation)
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        rejecter(error)
    }

    init(deferred:(_:Promise<CLLocation>, (CLLocation) -> Void, rejecter: (NSError) -> Void)) {
        fulfiller = deferred.1
        rejecter = deferred.2
        super.init()
        PMKRetain(self)
        delegate = self
        requestWhenInUseAuthorization()
    }
}

extension CLLocationManager {
    class func promise() -> Promise<CLLocation> {
        let deferred = Promise<CLLocation>.defer()
        let manager = LocationManager(deferred: deferred)
        manager.startUpdatingLocation()
        deferred.promise.finally {
            manager.delegate = nil
            manager.stopUpdatingLocation()
            PMKRelease(manager)
        }
        return deferred.promise
    }
}

extension CLGeocoder {
    class func reverseGeocode(location:CLLocation) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().reverseGeocodeLocation(location) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as CLPlacemark)
                }
            }
        }
    }

    class func geocode(#addressDictionary:Dictionary<String, String>) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().geocodeAddressDictionary(addressDictionary) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as CLPlacemark)
                }
            }
        }
    }

    class func geocode(#addressString:String) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().geocodeAddressString(addressString) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as CLPlacemark)
                }
            }
        }
    }
}
