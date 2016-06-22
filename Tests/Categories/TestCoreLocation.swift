import CoreLocation
import PromiseKit
import XCTest

class Test_CLLocationManager_Swift: XCTestCase {
    func test_fulfills_with_one_location() {
        swizzle(CLLocationManager.self, #selector(CLLocationManager.startUpdatingLocation)) {
            let ex = expectation(withDescription: "")

            CLLocationManager.promise().then { x -> Void in
                XCTAssertEqual(x, dummy.last!)
                ex.fulfill()
            }

            waitForExpectations(withTimeout: 1, handler: nil)
        }
    }

    func test_fulfills_with_multiple_locations() {
        swizzle(CLLocationManager.self, #selector(CLLocationManager.startUpdatingLocation)) {
            let ex = expectation(withDescription: "")

            CLLocationManager.promise().allResults().then { x -> Void in
                XCTAssertEqual(x, dummy)
                ex.fulfill()
            }

            waitForExpectations(withTimeout: 1, handler: nil)
        }
    }

    func test_requestAuthorization() {
        #if os(iOS)
            swizzle(CLLocationManager.self, #selector(CLLocationManager.requestWhenInUseAuthorization)) {
                swizzle(CLLocationManager.self, #selector(CLLocationManager.authorizationStatus), isClassMethod: true) {
                    let ex = expectation(withDescription: "")

                    CLLocationManager.requestAuthorization().then { x -> Void in
                        XCTAssertEqual(x, CLAuthorizationStatus.authorizedWhenInUse)
                        ex.fulfill()
                    }

                    waitForExpectations(withTimeout: 1, handler: nil)
                }
            }
        #endif
    }
}

class Test_CLGeocoder_Swift: XCTestCase {
    func test_reverseGeocodeLocation() {
        class MockGeocoder: CLGeocoder {
            private override func reverseGeocodeLocation(_ location: CLLocation, completionHandler: CLGeocodeCompletionHandler) {
                after(0.0).then {
                    completionHandler([dummyPlacemark], nil)
                }
            }
        }

        let ex = expectation(withDescription: "")
        MockGeocoder().reverseGeocodeLocation(CLLocation()).then { x -> Void in
            XCTAssertEqual(x, dummyPlacemark)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func test_geocodeAddressDictionary() {
        class MockGeocoder: CLGeocoder {
            private override func geocodeAddressDictionary(_ addressDictionary: [NSObject : AnyObject], completionHandler: CLGeocodeCompletionHandler) {
                after(0.0).then {
                    completionHandler([dummyPlacemark], nil)
                }
            }
        }

        let ex = expectation(withDescription: "")
        MockGeocoder().geocode([:]).then { x -> Void in
            XCTAssertEqual(x, dummyPlacemark)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }

    func test_geocodeAddressString() {
        class MockGeocoder: CLGeocoder {
            override func geocodeAddressString(_ addressString: String, completionHandler: CLGeocodeCompletionHandler) {
                after(0.0).then {
                    completionHandler([dummyPlacemark], nil)
                }
            }
        }

        let ex = expectation(withDescription: "")
        MockGeocoder().geocode("").then { x -> Void in
            XCTAssertEqual(x, dummyPlacemark)
            ex.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
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
            self.delegate!.locationManager?(self, didChangeAuthorization: .authorizedWhenInUse)
        }
    }

    class func pmk_authorizationStatus() -> CLAuthorizationStatus {
        return .notDetermined
    }
#endif
}
