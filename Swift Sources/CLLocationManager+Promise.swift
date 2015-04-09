import CoreLocation.CLLocationManager

private class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    let fulfiller: ([CLLocation]) -> Void
    let rejecter: (NSError) -> Void

    @objc func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        fulfiller(locations as! [CLLocation])
    }

    @objc func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        rejecter(error)
    }

    init(_ fulfiller: ([CLLocation]) -> Void, _ rejecter: (NSError) -> Void) {
        self.fulfiller = fulfiller
        self.rejecter = rejecter
        super.init()
        PMKRetain(self)
        delegate = self
    }
}

private class AuthorizationCatcher: CLLocationManager, CLLocationManagerDelegate {
    let fulfill: (CLAuthorizationStatus) -> Void

    init(fulfiller: (CLAuthorizationStatus)->(), auther: (CLLocationManager)->()) {
        fulfill = fulfiller
        super.init()
        let status = CLLocationManager.authorizationStatus()
        if status == .NotDetermined {
            delegate = self
            PMKRetain(self)
            auther(self)
        } else {
            fulfill(status)
        }
    }

    @objc func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .NotDetermined {
            fulfill(status)
            PMKRelease(self)
        }
    }
}


private func auther(requestAuthorizationType: CLLocationManager.RequestAuthorizationType)(manager: CLLocationManager)
{
    func hasInfoPListKey(key: String) -> Bool {
        let value = NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationAlwaysUsageDescription") as? String ?? ""
        return !value.isEmpty
    }

  #if os(iOS)
    switch requestAuthorizationType {
    case .Automatic:
        let always = hasInfoPListKey("NSLocationAlwaysUsageDescription")
        let whenInUse = hasInfoPListKey("NSLocationWhenInUseUsageDescription")
        if hasInfoPListKey("NSLocationAlwaysUsageDescription") {
            manager.requestAlwaysAuthorization()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    case .WhenInUse:

        manager.requestWhenInUseAuthorization()
        break
    case .Always:
        manager.requestAlwaysAuthorization()
        break

    }
  #endif
}


extension CLLocationManager {

    public enum RequestAuthorizationType {
        case Automatic
        case Always
        case WhenInUse
    }
  
    /**
      Returns the most recent CLLocation.

      @param requestAuthorizationType We read your Info plist and try to
      determine the authorization type we should request automatically. If you
      want to force one or the other, change this parameter from its default
      value.
     */
    public class func promise(requestAuthorizationType: RequestAuthorizationType = .Automatic) -> Promise<CLLocation> {
        let p: Promise<[CLLocation]> = promise(requestAuthorizationType: requestAuthorizationType)
        return p.then { (locations)->CLLocation in
            return locations[locations.count - 1]
        }
    }

    /**
      Returns the first batch of location objects a CLLocationManager instance
      provides.
     */
    public class func promise(requestAuthorizationType: RequestAuthorizationType = .Automatic) -> Promise<[CLLocation]> {
        return promise(yield: auther(requestAuthorizationType))
    }

    private class func promise(yield: (CLLocationManager)->() = { _ in }) -> Promise<[CLLocation]> {
        let deferred = Promise<[CLLocation]>.defer()
        let manager = LocationManager(deferred.fulfill, deferred.reject)
        yield(manager)
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
    public class func requestAuthorization(type: RequestAuthorizationType = .Automatic) -> Promise<CLAuthorizationStatus> {
        let d = Promise<CLAuthorizationStatus>.defer()
        AuthorizationCatcher(fulfiller: d.fulfill, auther: auther(type))
        return d.promise
    }

    @availability(*, deprecated=1.3.0)
    public class func requestAlwaysAuthorization() -> Promise<CLAuthorizationStatus> {
        return requestAuthorization(type: .Always)
    }
}
