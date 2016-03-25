import CoreLocation
import PromiseKit
import XCTest

class Test_CLLocationManager_Swift: XCTestCase {
    func test_fulfills_with_one_location() {
        swizzle(CLLocationManager.self, #selector(CLLocationManager.startUpdatingLocation)) {
            let ex = expectationWithDescription("")

            CLLocationManager.promise().then { x -> Void in
                XCTAssertEqual(x, dummy.last!)
                ex.fulfill()
            }

            waitForExpectationsWithTimeout(1, handler: nil)
        }
    }

    func test_fulfills_with_multiple_locations() {
        swizzle(CLLocationManager.self, #selector(CLLocationManager.startUpdatingLocation)) {
            let ex = expectationWithDescription("")

            CLLocationManager.promise().allResults().then { x -> Void in
                XCTAssertEqual(x, dummy)
                ex.fulfill()
            }

            waitForExpectationsWithTimeout(1, handler: nil)
        }
    }

    func test_requestAuthorization() {
        #if os(iOS)
            swizzle(CLLocationManager.self, #selector(CLLocationManager.requestWhenInUseAuthorization)) {
                swizzle(CLLocationManager.self, #selector(CLLocationManager.authorizationStatus), isClassMethod: true) {
                    let ex = expectationWithDescription("")

                    CLLocationManager.requestAuthorization().then { x -> Void in
                        XCTAssertEqual(x, CLAuthorizationStatus.AuthorizedWhenInUse)
                        ex.fulfill()
                    }

                    waitForExpectationsWithTimeout(1, handler: nil)
                }
            }
        #endif
    }
}

class Test_CLGeocoder_Swift: XCTestCase {
    func test_reverseGeocodeLocation() {
        class MockGeocoder: CLGeocoder {
            private override func reverseGeocodeLocation(location: CLLocation, completionHandler: CLGeocodeCompletionHandler) {
                after(0.0).then {
                    completionHandler([dummyPlacemark], nil)
                }
            }
        }

        let ex = expectationWithDescription("")
        MockGeocoder().reverseGeocodeLocation(CLLocation()).then { x -> Void in
            XCTAssertEqual(x, dummyPlacemark)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_geocodeAddressDictionary() {
        class MockGeocoder: CLGeocoder {
            private override func geocodeAddressDictionary(addressDictionary: [NSObject : AnyObject], completionHandler: CLGeocodeCompletionHandler) {
                after(0.0).then {
                    completionHandler([dummyPlacemark], nil)
                }
            }
        }

        let ex = expectationWithDescription("")
        MockGeocoder().geocode([:]).then { x -> Void in
            XCTAssertEqual(x, dummyPlacemark)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_geocodeAddressString() {
        class MockGeocoder: CLGeocoder {
            override func geocodeAddressString(addressString: String, completionHandler: CLGeocodeCompletionHandler) {
                after(0.0).then {
                    completionHandler([dummyPlacemark], nil)
                }
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
private let dummy = [CLLocation(latitude: 0, longitude: 0), CLLocation(latitude: 10, longitude: 20)]
private let dummyPlacemark = CLPlacemark()

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
