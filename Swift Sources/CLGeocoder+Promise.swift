import CoreLocation.CLGeocoder


extension CLGeocoder {
    public class func reverseGeocode(location: CLLocation) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().reverseGeocodeLocation(location) {
                if $1 != nil {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as! CLPlacemark)
                }
            }
        }
    }

    public class func geocode(#addressDictionary: [String:String]) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().geocodeAddressDictionary(addressDictionary) {
                if $1 != nil {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as! CLPlacemark)
                }
            }
        }
    }

    public class func geocode(#addressString: String) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().geocodeAddressString(addressString) {
                if $1 != nil {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as! CLPlacemark)
                }
            }
        }
    }
}
