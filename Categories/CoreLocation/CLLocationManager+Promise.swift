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
    public class func promise(requestAuthorizationType: RequestAuthorizationType = .Automatic) -> LocationPromise {
        return promise(yielding: auther(requestAuthorizationType))
    }

    private class func promise(yielding yield: (CLLocationManager) -> Void = { _ in }) -> LocationPromise {
        let manager = LocationManager()
        manager.delegate = manager
        yield(manager)
        manager.startUpdatingLocation()
        manager.promise.always {
            manager.delegate = nil
            manager.stopUpdatingLocation()
        }
        return manager.promise
    }
}

private class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    let (promise, fulfill, reject) = LocationPromise.foo()

#if os(iOS)
    @objc func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        fulfill(locations)
    }
#else
    @objc func locationManager(manager: CLLocationManager, didUpdateLocations ll: [AnyObject]) {
        let locations = ll as! [CLLocation]
        fulfill(locations)
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

private func auther(requestAuthorizationType: CLLocationManager.RequestAuthorizationType) -> (CLLocationManager -> Void) {

    //PMKiOS7 guard #available(iOS 8, *) else { return }
    return { manager in
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
}

#else
    private func auther(requestAuthorizationType: CLLocationManager.RequestAuthorizationType) -> (CLLocationManager -> Void)
    {
        return { _ in }
    }
#endif


public class LocationPromise: Promise<CLLocation> {

    // convoluted for concurrency guarantees

    private let (parentPromise, fulfill, reject) = Promise<[CLLocation]>.pendingPromise()

    public func allResults() -> Promise<[CLLocation]> {
        return parentPromise
    }

    private class func foo() -> (LocationPromise, ([CLLocation]) -> Void, (ErrorType) -> Void) {
        var fulfill: ((CLLocation) -> Void)!
        var reject: ((ErrorType) -> Void)!
        let promise = LocationPromise { fulfill = $0; reject = $1 }

        promise.parentPromise.then(on: zalgo) { fulfill($0.last!) }
        promise.parentPromise.error { reject($0) }

        return (promise, promise.fulfill, promise.reject)
    }

    private override init(@noescape resolvers: (fulfill: (CLLocation) -> Void, reject: (ErrorType) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }
}
