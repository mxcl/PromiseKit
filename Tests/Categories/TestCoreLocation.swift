import CoreLocation
import PromiseKit
import XCTest

class TestCLLocationManager: XCTestCase {
    func testLocation() {
        swizzle(CLLocationManager.self, "startUpdatingLocation") {
            let ex = expectationWithDescription("")

            CLLocationManager.promise().then { (x: CLLocation) -> Void in
                XCTAssertEqual(x, dummy.last!)
                ex.fulfill()
            }

            waitForExpectationsWithTimeout(1, handler: nil)
        }
    }

    func testLocations() {
        swizzle(CLLocationManager.self, "startUpdatingLocation") {
            let ex = expectationWithDescription("")

            CLLocationManager.promise().then { (x: [CLLocation]) -> Void in
                XCTAssertEqual(x, dummy)
                ex.fulfill()
            }

            waitForExpectationsWithTimeout(1, handler: nil)
        }
    }

    func testRequestAuthorization() {
        #if os(iOS)
            swizzle(CLLocationManager.self, "requestWhenInUseAuthorization") {
                swizzle(CLLocationManager.self, "authorizationStatus", isClassMethod: true) {
                    let ex = expectationWithDescription("")

                    CLLocationManager.requestAuthorization().then { x -> Void in
                        XCTAssertEqual(x, .AuthorizedWhenInUse)
                        ex.fulfill()
                    }

                    waitForExpectationsWithTimeout(1, handler: nil)
                }
            }
        #endif
    }
}

private let dummyPlacemark = CLPlacemark()

class TestCLGeocoder: XCTestCase {
    func testReverseGeocodeLocation() {
        class MockGeocoder: CLGeocoder {
            private override func reverseGeocodeLocation(location: CLLocation, completionHandler: CLGeocodeCompletionHandler) {
                completionHandler([dummyPlacemark], nil)
            }
        }

        let ex = expectationWithDescription("")
        MockGeocoder().reverseGeocodeLocation(CLLocation()).then { x -> Void in
            XCTAssertEqual(x, dummyPlacemark)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testGeocodeAddressDictionary() {
        class MockGeocoder: CLGeocoder {
            private override func geocodeAddressDictionary(addressDictionary: [NSObject : AnyObject], completionHandler: CLGeocodeCompletionHandler) {
                completionHandler([dummyPlacemark], nil)
            }
        }

        let ex = expectationWithDescription("")
        MockGeocoder().geocode([:]).then { x -> Void in
            XCTAssertEqual(x, dummyPlacemark)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testGeocodeAddressString() {
        class MockGeocoder: CLGeocoder {
            override func geocodeAddressString(addressString: String, completionHandler: CLGeocodeCompletionHandler) {
                completionHandler([dummyPlacemark], nil)
            }
        }

        let ex = expectationWithDescription("")
        MockGeocoder().geocode("").then { x -> Void in
            XCTAssertEqual(x, dummyPlacemark)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}



/////////////////////////////////////////////////////////////// resources

func swizzle(foo: AnyClass, _ from: Selector, isClassMethod: Bool = false, @noescape body: () -> Void) {
    let get: (AnyClass!, Selector) -> Method = isClassMethod ? class_getClassMethod : class_getInstanceMethod
    let originalMethod = get(foo, from)
    let swizzledMethod = get(foo, Selector("pmk_\(from)"))

    method_exchangeImplementations(originalMethod, swizzledMethod)
    body()
    method_exchangeImplementations(swizzledMethod, originalMethod)
}

private let dummy = [CLLocation(latitude: 0, longitude: 0), CLLocation(latitude: 10, longitude: 20)]

extension CLLocationManager {
    @objc func pmk_startUpdatingLocation() {
        after(0.1).then {
            self.delegate!.locationManager?(self, didUpdateLocations: dummy)
        }
    }

    #if os(iOS)
    @objc func pmk_requestWhenInUseAuthorization() {
        after(0.1).then {
            self.delegate!.locationManager?(self, didChangeAuthorizationStatus: .AuthorizedWhenInUse)
        }
    }

    class func pmk_authorizationStatus() -> CLAuthorizationStatus {
        return .NotDetermined
    }
    #endif
}
