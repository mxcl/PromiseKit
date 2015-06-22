import CoreLocation.CLLocationManager
import PromiseKit

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
        return promise(requestAuthorizationType: requestAuthorizationType).then(on: zalgo) {
            (locations: [CLLocation]) -> CLLocation in
            return locations.last!
        }
    }

    /**
      @return A new promise that fulfills with the first batch of location objects a CLLocationManager instance provides.
     */
    public class func promise(requestAuthorizationType: RequestAuthorizationType = .Automatic) -> Promise<[CLLocation]> {
        return promise(yield: auther(requestAuthorizationType))
    }

    private class func promise(yield: (CLLocationManager) -> Void = { _ in }) -> Promise<[CLLocation]> {
        let manager = LocationManager()
        manager.delegate = manager
        yield(manager)
        manager.startUpdatingLocation()
        manager.promise.finally {
            manager.delegate = nil
            manager.stopUpdatingLocation()
        }
        return manager.promise
    }

  #if os(iOS)
    /**
      Cannot error, despite the fact this might be more useful in some
      circumstances, we stick with our decision that errors are errors
      and errors only. Thus your catch handler is always catching failures
      and not being abused for logic.
     */
    public class func requestAuthorization(type: RequestAuthorizationType = .Automatic) -> Promise<CLAuthorizationStatus> {
        return AuthorizationCatcher(auther: auther(type)).promise
    }
  #endif
}


//TODO authorizations other than .Authorized should probably error


private class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    let (promise, fulfill, reject) = Promise<[CLLocation]>.defer()

    @objc func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        fulfill(locations as! [CLLocation])
    }

    @objc func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        reject(error)
    }
}

#if os(iOS)
private class AuthorizationCatcher: CLLocationManager, CLLocationManagerDelegate {
    let (promise, fulfill, _) = Promise<CLAuthorizationStatus>.defer()
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

    @objc private func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .NotDetermined {
            fulfill(status)
            retainCycle = nil
        }
    }
}
#endif

private func auther(requestAuthorizationType: CLLocationManager.RequestAuthorizationType)(manager: CLLocationManager)
{
  #if os(iOS)
    if !manager.respondsToSelector("requestWhenInUseAuthorization") { return }

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
            if !whenInUse { NSLog("You didn’t set your NSLocationWhenInUseUsageDescription Info.plist key") }
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

