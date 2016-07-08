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
        case automatic
        case always
        case whenInUse
    }

    private class func promiseDoneForLocationManager(_ manager: CLLocationManager) -> Void {
        manager.delegate = nil
        manager.stopUpdatingLocation()
    }
  
    /**
      @return A new promise that fulfills with the most recent CLLocation.

      @param requestAuthorizationType We read your Info plist and try to
      determine the authorization type we should request automatically. If you
      want to force one or the other, change this parameter from its default
      value.
     */
    public class func promise(_ requestAuthorizationType: RequestAuthorizationType = .automatic) -> LocationPromise {
        return promise(yielding: auther(requestAuthorizationType))
    }

    private class func promise(yielding yield: (CLLocationManager) -> Void = { _ in }) -> LocationPromise {
        let manager = LocationManager()
        manager.delegate = manager
        yield(manager)
        manager.startUpdatingLocation()
        manager.promise.always {
            CLLocationManager.promiseDoneForLocationManager(manager)
        }
        return manager.promise
    }
}

private class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    let (promise, fulfill, reject) = LocationPromise.foo()

    @objc private func locationManager(_ manager: CLLocationManager, didUpdateLocations ll: [CLLocation]) {
        let locations = ll 
        fulfill(locations)
        CLLocationManager.promiseDoneForLocationManager(manager)
    }

    @objc func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        reject(error)
        CLLocationManager.promiseDoneForLocationManager(manager)
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
    public class func requestAuthorization(type: RequestAuthorizationType = .automatic) -> Promise<CLAuthorizationStatus> {
        return AuthorizationCatcher(auther: auther(type)).promise
    }
}

@available(iOS 8, *)
private class AuthorizationCatcher: CLLocationManager, CLLocationManagerDelegate {
    let (promise, fulfill, _) = Promise<CLAuthorizationStatus>.pending()
    var retainCycle: AnyObject?

    init(auther: (CLLocationManager)->()) {
        super.init()
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            delegate = self
            auther(self)
            retainCycle = self
        } else {
            fulfill(status)
        }
    }

    @objc private func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .notDetermined {
            fulfill(status)
            retainCycle = nil
        }
    }
}

private func auther(_ requestAuthorizationType: CLLocationManager.RequestAuthorizationType) -> ((CLLocationManager) -> Void) {

    //PMKiOS7 guard #available(iOS 8, *) else { return }
    return { manager in
        func hasInfoPlistKey(_ key: String) -> Bool {
            let value = Bundle.main.objectForInfoDictionaryKey(key) as? String ?? ""
            return !value.isEmpty
        }

        switch requestAuthorizationType {
        case .automatic:
            let always = hasInfoPlistKey("NSLocationAlwaysUsageDescription")
            let whenInUse = hasInfoPlistKey("NSLocationWhenInUseUsageDescription")
            if always {
                manager.requestAlwaysAuthorization()
            } else {
                if !whenInUse { NSLog("PromiseKit: Warning: `NSLocationWhenInUseUsageDescription` key not set") }
                manager.requestWhenInUseAuthorization()
            }
        case .whenInUse:
            manager.requestWhenInUseAuthorization()
            break
        case .always:
            manager.requestAlwaysAuthorization()
            break

        }
    }
}

#else

private func auther(_ requestAuthorizationType: CLLocationManager.RequestAuthorizationType) -> (CLLocationManager) -> Void {
    return { _ in }
}

#endif


public class LocationPromise: Promise<CLLocation> {
    // convoluted for concurrency guarantees
    private let (parentPromise, fulfill, reject) = Promise<[CLLocation]>.pending()

    public func allResults() -> Promise<[CLLocation]> {
        return parentPromise
    }

    private class func foo() -> (LocationPromise, ([CLLocation]) -> Void, (ErrorProtocol) -> Void) {
        var fulfill: ((CLLocation) -> Void)!
        var reject: ((ErrorProtocol) -> Void)!
        let promise = LocationPromise { fulfill = $0; reject = $1 }

        promise.parentPromise.then(on: zalgo) { fulfill($0.last!) }
        promise.parentPromise.catch(on: zalgo, execute: reject)

        return (promise, promise.fulfill, promise.reject)
    }

    private override init(resolvers: @noescape (fulfill: (CLLocation) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }
}
