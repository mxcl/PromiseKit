import CoreLocation.CLLocationManager
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `CLLocationManager` category:

    use_frameworks!
    pod "PromiseKit/CoreLocation"

 And then in your sources:

    import PromiseKit
*/
extension CLLocationManager {

    public enum RequestAuthorizationType {
        case Automatic
        case Always
        case WhenInUse
    }
  
    /**
      @return A new promise that fulfills with the most recent CLLocation.

      @param requestAuthorizationType We read your Info plist and try to
      determine the authorization type we should request automatically. If you
      want to force one or the other, change this parameter from its default
      value.
     */
    public class func promise(requestAuthorizationType: RequestAuthorizationType = .Automatic) -> Promise<CLLocation> {
        return promiseAll(requestAuthorizationType).then(on: zalgo) { $0.last! }
    }

    /**
      @return A new promise that fulfills with the first batch of location objects a CLLocationManager instance provides.
     */
    public class func promiseAll(requestAuthorizationType: RequestAuthorizationType = .Automatic) -> Promise<[CLLocation]> {
        return promise(yielding: auther(requestAuthorizationType))
    }

    private class func promise(yielding yield: (CLLocationManager) -> Void = { _ in }) -> Promise<[CLLocation]> {
        let manager = LocationManager()
        manager.delegate = manager
        yield(manager)
        manager.startUpdatingLocation()
        manager.promise.ensure {
            manager.delegate = nil
            manager.stopUpdatingLocation()
        }
        return manager.promise
    }
}

private class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    let (promise, fulfill, reject) = Promise<[CLLocation]>.pendingPromise()

#if os(iOS)
    @objc func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        fulfill(locations)
    }
#else
    @objc func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        fulfill(locations as! [CLLocation])
    }
#endif

    @objc func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        reject(error)
    }
}


#if os(iOS)

extension CLLocationManager {
    /**
     Cannot error, despite the fact this might be more useful in some
     circumstances, we stick with our decision that errors are errors
     and errors only. Thus your catch handler is always catching failures
     and not being abused for logic.
    */
    @available(iOS 8, *)
    public class func requestAuthorization(type: RequestAuthorizationType = .Automatic) -> Promise<CLAuthorizationStatus> {
        return AuthorizationCatcher(auther: auther(type)).promise
    }
}

@available(iOS 8, *)
private class AuthorizationCatcher: CLLocationManager, CLLocationManagerDelegate {
    let (promise, fulfill, _) = Promise<CLAuthorizationStatus>.pendingPromise()
    var retainCycle: AnyObject?

    init(auther: (CLLocationManager)->()) {
        super.init()
        let status = CLLocationManager.authorizationStatus()
        if status == .NotDetermined {
            delegate = self
            auther(self)
            retainCycle = self
        } else {
            fulfill(status)
        }
    }

    @objc private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .NotDetermined {
            fulfill(status)
            retainCycle = nil
        }
    }
}

private func auther(requestAuthorizationType: CLLocationManager.RequestAuthorizationType)(manager: CLLocationManager) {

    //PMKiOS7 guard #available(iOS 8, *) else { return }

    func hasInfoPListKey(key: String) -> Bool {
        let value = NSBundle.mainBundle().objectForInfoDictionaryKey(key) as? String ?? ""
        return !value.isEmpty
    }

    switch requestAuthorizationType {
    case .Automatic:
        let always = hasInfoPListKey("NSLocationAlwaysUsageDescription")
        let whenInUse = hasInfoPListKey("NSLocationWhenInUseUsageDescription")
        if always {
            manager.requestAlwaysAuthorization()
        } else {
            if !whenInUse { NSLog("PromiseKit: Warning: `NSLocationWhenInUseUsageDescription` key not set") }
            manager.requestWhenInUseAuthorization()
        }
    case .WhenInUse:
        manager.requestWhenInUseAuthorization()
        break
    case .Always:
        manager.requestAlwaysAuthorization()
        break

    }
}

#else
    private func auther(requestAuthorizationType: CLLocationManager.RequestAuthorizationType)(manager: CLLocationManager)
    {}
#endif
