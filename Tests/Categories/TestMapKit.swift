import PromiseKit
import MapKit
import XCTest

class Test_MKDirections_Swift: XCTestCase {
    func test_directions_response() {
        let ex = expectation(description: "")

        class MockDirections: MKDirections {
            private override func calculate(completionHandler: MKDirectionsHandler) {
                completionHandler(MKDirectionsResponse(), nil)
            }
        }

        let rq = MKDirectionsRequest()
        MockDirections(request: rq).promise().then { (rsp: MKDirectionsResponse) in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }


    func test_ETA_response() {
        let ex = expectation(description: "")

        class MockDirections: MKDirections {
            private override func calculateETA(completionHandler: MKETAHandler) {
                completionHandler(MKETAResponse(), nil)
            }
        }

        let rq = MKDirectionsRequest()
        MockDirections(request: rq).promise().then { (rsp: MKETAResponse) in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

}

class Test_MKSnapshotter_Swift: XCTestCase {
    func test() {
        let ex = expectation(description: "")

        class MockSnapshotter: MKMapSnapshotter {
            private override func start(completionHandler: MKMapSnapshotCompletionHandler) {
                completionHandler(MKMapSnapshot(), nil)
            }
        }

        MockSnapshotter().promise().then { _ in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
