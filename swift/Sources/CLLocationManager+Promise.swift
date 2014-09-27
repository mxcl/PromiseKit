import CoreLocation.CLLocationManager

private class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    let fulfiller: ([CLLocation]) -> Void
    let rejecter: (NSError) -> Void

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        fulfiller(locations as [CLLocation])
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        rejecter(error)
    }

    init(_ fulfiller: ([CLLocation]) -> Void, _ rejecter: (NSError) -> Void) {
        self.fulfiller = fulfiller
        self.rejecter = rejecter
        super.init()
        PMKRetain(self)
        delegate = self
        requestWhenInUseAuthorization()
    }
}

extension CLLocationManager {
    /**
      Returns the most recent CLLocation.
     */
    public class func promise() -> Promise<CLLocation> {
        return promise().then { (locations: [CLLocation]) -> CLLocation in
            return last(locations)!
        }
    }

    public class func promise() -> Promise<[CLLocation]> {
        let deferred = Promise<[CLLocation]>.defer()
        let manager = LocationManager(deferred.fulfiller, deferred.rejecter)
        manager.startUpdatingLocation()
        deferred.promise.finally {
            manager.delegate = nil
            manager.stopUpdatingLocation()
            PMKRelease(manager)
        }
        return deferred.promise
    }
}
