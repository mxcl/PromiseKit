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

private class AuthorizationCatcher: CLLocationManager, CLLocationManagerDelegate {
    let fulfill: (CLAuthorizationStatus) -> Void

    init(_ fulfill: (CLAuthorizationStatus)->()) {
        self.fulfill = fulfill
        super.init()
        let status = CLLocationManager.authorizationStatus()
        if status == .NotDetermined {
            self.delegate = self
            PMKRetain(self)
            requestAlwaysAuthorization()
        } else {
            fulfill(status)
        }
    }

    private func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .NotDetermined {
            fulfill(status)
            PMKRelease(self)
        }
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
        let manager = LocationManager(deferred.fulfill, deferred.reject)
        manager.startUpdatingLocation()
        deferred.promise.finally {
            manager.delegate = nil
            manager.stopUpdatingLocation()
            PMKRelease(manager)
        }
        return deferred.promise
    }

    /**
      Cannot error, despite the fact this might be more useful in some
      circumstances, we stick with our decision that errors are errors
      and errors only. Thus your catch handler is always catching failures
      and not being abused for logic.
     */
    public class func requestAlwaysAuthorization() -> Promise<CLAuthorizationStatus> {
        let d = Promise<CLAuthorizationStatus>.defer()
        AuthorizationCatcher(d.fulfill)
        return d.promise
    }
}
